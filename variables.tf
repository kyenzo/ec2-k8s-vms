variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ca-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  default     = "k8s-vms-host"
}

variable "instance_type" {
  description = "EC2 instance type (must have 64GB RAM)"
  type        = string
  default     = "r5.2xlarge" # 8 vCPU, 64 GiB RAM (Memory Optimized - Cost Effective)

  validation {
    condition = contains([
      "m5.4xlarge",   # 16 vCPU, 64 GiB RAM
      "m5a.4xlarge",  # 16 vCPU, 64 GiB RAM
      "m6i.4xlarge",  # 16 vCPU, 64 GiB RAM
      "r5.2xlarge",   # 8 vCPU, 64 GiB RAM (Memory Optimized)
      "r5a.2xlarge",  # 8 vCPU, 64 GiB RAM
      "r6i.2xlarge"   # 8 vCPU, 64 GiB RAM
    ], var.instance_type)
    error_message = "Instance type must support 64GB RAM. Choose from: m5.4xlarge, m5a.4xlarge, m6i.4xlarge, r5.2xlarge, r5a.2xlarge, r6i.2xlarge"
  }
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "k8s-vms-key"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 200
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production
}

variable "use_spot_instance" {
  description = "Use spot instance instead of on-demand (saves ~60% but can be interrupted)"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instance (leave empty for on-demand price)"
  type        = string
  default     = ""
}
