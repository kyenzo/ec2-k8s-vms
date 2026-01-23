output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.k8s_host.instance_id
}

output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = module.k8s_host.instance_public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = module.k8s_host.instance_private_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = module.k8s_host.ssh_command
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = module.k8s_host.private_key_path
}

output "connection_info" {
  description = "Connection information for the instance"
  value = {
    public_ip        = module.k8s_host.instance_public_ip
    private_key_path = module.k8s_host.private_key_path
    ssh_user         = "ubuntu"
    ssh_command      = module.k8s_host.ssh_command
  }
}

# =============================================================================
# GitHub OIDC Outputs
# =============================================================================

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions to assume via OIDC"
  value       = module.github_oidc.role_arn
}

# =============================================================================
# AWS Secrets Manager Outputs
# =============================================================================

output "secrets_info" {
  description = "AWS Secrets Manager secret names (for GitHub Actions workflow)"
  value = {
    ssh_key_secret_name         = aws_secretsmanager_secret.ec2_ssh_key.name
    public_ip_secret_name       = aws_secretsmanager_secret.ec2_public_ip.name
    connection_info_secret_name = aws_secretsmanager_secret.ec2_connection_info.name
  }
}
