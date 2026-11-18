variable "name" {
  type        = string
  description = "Role name."
}

variable "oidc_provider_arn" {
  type        = string
  description = "The cluster OIDC provider ARN (from the eks module)."
}

variable "oidc_issuer_url" {
  type        = string
  description = "The cluster OIDC issuer URL (from the eks module), with its https prefix."
}

variable "namespace_service_accounts" {
  type        = list(string)
  description = "Service accounts allowed to assume the role, each as \"namespace:serviceaccount\"."

  validation {
    condition     = alltrue([for s in var.namespace_service_accounts : can(regex("^[^:]+:[^:]+$", s))])
    error_message = "Each entry must be exactly \"namespace:serviceaccount\"."
  }
}

variable "policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed or customer policy ARNs to attach."
}

variable "inline_policy_json" {
  type        = string
  default     = null
  description = "Optional inline least-privilege policy for this role."
}
