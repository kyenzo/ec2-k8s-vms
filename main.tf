terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "k8s-vms"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet in the first availability zone
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create EC2 instance using the module
module "k8s_host" {
  source = "./terraform/modules/ec2-instance"

  name_prefix   = var.instance_name
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_id    = data.aws_vpc.default.id
  subnet_id = data.aws_subnets.default.ids[0]

  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  ssh_allowed_cidrs   = var.ssh_allowed_cidrs
  associate_public_ip = true

  # Spot instance configuration
  use_spot_instance = var.use_spot_instance
  spot_max_price    = var.spot_max_price

  # User data script to install tools on first boot
  user_data = file("${path.module}/scripts/install-k8s-tools.sh")

  tags = {
    Purpose = "Kubernetes-VMs-Host"
  }
}

# =============================================================================
# AWS Secrets Manager - Store EC2 credentials for GitHub Actions access
# =============================================================================

# Secret for SSH private key (PEM)
resource "aws_secretsmanager_secret" "ec2_ssh_key" {
  name                    = "${var.secrets_prefix}/ec2-ssh-private-key"
  description             = "SSH private key for EC2 K8s VMs host"
  recovery_window_in_days = 0 # Allow immediate deletion for dev environment

  tags = {
    Purpose = "EC2-SSH-Access"
  }
}

resource "aws_secretsmanager_secret_version" "ec2_ssh_key" {
  secret_id     = aws_secretsmanager_secret.ec2_ssh_key.id
  secret_string = module.k8s_host.private_key_pem
}

# Secret for EC2 public IP
resource "aws_secretsmanager_secret" "ec2_public_ip" {
  name                    = "${var.secrets_prefix}/ec2-public-ip"
  description             = "Public IP address of EC2 K8s VMs host"
  recovery_window_in_days = 0

  tags = {
    Purpose = "EC2-Connection-Info"
  }
}

resource "aws_secretsmanager_secret_version" "ec2_public_ip" {
  secret_id     = aws_secretsmanager_secret.ec2_public_ip.id
  secret_string = module.k8s_host.instance_public_ip
}

# Secret for EC2 connection info (JSON with all details)
resource "aws_secretsmanager_secret" "ec2_connection_info" {
  name                    = "${var.secrets_prefix}/ec2-connection-info"
  description             = "Full connection info for EC2 K8s VMs host"
  recovery_window_in_days = 0

  tags = {
    Purpose = "EC2-Connection-Info"
  }
}

resource "aws_secretsmanager_secret_version" "ec2_connection_info" {
  secret_id = aws_secretsmanager_secret.ec2_connection_info.id
  secret_string = jsonencode({
    host        = module.k8s_host.instance_public_ip
    user        = "ubuntu"
    private_key = module.k8s_host.private_key_pem
    port        = 22
  })
}

# =============================================================================
# GitHub OIDC - Allow GitHub Actions to access secrets without stored credentials
# =============================================================================

module "github_oidc" {
  source = "./terraform/modules/github-oidc"

  create_oidc_provider = var.create_oidc_provider
  role_name            = var.github_actions_role_name

  # Repositories allowed to assume this role
  allowed_repositories = var.github_allowed_repositories

  # Secrets this role can access
  allowed_secret_arns = [
    aws_secretsmanager_secret.ec2_ssh_key.arn,
    aws_secretsmanager_secret.ec2_public_ip.arn,
    aws_secretsmanager_secret.ec2_connection_info.arn,
  ]

  tags = {
    Purpose = "GitHub-Actions-OIDC"
  }
}
