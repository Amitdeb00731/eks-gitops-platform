# The EKS cluster, managed node group, OIDC provider (for IRSA), secret
# encryption and control-plane logging. This wraps the community EKS module,
# which is the industry default for a cluster of this complexity (ADR 0006),
# pinned to a major version.

locals {
  name = "${var.environment}-platform"
}

module "eks" {
  # checkov:skip=CKV_TF_1:Registry modules are pinned by version, which is the registry's supply-chain control; commit-hash pinning applies to git sources, not registry sources.
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.30.0"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Public endpoint, narrowed by CIDR, plus private access so in-VPC traffic
  # never leaves the network. Restrict the CIDR for anything but a short run.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true

  # OIDC provider for IAM roles for service accounts.
  enable_irsa = true

  # Envelope-encrypt Kubernetes secrets with a dedicated, rotated KMS key.
  create_kms_key = true
  encryption_config = {
    resources = ["secrets"]
  }

  # Control-plane audit and authenticator logs to CloudWatch.
  enabled_log_types = ["api", "audit", "authenticator"]

  # Map the identity that applies this (AdminJITRole) to cluster admin through a
  # native EKS access entry, so no aws-auth ConfigMap is needed.
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Nodes are cattle: label them and keep the group small for the run.
      labels = {
        role = "general"
      }
    }
  }

  tags = {
    environment = var.environment
    tier        = "cluster"
  }
}
