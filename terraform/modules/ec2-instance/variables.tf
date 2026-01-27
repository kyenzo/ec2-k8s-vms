variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.4xlarge"
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If empty, latest Ubuntu 22.04 will be used"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "terraform-key"
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be created"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "associate_public_ip" {
  description = "Associate an Elastic IP with the instance"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "use_spot_instance" {
  description = "Use spot instance instead of on-demand"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for spot instance (leave empty for on-demand price)"
  type        = string
  default     = ""
}

variable "cpu_core_count" {
  description = "Number of CPU cores. Set to half of vCPUs to enable nested virtualization"
  type        = number
  default     = null
}

variable "cpu_threads_per_core" {
  description = "Threads per core. Set to 1 to disable hyper-threading and enable nested virtualization"
  type        = number
  default     = null
}
