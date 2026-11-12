# Phase 1: multi-environment Terraform foundation

**Tier:** designed and validated. Everything here is written and proven with
`terraform validate`, `terraform plan` and a policy scan. One environment is
applied for real during the Phase 2 bring-up; the other two are proven by plan.

**Goal:** a repeatable, reviewable way to define AWS infrastructure for three
environments (dev, staging, production) from reusable modules, with remote state
in S3, state locking in DynamoDB, and a policy gate that runs before anything is
applied.

**Risk and resilience framing:** this is infrastructure as code with environment
segregation and a pre-apply control gate. In bank terms it gives change control
(every change is a reviewed, planned diff), segregation of environments (separate
state and separate blast radius per environment), and an auditable record of what
was applied and when.

## Layout

```
terraform/
  bootstrap/        creates the state bucket and lock table (run once)
  modules/
    network/        VPC, subnets, routing (wraps the community VPC module)
  envs/
    dev/            backend + composition + variables for dev
    staging/
    prod/
  policy/           Checkov configuration and the baseline
```

Modules hold reusable building blocks with no environment-specific values. The
`envs/` directories compose those modules and carry the only per-environment
differences (CIDR ranges, sizes, the state key). This keeps the three
environments identical in shape and different only where they must be.

## Step 1: the remote state backend

Terraform state records what exists. It must be shared (so the team sees the same
state), versioned (so a bad apply can be recovered) and locked (so two applies
cannot run at once). S3 provides the shared, versioned store; a DynamoDB table
provides the lock.

There is a chicken-and-egg problem: the backend cannot store its own creation in
a backend that does not yet exist. Solve it with a small bootstrap that runs once
with local state, then never changes.

`terraform/bootstrap/main.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project = "eks-gitops-platform"
      tier    = "foundation"
    }
  }
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

`terraform/bootstrap/variables.tf`:

```hcl
variable "region" {
  type        = string
  description = "The account's pinned Region."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the state bucket."
}

variable "lock_table_name" {
  type        = string
  default     = "eks-gitops-platform-tf-lock"
  description = "DynamoDB table for state locking."
}
```

Run it once:

```
cd terraform/bootstrap
terraform init
terraform apply
```

The bootstrap keeps local state on purpose. It changes rarely, and committing its
state is avoided (it is git-ignored). The bucket and table it creates are what
every environment then uses.

## Step 2: a reusable module

Modules are the reusable blocks. The network module is the first; the EKS module
arrives in Phase 2. The network module wraps the community VPC module so the
platform gets a well-tested VPC with the small set of options the build needs.

`terraform/modules/network/main.tf`:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment}-platform"
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  # Tags the EKS and load balancer controllers rely on to place resources.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

`terraform/modules/network/variables.tf`:

```hcl
variable "environment" {
  type        = string
  description = "dev, staging or prod."
}

variable "cidr" {
  type        = string
  description = "VPC CIDR range."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to spread across."
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "NAT gateways cost money. Off by default; on only when a private workload needs egress."
}
```

`terraform/modules/network/outputs.tf`:

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}
```

NAT gateways default off. They are the quiet monthly cost, so they are only
switched on when a private workload genuinely needs outbound access, and never
left on at rest.

## Step 3: the environment overlays

Each environment is a thin composition: a backend block pointing at its own state
key, the provider, and a call to the module with that environment's values.

`terraform/envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_STATE_BUCKET"
    key            = "envs/dev/terraform.tfstate"
    region         = "REPLACE_WITH_REGION"
    dynamodb_table = "eks-gitops-platform-tf-lock"
    encrypt        = true
  }
}
```

The `key` differs per environment (`envs/staging/...`, `envs/prod/...`), so the
three environments never share state. The bucket and lock table are the same.

`terraform/envs/dev/main.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project     = "eks-gitops-platform"
      environment = var.environment
    }
  }
}

module "network" {
  source = "../../modules/network"

  environment     = var.environment
  cidr            = var.cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}
```

`terraform/envs/dev/dev.tfvars`:

```hcl
region          = "REPLACE_WITH_REGION"
environment     = "dev"
cidr            = "10.10.0.0/16"
azs             = ["REGIONa", "REGIONb", "REGIONc"]
private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
```

Staging and production use the same files with their own CIDR ranges
(`10.20.0.0/16`, `10.30.0.0/16`) and larger sizes where it matters. Keeping the
three identical in shape is the point: a change proven in dev behaves the same in
production.

Validate and plan each environment without applying:

```
cd terraform/envs/dev
terraform init
terraform validate
terraform plan -var-file=dev.tfvars
```

`validate` and a clean `plan` are the Phase 1 evidence for staging and
production. Dev is the environment applied for real in Phase 2.

## Step 4: the policy gate (fail then prove)

No Terraform is applied until it passes a policy scan. Checkov reads the code and
flags insecure configuration before it reaches AWS. This is the pre-apply control
gate.

Run it over the whole tree:

```
checkov --directory terraform/ --download-external-modules true
```

Prove the gate works by failing it first. Temporarily remove the public-access
block from the bootstrap bucket:

```hcl
# resource "aws_s3_bucket_public_access_block" "state" { ... }  # commented out
```

Checkov fails with `CKV_AWS_53` to `CKV_AWS_56` (S3 bucket missing public-access
restrictions). Capture that failure, restore the block, and show the same scan
passing. The paired failing-then-passing output is the evidence that the gate
catches real misconfiguration, not that it simply ran.

`terraform/policy/README.md` records the baseline and any rule that is
deliberately skipped, each with a reason.

## Step 5: prove state locking

State locking stops two applies corrupting state. Prove it: start an apply in one
shell and, while it holds the lock, start another in a second shell.

```
# shell 1
terraform apply -var-file=dev.tfvars

# shell 2, while shell 1 is mid-apply
terraform apply -var-file=dev.tfvars
# Error: Error acquiring the state lock ... ConditionalCheckFailedException
```

The second apply is refused with a lock error naming the DynamoDB table. That
refusal is the evidence that the lock works.

## Evidence to capture (into `evidence/phase1/`)

- `terraform validate` output for all three environments.
- `terraform plan` output for staging and production (no changes to apply beyond
  the intended resources).
- The Checkov scan failing on the removed public-access block, then passing.
- The state-lock error from the concurrent apply.
- The bootstrap apply result (bucket and table created).

## Done checklist

_These boxes are an operator runbook for a reader reproducing this phase. The
as-built result is recorded in the evidence files, not in these boxes._

- [ ] Bootstrap applied; state bucket and lock table exist
- [ ] Network module written, validated
- [ ] Three environment overlays written, each with its own state key
- [ ] `terraform validate` clean for dev, staging and prod
- [ ] `terraform plan` captured for staging and prod
- [ ] Checkov gate shown failing on a bad config, then passing
- [ ] State lock shown refusing a concurrent apply
- [ ] Evidence saved under `evidence/phase1/`

**Next, Phase 2:** stand up the EKS cluster, node groups, IAM roles for service
accounts and the load balancer controller, and capture the live evidence.
