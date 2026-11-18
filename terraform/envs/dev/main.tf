provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project     = "eks-gitops-platform"
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

module "network" {
  source = "../../modules/network"

  environment        = var.environment
  cidr               = var.cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
}

# --- EKS cluster (Phase 2, dev only: the one live bring-up) ---

module "eks" {
  source = "../../modules/eks"

  environment                  = var.environment
  kubernetes_version           = var.kubernetes_version
  vpc_id                       = module.network.vpc_id
  subnet_ids                   = module.network.private_subnet_ids
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  node_instance_types          = var.node_instance_types
  node_capacity_type           = var.node_capacity_type
  node_desired_size            = var.node_desired_size

  # The managed node group only implicitly depends on the subnets, not on the
  # NAT gateway and its route. Private nodes need that egress during bootstrap
  # (nodeadm calls the EC2 and EKS APIs before the kubelet can join), so wait for
  # the whole network, including the NAT path, before the cluster and its nodes.
  depends_on = [module.network]
}

# AWS Load Balancer Controller: a customer-managed policy built from the
# controller's own published policy (pinned to a release), attached to an IRSA
# role for its service account in kube-system.
resource "aws_iam_policy" "lb_controller" {
  name        = "${var.environment}-aws-load-balancer-controller"
  description = "AWS Load Balancer Controller policy, pinned to controller release v3.6.1."
  policy      = file("${path.module}/../../policy/lb-controller-iam-policy.json")
}

module "irsa_lb_controller" {
  source = "../../modules/irsa"

  name                       = "${var.environment}-aws-load-balancer-controller"
  oidc_provider_arn          = module.eks.oidc_provider_arn
  oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
  namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
  policy_arns                = [aws_iam_policy.lb_controller.arn]
}

# A demonstration IRSA role scoped to one harmless read action, to prove that a
# pod assuming it shows this identity and not the node's. Least privilege made
# visible.
data "aws_iam_policy_document" "irsa_demo" {
  statement {
    sid       = "ListBucketNames"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}

module "irsa_demo" {
  source = "../../modules/irsa"

  name                       = "${var.environment}-irsa-demo"
  oidc_provider_arn          = module.eks.oidc_provider_arn
  oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
  namespace_service_accounts = ["default:irsa-demo"]
  inline_policy_json         = data.aws_iam_policy_document.irsa_demo.json
}
