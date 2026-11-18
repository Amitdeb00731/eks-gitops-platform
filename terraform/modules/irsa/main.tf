# A reusable IAM role for an EKS service account (IRSA). The trust policy
# federates to the cluster OIDC provider and is pinned to a specific namespace
# and service account, so only that pod identity can assume it, and only with
# the sts.amazonaws.com audience. Written from native resources so the whole
# trust relationship is visible to the policy scan.

locals {
  # The OIDC condition keys are built from the issuer host, without its scheme.
  oidc_host = replace(var.oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AssumeWithOidc"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = [for sa in var.namespace_service_accounts : "system:serviceaccount:${sa}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600

  tags = {
    "managed-by" = "terraform"
  }
}

# Attach by index rather than for_each over the ARNs: a managed policy ARN can
# be computed (the LB controller policy is created in the same apply), and
# for_each needs its set keys known at plan time, whereas count only needs the
# list length, which is known.
resource "aws_iam_role_policy_attachment" "managed" {
  count = length(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
