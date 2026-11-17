region      = "eu-north-1"
environment = "prod"
cidr        = "10.30.0.0/16"
azs         = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]

public_subnets  = ["10.30.101.0/24", "10.30.102.0/24", "10.30.103.0/24"]
private_subnets = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]

enable_nat_gateway = false
