output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = var.associate_public_ip ? aws_eip.instance[0].public_ip : aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.instance.id
}

output "key_name" {
  description = "The name of the SSH key pair"
  value       = aws_key_pair.deployer.key_name
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${var.associate_public_ip ? aws_eip.instance[0].public_ip : aws_instance.main.public_ip}"
}
