# AWS Secrets Manager Module
# Stores EC2 connection information for secure access from GitHub Actions

# Secret for SSH private key (PEM)
resource "aws_secretsmanager_secret" "ec2_ssh_key" {
  name                    = "${var.secrets_prefix}/ec2-ssh-private-key"
  description             = "SSH private key for EC2 K8s VMs host"
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    var.tags,
    {
      Purpose = "EC2-SSH-Access"
    }
  )
}

resource "aws_secretsmanager_secret_version" "ec2_ssh_key" {
  secret_id     = aws_secretsmanager_secret.ec2_ssh_key.id
  secret_string = var.ssh_private_key
}

# Secret for EC2 public IP
resource "aws_secretsmanager_secret" "ec2_public_ip" {
  name                    = "${var.secrets_prefix}/ec2-public-ip"
  description             = "Public IP address of EC2 K8s VMs host"
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    var.tags,
    {
      Purpose = "EC2-Connection-Info"
    }
  )
}

resource "aws_secretsmanager_secret_version" "ec2_public_ip" {
  secret_id     = aws_secretsmanager_secret.ec2_public_ip.id
  secret_string = var.public_ip
}

# Secret for EC2 connection info (JSON with all details)
resource "aws_secretsmanager_secret" "ec2_connection_info" {
  name                    = "${var.secrets_prefix}/ec2-connection-info"
  description             = "Full connection info for EC2 K8s VMs host"
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    var.tags,
    {
      Purpose = "EC2-Connection-Info"
    }
  )
}

resource "aws_secretsmanager_secret_version" "ec2_connection_info" {
  secret_id = aws_secretsmanager_secret.ec2_connection_info.id
  secret_string = jsonencode({
    host        = var.public_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key
    port        = var.ssh_port
  })
}
