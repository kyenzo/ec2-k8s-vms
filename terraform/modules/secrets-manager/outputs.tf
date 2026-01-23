output "ssh_key_secret_arn" {
  description = "ARN of the SSH private key secret"
  value       = aws_secretsmanager_secret.ec2_ssh_key.arn
}

output "ssh_key_secret_name" {
  description = "Name of the SSH private key secret"
  value       = aws_secretsmanager_secret.ec2_ssh_key.name
}

output "public_ip_secret_arn" {
  description = "ARN of the public IP secret"
  value       = aws_secretsmanager_secret.ec2_public_ip.arn
}

output "public_ip_secret_name" {
  description = "Name of the public IP secret"
  value       = aws_secretsmanager_secret.ec2_public_ip.name
}

output "connection_info_secret_arn" {
  description = "ARN of the connection info secret"
  value       = aws_secretsmanager_secret.ec2_connection_info.arn
}

output "connection_info_secret_name" {
  description = "Name of the connection info secret"
  value       = aws_secretsmanager_secret.ec2_connection_info.name
}

output "all_secret_arns" {
  description = "List of all secret ARNs for IAM policy"
  value = [
    aws_secretsmanager_secret.ec2_ssh_key.arn,
    aws_secretsmanager_secret.ec2_public_ip.arn,
    aws_secretsmanager_secret.ec2_connection_info.arn,
  ]
}
