variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (set to false if it already exists in your account)"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
  default     = "github-actions-ec2-k8s"
}

variable "allowed_repositories" {
  description = "List of GitHub repositories allowed to assume this role (format: owner/repo)"
  type        = list(string)
}

variable "allowed_secret_arns" {
  description = "List of Secrets Manager secret ARNs that the role can access"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
