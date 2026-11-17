# Creates the remote-state backend that every environment uses: one S3 bucket,
# versioned and encrypted with a customer-managed KMS key. Locking uses the S3
# native lock file (Terraform 1.10 and later), so no DynamoDB table is needed.
# This configuration keeps local state on purpose and is run once.

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project    = "eks-gitops-platform"
      tier       = "foundation"
      managed-by = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "state_key" {
  # In a KMS key policy, Resource "*" means this key only, and the account-root statement is the
  # AWS default key policy that keeps the key manageable through IAM. Checkov reads key policies as
  # identity policies, so these three checks do not apply here.
  # checkov:skip=CKV_AWS_109:Key policy. Resource "*" is scoped to this key.
  # checkov:skip=CKV_AWS_111:Key policy. Resource "*" is scoped to this key.
  # checkov:skip=CKV_AWS_356:Key policy. Resource "*" is scoped to this key.
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "Encrypts the eks-gitops-platform Terraform state."
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_key.json
}

resource "aws_kms_alias" "state" {
  name          = "alias/eks-gitops-platform-tfstate"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  # checkov:skip=CKV_AWS_18:Access logging needs a second bucket that would itself fail this check. CloudTrail data events are the audit record for state access.
  # checkov:skip=CKV_AWS_144:The account's SCP pins a single Region, so cross-Region replication is not permitted. Versioning provides recovery.
  # checkov:skip=CKV2_AWS_62:Event notifications have no consumer for a state bucket. Changes are audited through CloudTrail.
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
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
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
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

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-superseded-state"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
