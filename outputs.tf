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
