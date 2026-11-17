variable "region" {
  type        = string
  description = "The account's pinned Region."
}

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

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}
