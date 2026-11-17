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

module "network" {
  source = "../../modules/network"

  environment        = var.environment
  cidr               = var.cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
}
