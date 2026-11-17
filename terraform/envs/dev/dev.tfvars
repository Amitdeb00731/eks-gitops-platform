region      = "eu-north-1"
environment = "dev"
cidr        = "10.10.0.0/16"
azs         = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]

public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]

enable_nat_gateway = false
