# EC2 Kubernetes VMs Infrastructure

This project provisions an EC2 instance with 64GB RAM on AWS using Terraform, designed to host multiple VMs for a bare-metal Kubernetes cluster.

## Architecture

- **EC2 Instance**: m5.4xlarge (16 vCPU, 64 GiB RAM) in ca-west-1
- **Storage**: 200 GB gp3 root volume
- **Networking**: Default VPC with public IP and Elastic IP
- **Security**: Security group with SSH access and Kubernetes API port
- **SSH Key**: Auto-generated SSH key pair managed by Terraform

## Prerequisites

1. **AWS CLI** configured with credentials
   ```bash
   aws configure
   ```

2. **Terraform** installed (>= 1.0)
   ```bash
   brew install terraform  # macOS
   ```

3. **AWS Credentials** with permissions to create:
   - EC2 instances
   - Security groups
   - Key pairs
   - Elastic IPs

## Project Structure

```
ec2-k8s-vms/
├── main.tf                          # Root configuration
├── variables.tf                     # Variable declarations with defaults
├── outputs.tf                       # Root outputs
├── terraform/
│   └── modules/
│       └── ec2-instance/            # Reusable EC2 module
│           ├── main.tf              # Module resources
│           ├── variables.tf         # Module variables
│           ├── outputs.tf           # Module outputs
│           └── versions.tf          # Provider versions
└── README.md
```

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

This downloads the required provider plugins.

### 2. Review the Plan

```bash
terraform plan
```

This shows what resources will be created.

### 3. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will:
- Generate an SSH key pair
- Create a security group
- Launch an EC2 instance with 64GB RAM
- Associate an Elastic IP
- Save the private key as `k8s-vms-key.pem`

### 4. Connect to the Instance

After the apply completes, use the SSH command from the output:

```bash
ssh -i k8s-vms-key.pem ubuntu@<instance-public-ip>
```

Or simply run:
```bash
terraform output -raw ssh_command | bash
```

## Configuration

Edit [terraform.tfvars](terraform.tfvars) to customize:

### Instance Type (for different RAM sizes)

```hcl
instance_type = "m5.4xlarge"  # 64 GB RAM (default)
# instance_type = "r5.2xlarge"   # 64 GB RAM (memory-optimized, cheaper)
# instance_type = "m6i.4xlarge"  # 64 GB RAM (newer generation)
```

### Region

```hcl
aws_region = "ca-west-1"  # Calgary (default)
# aws_region = "us-east-1"  # N. Virginia
```

### Storage

```hcl
root_volume_size = 200  # GB (adjust based on VM requirements)
root_volume_type = "gp3"  # General Purpose SSD
```

### SSH Access Restriction

**IMPORTANT**: Restrict SSH access in production!

```hcl
# Allow from anywhere (current default - NOT RECOMMENDED for production)
ssh_allowed_cidrs = ["0.0.0.0/0"]

# Restrict to your IP (recommended)
ssh_allowed_cidrs = ["YOUR_PUBLIC_IP/32"]
```

Find your public IP:
```bash
curl ifconfig.me
```

## Outputs

After `terraform apply`, you'll get:

```
instance_id         = "i-xxxxxxxxxxxxxxxxx"
instance_public_ip  = "xx.xx.xx.xx"
private_key_path    = "./k8s-vms-key.pem"
ssh_command         = "ssh -i ./k8s-vms-key.pem ubuntu@xx.xx.xx.xx"
```

View outputs anytime:
```bash
terraform output
```

## SSH Key Management

- **Private key**: `k8s-vms-key.pem` (created in project root)
- **Permissions**: Automatically set to `0400`
- **Security**: Never commit the `.pem` file to git (already in `.gitignore`)

Backup the private key securely:
```bash
cp k8s-vms-key.pem ~/backup/k8s-vms-key.pem
chmod 400 ~/backup/k8s-vms-key.pem
```

## Verify Instance

After connecting via SSH, verify the instance:

```bash
# Check RAM
free -h
# Should show ~64GB total

# Check CPU
nproc
# Should show 16 cores

# Check disk space
df -h
# Should show ~200GB on /dev/nvme0n1p1
```

## Cost Estimation

Approximate monthly costs for ca-west-1 (Calgary):

| Instance Type | vCPU | RAM   | On-Demand/month | Spot/month (est.) |
|---------------|------|-------|-----------------|-------------------|
| m5.4xlarge    | 16   | 64 GB | ~$500           | ~$150             |
| r5.2xlarge    | 8    | 64 GB | ~$390           | ~$120             |

Additional costs:
- Storage (200 GB gp3): ~$16/month
- Elastic IP (if instance running): Free
- Data transfer: Varies

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete:
- EC2 instance
- Security group
- Key pair
- Elastic IP

**Note**: The local `.pem` file will remain. Delete manually if needed.

## Module Reusability

The `terraform/modules/ec2-instance` module can be reused for other instances:

```hcl
module "another_instance" {
  source = "./terraform/modules/ec2-instance"

  name_prefix  = "my-other-instance"
  instance_type = "t3.medium"
  vpc_id        = "vpc-xxxxx"
  subnet_id     = "subnet-xxxxx"
}
```

## Next Steps

This infrastructure is ready for:
1. Installing virtualization tools (KVM, libvirt, Vagrant)
2. Creating VMs with Vagrant
3. Setting up Kubernetes with kubeadm
4. Ansible automation for the above

## Troubleshooting

### AWS Credentials Not Found
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

### Permission Denied (SSH)
```bash
chmod 400 k8s-vms-key.pem
```

### Connection Timeout
- Check security group allows your IP
- Verify instance is running: `terraform show | grep instance_state`

### Region Not Available
Some instance types may not be available in ca-west-1. Try:
- Different region: `aws_region = "us-west-2"`
- Different instance type: `instance_type = "r5.2xlarge"`

## Support

For issues with:
- Terraform: [Terraform Documentation](https://www.terraform.io/docs)
- AWS: [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
