# AWS Configuration
aws_region  = "ca-west-1"
environment = "dev"

# EC2 Instance Configuration
instance_name = "k8s-vms-host"
instance_type = "m5.4xlarge" # 16 vCPU, 64 GiB RAM

# SSH Key Configuration
key_name = "k8s-vms-key"

# Storage Configuration
root_volume_size = 200 # GB - needs space for VMs
root_volume_type = "gp3"

# Security Configuration
# WARNING: 0.0.0.0/0 allows SSH from anywhere. Restrict to your IP in production.
# Example: ssh_allowed_cidrs = ["YOUR_IP/32"]
ssh_allowed_cidrs = ["0.0.0.0/0"]
