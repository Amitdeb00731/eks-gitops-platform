region      = "eu-north-1"
environment = "staging"
cidr        = "10.20.0.0/16"
azs         = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]

public_subnets  = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

enable_nat_gateway = false
