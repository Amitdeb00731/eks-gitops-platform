variable "environment" {
  type        = string
  description = "dev, staging or prod."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "cidr" {
  type        = string
  description = "VPC CIDR range."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to spread across. One public and one private subnet per zone."
}

variable "public_subnets" {
  type        = list(string)
  description = "One CIDR per Availability Zone, in the same order as azs."
}

variable "private_subnets" {
  type        = list(string)
  description = "One CIDR per Availability Zone, in the same order as azs."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "NAT gateways cost money. Off by default; on only when a private workload needs egress."
}

variable "flow_log_retention_days" {
  type        = number
  default     = 365
  description = "Retention for VPC flow logs in CloudWatch Logs."
}
