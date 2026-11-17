# Phase 1: multi-environment Terraform foundation

**Tier:** designed and validated. The code is proven with `terraform fmt`,
`terraform validate`, a policy scan and `terraform plan`. The only resources
created in this phase are the state backend (one S3 bucket and one KMS key).
The dev network is applied for real during the Phase 2 bring-up; staging and
production are proven by plan.

**Goal:** a repeatable, reviewable way to define AWS infrastructure for three
environments (dev, staging, production) from reusable modules, with encrypted
and versioned remote state, state locking, and a policy gate that runs before
anything is applied.

**Risk and resilience framing:** this is infrastructure as code with environment
segregation and a pre-apply control gate. In bank terms it gives change control
(every change is a reviewed, planned diff), segregation of environments (separate
state and separate blast radius per environment), and an auditable record of what
was applied and when. The policy gate is a preventive control, and its documented
exceptions are recorded risk acceptances.

## Layout

```
terraform/
  bootstrap/        state bucket and its KMS key (run once, local state)
  modules/
    network/        VPC, subnets, routing, flow logs, default-deny security group
  envs/
    dev/            backend, composition and values for dev
    staging/
    prod/
  policy/           Checkov configuration and the baseline
```

Modules hold reusable building blocks with no environment-specific values. The
`envs/` directories compose those modules and carry the only per-environment
differences (the state key and the CIDR ranges). The three environments are
identical in shape, so a change proven in dev behaves the same in production.

## Design choices

- **State locking uses the S3 native lock file** (`use_lockfile = true`,
  Terraform 1.10 and later) rather than a DynamoDB table. DynamoDB locking is
  deprecated in current Terraform, and the native lock removes a resource. See
  [ADR 0004](adr/0004-s3-native-state-locking.md).
- **The network module is written from native resources** rather than wrapping a
  community module, so every resource is visible to the policy scan and the
  module carries only what the platform needs. See
  [ADR 0005](adr/0005-network-module-from-native-resources.md).
- **State is encrypted with a customer-managed KMS key.** State can hold
  sensitive values, so the key policy, not just bucket access, decides who can
  read it. The key costs about one US dollar a month while it exists.
- **VPC flow logs are on by default**, encrypted with their own KMS key and kept
  for 365 days. This mirrors the Security Hub control (EC2.6) remediated in the
  cloud IAM build.
- **NAT gateways default off.** They are the quiet monthly cost, so they are only
  switched on when a private workload genuinely needs outbound access.
- **No account-specific value is committed.** The state bucket name and key ARN
  are passed at `terraform init` time.

## Prerequisites

- Terraform 1.10 or later (`winget install Hashicorp.Terraform`), AWS CLI v2 and
  Checkov (`pip install checkov`).
