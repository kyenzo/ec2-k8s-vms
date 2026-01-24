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
# GitHub OIDC - Allow GitHub Actions to access secrets without stored credentials
# =============================================================================

module "github_oidc" {
  source = "./terraform/modules/github-oidc"

  create_oidc_provider = var.create_oidc_provider
  role_name            = var.github_actions_role_name

  # Repositories allowed to assume this role
  allowed_repositories = var.github_allowed_repositories

  # Secrets this role can access (ARNs will be managed by GitHub Actions)
  allowed_secret_arns = [
    "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.secrets_prefix}/*"
  ]

  tags = {
    Purpose = "GitHub-Actions-OIDC"
  }
}
