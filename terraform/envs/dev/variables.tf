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

# --- EKS (Phase 2) ---

variable "kubernetes_version" {
  type    = string
  default = "1.33"
}

variable "endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "node_desired_size" {
  type    = number
  default = 2
}