- Short-lived credentials for the workload account. The account has no standing
  privilege: an operator assumes a role with MFA, using the helper from the
  [cloud IAM build](https://github.com/Amitdeb00731/cloud-iam-lab-aws), which
  exports temporary credentials into the shell. From this repository's root, with
  the two repositories side by side, confirm them before anything else:

```
source ../cloud-iam-lab-aws/scripts/assume-role.sh <6-digit-MFA-code>   # ContributorRole
aws sts get-caller-identity
```

`ContributorRole` (PowerUserAccess) is enough for this phase, because the
bootstrap creates only S3 and KMS resources and the environments are only
planned. The network module creates an IAM role for flow logs, so the dev apply
in Phase 2 runs as the elevated `AdminJITRole`. Credentials last about an hour;
re-source with a fresh code if they expire.

The Region is `eu-north-1`, which the account's service control policy pins.

## Step 1: the policy gate, before anything touches AWS

No Terraform is applied until it passes a policy scan. Checkov reads the code and
flags insecure configuration before it reaches AWS.

```
checkov -d terraform --config-file terraform/policy/.checkov.yaml
```

The expected baseline is 96 passed, 0 failed, 15 skipped. Every skip is an
inline `checkov:skip` comment with its reason, listed in
[terraform/policy/README.md](../terraform/policy/README.md).

**Prove the gate works by failing it first.** Delete the
`aws_s3_bucket_public_access_block` resource from `terraform/bootstrap/main.tf`
(and the `depends_on` line that refers to it) and rerun the scan. It fails on
`CKV2_AWS_6` (S3 bucket has no public access block). Capture that failure,
restore the file with `git checkout terraform/bootstrap/main.tf`, and rerun to
show the clean baseline. The paired failing and passing output is the evidence
that the gate catches real misconfiguration, not that it simply ran.

## Step 2: bootstrap the state backend

Terraform state records what exists. It must be shared, versioned (so a bad apply
can be recovered) and locked (so two runs cannot write at once). There is a
chicken-and-egg problem: the backend cannot store its own creation in a backend
that does not yet exist, so a small bootstrap runs once with local state.

```
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars    # set a globally unique bucket name
terraform init
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
```

The plan shows 9 resources: the bucket (versioned, KMS-encrypted, public access
blocked, TLS-only bucket policy, ACLs disabled, superseded versions expired after
90 days) and the KMS key with rotation enabled, plus its alias. The bootstrap's
local state and `terraform.tfvars` are git-ignored.

Keep the two outputs for the next step:

```
export TF_STATE_BUCKET=$(terraform output -raw state_bucket_name)
export TF_STATE_KMS_KEY=$(terraform output -raw state_kms_key_arn)
```

## Step 3: initialise, validate and plan each environment

Each environment has its own state key (`envs/dev/terraform.tfstate`,
`envs/staging/...`, `envs/prod/...`), so the three never share state. The bucket
and key are supplied at init time:

```
cd terraform/envs/staging
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="kms_key_id=$TF_STATE_KMS_KEY"
terraform validate
terraform plan -var-file=staging.tfvars -out=staging.tfplan
```

Repeat for `dev` and `prod`. Each plan should show 23 resources to add, the same
shape in every environment, differing only in CIDR ranges and names. Nothing is
applied in this phase; dev is applied in Phase 2.

The first `terraform init` writes `.terraform.lock.hcl`, which pins the exact
provider build. Commit it, after adding the Linux hashes so a CI runner gets the
same provider:

```
terraform providers lock -platform=windows_amd64 -platform=linux_amd64
```

## Step 4: prove state locking (no resources created)

State locking stops two runs corrupting state. `terraform apply` holds the lock
while it waits at its approval prompt, which gives a safe way to prove the lock
without creating anything.

```
# shell 1, in terraform/envs/staging: stop at the prompt, do not answer yet
terraform apply -var-file=staging.tfvars

# shell 2, same directory, while shell 1 is waiting
terraform plan -var-file=staging.tfvars
# Error: Error acquiring the state lock
```

Shell 2 is refused and the lock information names the `.tflock` object in the
state bucket. Then answer `no` in shell 1, so nothing is applied and the lock is
released. The refusal is the evidence that the lock works.

## Evidence to capture (into `evidence/phase1/`)

Already captured from a clean build environment (see
[evidence/phase1/](../evidence/phase1/README.md)):

- `terraform fmt` and `terraform validate` for all five configurations.
- The Checkov baseline, and the gate failing on the removed public access block.

Captured during the AWS steps:

- The bootstrap apply and its outputs (bucket and key created).
- `terraform plan` for dev, staging and production.
- The state-lock refusal from the concurrent run.

## Done checklist

_These boxes are an operator runbook for a reader reproducing this phase. The
as-built result is recorded in the evidence files, not in these boxes._

- [x] Policy gate shown failing on a bad configuration, then passing
- [x] Bootstrap applied; state bucket and KMS key exist
- [x] Each environment initialised against its own state key
- [x] `terraform validate` clean for dev, staging and prod
- [x] `terraform plan` captured for dev, staging and prod
- [x] State lock shown refusing a concurrent run
- [x] Provider lock file committed with Windows and Linux hashes
- [x] Evidence saved under `evidence/phase1/`

**Next, Phase 2:** add the EKS module (cluster, managed node group, OIDC provider
for IAM roles for service accounts) and the load balancer controller, apply dev
for a single evidence run, and destroy it the same day.
