# Lab notes

A running log of the build, one entry per working session. Each entry records
what was done, what was proven, and anything that caught us out, in the STAR
form (situation, task, action, result).

## Conventions

- Three tiers, and every artefact is labelled: built live (briefly), proven
  locally, or designed and documented.
- No secret is ever committed. Credentials live in a secrets manager or in local
  environment variables that are git-ignored.
- One EKS cluster is only ever brought up for a single evidence run and is
  destroyed the same day.

## Entries

### Phase 1: foundation (complete)

Situation: the platform needs a repeatable, reviewable way to define AWS
infrastructure across three environments, with a control gate before anything is
applied.

Task: build reusable Terraform modules and per-environment overlays, with
encrypted remote state, state locking and a policy gate, and prove each control.

Action (2026-11-17): wrote the bootstrap (state bucket and KMS key), a network
module from native resources (VPC, subnets, routing, optional NAT, KMS-encrypted
flow logs, default-deny security group) and the dev, staging and prod overlays.
Validated all five configurations, ran Checkov, applied the bootstrap to the
workload account (ContributorRole with MFA, eu-north-1), planned the three
environments and tested the state lock.

Result: format and validation clean on all five configurations. Checkov baseline
96 passed, 0 failed, 15 documented skips; the gate shown failing on a removed
public access block (CKV2_AWS_6) and passing again once restored. Bootstrap
applied: 9 resources, the state bucket and KMS key created from a reviewed plan.
Each environment planned the same 23 resources with nothing applied. A concurrent
run was refused with the S3 native lock (HTTP 412 PreconditionFailed). Evidence in
evidence/phase1/ (01 to 08).

What caught us out:

- Checkov flagged both KMS key policies (CKV_AWS_109, 111, 356) because it reads
  them as identity policies. In a key policy `Resource "*"` means the key itself,
  so these are documented skips rather than a weaker policy.
- The guide first predicted the gate would fail on CKV_AWS_53 to 56. Removing the
  public access block removes the resource those checks inspect, so the real
  failure is CKV2_AWS_6. Running the gate, rather than assuming its output,
  corrected the guide.
- DynamoDB state locking is deprecated in current Terraform. The backend uses the
  S3 native lock file instead (ADR 0004); the lock refusal surfaces as an S3 HTTP
  412 rather than a DynamoDB conditional-check error.
- A repeated `git checkout -B` reset the working tree to the scaffold and dropped
  the Phase 1 files locally; they were restored from the pushed branch. The commit
  on the remote was never at risk.

### Phase 2: EKS cluster and workload identity (code ready, live run pending)

Situation: the platform needs a running cluster with least privilege at the
workload layer, brought up briefly for evidence and torn down the same day.

Task: write the EKS cluster, a reusable IRSA module, and the load balancer
controller role, wired into dev, and validate as far as an offline build allows.

Action (2026-11-17): added modules/eks (community EKS module v21, wrapped with
secure defaults: OIDC on, KMS secret encryption, control-plane logging, access
entries), a native modules/irsa (OIDC-federated trust pinned to a namespace and
service account), the committed load balancer controller policy (pinned to
controller release v3.6.1), and the two IRSA roles in dev. Turned the dev NAT
gateway on for node egress.

Result: fmt clean; the irsa module and the full dev wiring validate (the cluster
module checked against a stub matching the v21 interface, since the community
module cannot be fetched offline); the load balancer policy JSON parses; Checkov
135 passed, 0 failed, 16 skips. The live apply, the IRSA proof and the load
balancer evidence are captured on the operator workstation during the bring-up.

What caught us out:

- The community EKS module cannot be downloaded in the offline build environment,
  so Phase 2's Terraform is validated on the laptop during the live run, which is
  where a live-tier phase is proven anyway (ADR 0006).
- CKV_TF_1 wants a commit hash for the module source. Registry modules are pinned
  by version, so this is a documented skip, and the module is pinned to a patch
  range.

