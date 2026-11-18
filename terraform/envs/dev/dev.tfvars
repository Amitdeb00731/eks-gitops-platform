region      = "eu-north-1"
environment = "dev"
cidr        = "10.10.0.0/16"
azs         = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]

public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]

# Phase 2 brings up a live cluster, so the private nodes need egress.
enable_nat_gateway = true

# EKS (Phase 2). Narrow this to your own IP before applying if you can.
kubernetes_version           = "1.33"
endpoint_public_access_cidrs = ["0.0.0.0/0"]
node_instance_types          = ["t3.medium"]
node_capacity_type           = "ON_DEMAND"
node_desired_size            = 2
