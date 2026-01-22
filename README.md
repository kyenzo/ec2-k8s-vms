# EC2 Kubernetes VMs Infrastructure

This project provisions an EC2 instance with 64GB RAM on AWS using Terraform, designed to host multiple VMs for a bare-metal Kubernetes cluster.

## Architecture

- **EC2 Instance**: r5.2xlarge Spot (8 vCPU, 64 GiB RAM) in ca-west-1
- **Instance Type**: Spot instance (saves ~60% vs on-demand)
- **Storage**: 200 GB gp3 root volume
- **Networking**: Default VPC with public IP and Elastic IP
- **Security**: Security group with SSH access and Kubernetes API port
- **SSH Key**: Auto-generated SSH key pair managed by Terraform
- **Estimated Cost**: ~$110-130/month (spot) vs ~$390/month (on-demand)

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

All variables have sensible defaults in [variables.tf](variables.tf). To customize, you have several options:

### Option 1: Command-line Flags

```bash
# Change instance type
terraform apply -var="instance_type=r5.2xlarge"

# Change region
terraform apply -var="aws_region=us-west-2"

# Multiple variables
terraform apply \
  -var="instance_type=r5.2xlarge" \
  -var="root_volume_size=300"
```

### Option 2: Environment Variables

```bash
export TF_VAR_instance_type="r5.2xlarge"
export TF_VAR_aws_region="us-west-2"
terraform apply
```

### Option 3: Create terraform.tfvars (Optional)

Create `terraform.tfvars` for persistent overrides:

```hcl
# Override defaults
instance_type = "r5.2xlarge"  # Memory-optimized, cheaper for 64GB
root_volume_size = 300        # More space for VMs
ssh_allowed_cidrs = ["YOUR_IP/32"]  # Restrict SSH access
```

### Available Instance Types (64GB RAM)

```hcl
instance_type = "r5.2xlarge"   # 8 vCPU, 64 GB RAM (default, memory-optimized)
instance_type = "m5.4xlarge"   # 16 vCPU, 64 GB RAM (more CPU power)
instance_type = "m6i.4xlarge"  # 16 vCPU, 64 GB RAM (newer generation)
```

### Spot vs On-Demand Instances

By default, this project uses **Spot instances** to save ~60% on costs. Spot instances can be interrupted with 2-minute notice (rare for r5 types).

```bash
# Disable spot (use on-demand instead)
terraform apply -var="use_spot_instance=false"

# Set custom max spot price (optional)
terraform apply -var="spot_max_price=0.15"
```

**Spot instance behavior:**
- **Interruption**: If AWS needs capacity, instance is stopped (not terminated)
- **Restart**: Instance automatically restarts when capacity available
- **Data**: EBS volume persists, no data loss
- **Best for**: Dev/learning environments

### SSH Access Restriction

**IMPORTANT**: The default allows SSH from anywhere (`0.0.0.0/0`). Restrict in production:

```bash
# Get your public IP
curl ifconfig.me

# Apply with restricted access
terraform apply -var='ssh_allowed_cidrs=["YOUR_IP/32"]'
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
# Should show 8 cores (r5.2xlarge default)

# Check disk space
df -h
# Should show ~200GB on /dev/nvme0n1p1
```

## Cost Estimation

**Current Configuration (r5.2xlarge Spot)**:
- **EC2 Spot**: ~$110-130/month
- **Storage (200 GB gp3)**: ~$16/month
- **Total**: ~$126-146/month

### Cost Comparison for ca-west-1 (Calgary)

| Instance Type | vCPU | RAM   | On-Demand/month | Spot/month | Savings |
|---------------|------|-------|-----------------|------------|---------|
| **r5.2xlarge** (default) | 8 | 64 GB | ~$390 | **~$120** | **69%** |
| m5.4xlarge    | 16   | 64 GB | ~$560           | ~$170     | 70%     |

**Additional costs:**
- Storage (200 GB gp3): ~$16/month
- Elastic IP (if instance running): Free
- Data transfer: First 100 GB free, then $0.09/GB

**Spot vs On-Demand**: By default, this setup uses Spot instances for maximum savings. Spot interruptions are rare for r5 types, and the instance will automatically restart when capacity is available.

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

  name_prefix       = "my-other-instance"
  instance_type     = "t3.medium"
  vpc_id            = "vpc-xxxxx"
  subnet_id         = "subnet-xxxxx"
  use_spot_instance = true  # Enable spot for savings
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
- Different instance type: `instance_type = "r5a.2xlarge"`

### Spot Instance Interrupted
If your spot instance is stopped due to capacity:
- **Wait**: Instance will auto-restart when capacity available (usually minutes)
- **Switch region**: Try a different region with more capacity
- **Use on-demand**: `terraform apply -var="use_spot_instance=false"` (costs more)

Check spot interruption frequency:
```bash
# View spot instance history
aws ec2 describe-spot-instance-requests --region ca-west-1
```

## Support

For issues with:
- Terraform: [Terraform Documentation](https://www.terraform.io/docs)
- AWS: [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
