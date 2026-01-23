variable "secrets_prefix" {
  description = "Prefix for secret names"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key in PEM format"
  type        = string
  sensitive   = true
}

variable "public_ip" {
  description = "EC2 instance public IP address"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the instance"
  type        = string
  default     = "ubuntu"
}

variable "ssh_port" {
  description = "SSH port number"
  type        = number
  default     = 22
}

variable "recovery_window_days" {
  description = "Number of days to retain secrets after deletion (0 = immediate deletion)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
