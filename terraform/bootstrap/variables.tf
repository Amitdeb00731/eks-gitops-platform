variable "region" {
  type        = string
  description = "The account's pinned Region."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the Terraform state bucket."
}

variable "noncurrent_version_retention_days" {
  type        = number
  default     = 90
  description = "How long superseded state versions are kept for recovery before expiry."
}
