variable "environment" {
  type        = string
  description = "dev, staging or prod."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.33"
  description = "EKS control-plane version. Bump when AWS retires an older one."
}

variable "vpc_id" {
  type        = string
  description = "VPC the cluster runs in."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for the control-plane ENIs and the managed nodes."
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the public API endpoint. Narrow to your own IP for a real deployment; 0.0.0.0/0 is acceptable only for a short evidence run."
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_capacity_type" {
  type        = string
  default     = "ON_DEMAND"
  description = "ON_DEMAND for a reliable evidence run, or SPOT to cut cost."
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 3
}
