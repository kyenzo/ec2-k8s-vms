# EC2 Kubernetes VMs Infrastructure

This project provisions an EC2 instance with 64GB RAM on AWS using Terraform, designed to host multiple VMs for a bare-metal Kubernetes cluster.

## Architecture

- **EC2 Instance**: r5.2xlarge On-Demand (8 vCPU, 64 GiB RAM) in ca-west-1
- **Instance Type**: On-Demand (reliable, always available)
- **Storage**: 200 GB gp3 root volume
- **Networking**: Default VPC with public IP and Elastic IP
- **Security**: Security group with SSH access and Kubernetes API port
- **SSH Key**: Auto-generated SSH key pair managed by Terraform
- **Auto-Install**: KVM, Vagrant, Ansible, kubectl, Docker (via cloud-init)
- **Estimated Cost**: ~$406/month (on-demand)

### Pre-installed Tools (Automatic)

On first boot, the instance automatically installs:

| Tool | Purpose | Version |
|------|---------|---------|
| **KVM/libvirt** | Hardware virtualization for VMs | Latest |
| **Vagrant** | VM lifecycle management | Latest from HashiCorp |
| **vagrant-libvirt** | Vagrant provider for KVM | Latest plugin |
| **Ansible** | Configuration management & automation | Latest from PPA |
| **kubectl** | Kubernetes command-line tool | v1.28 |
| **Docker** | Container runtime | Latest CE |
| **Utilities** | git, vim, htop, jq, curl, wget, etc. | Latest |

**Installation time**: 5-10 minutes on first boot

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
├── scripts/
│   └── install-k8s-tools.sh         # Auto-installs KVM, Vagrant, Ansible, kubectl
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

### 5. Wait for Tools Installation (First Boot Only)

On first boot, the instance automatically installs:
- **KVM/libvirt** (virtualization)
- **Vagrant + vagrant-libvirt** (VM management)
- **Ansible** (automation)
- **kubectl** (Kubernetes CLI)
- **Docker** (containerization)
- **Additional utilities** (git, vim, htop, jq, etc.)

**Check installation status:**
```bash
# Wait 5-10 minutes for installation to complete, then SSH in and check:
tail -f /var/log/install-k8s-tools.log

# Or check if installation is complete:
cat /etc/motd
```

Installation takes **5-10 minutes**. Once complete, you'll see a welcome message when you SSH in.

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

By default, this project uses **On-Demand instances** for reliability. You can optionally enable Spot instances to save ~60% on costs.

```bash
# Enable spot (saves money but less reliable)
terraform apply -var="use_spot_instance=true"

# Set custom max spot price (optional)
terraform apply -var="use_spot_instance=true" -var="spot_max_price=0.15"
```

**On-Demand (default):**
- ✅ Always available
- ✅ No interruptions
- ❌ ~$270/month more expensive than spot

**Spot (optional):**
- ✅ 60-70% cheaper
- ❌ Can be interrupted with 2-minute notice
- ❌ May need to wait for capacity
- **Best for**: Dev/learning environments where interruptions are acceptable

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

After connecting via SSH, verify the instance and installed tools:

### System Resources
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

### Installed Tools
```bash
# Verify KVM/libvirt
virsh --version
sudo virsh list --all

# Verify Vagrant
vagrant --version
vagrant plugin list | grep libvirt

# Verify Ansible
ansible --version

# Verify kubectl
kubectl version --client

# Verify Docker
docker --version
docker ps

# Check installation log
cat /var/log/install-k8s-tools.log
```

## Cost Estimation

**Current Configuration (r5.2xlarge On-Demand)**:
- **EC2 On-Demand**: ~$390/month
- **Storage (200 GB gp3)**: ~$16/month
- **Total**: ~$406/month

### Cost Comparison for ca-west-1 (Calgary)

| Instance Type | vCPU | RAM   | On-Demand/month (default) | Spot/month (optional) | Spot Savings |
|---------------|------|-------|---------------------------|----------------------|--------------|
| **r5.2xlarge** | 8 | 64 GB | **~$390** | ~$120 | 69% |
| m5.4xlarge    | 16   | 64 GB | ~$560           | ~$170     | 70%     |

**Additional costs:**
- Storage (200 GB gp3): ~$16/month
- Elastic IP (if instance running): Free
- Data transfer: First 100 GB free, then $0.09/GB

**Note**: On-Demand is the default for reliability. Enable spot with `-var="use_spot_instance=true"` if you want to save ~$270/month but can tolerate interruptions.

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

The instance comes pre-configured with all necessary tools. You can now:

1. **Clone your Ansible/Vagrant repository**
   ```bash
   git clone <your-k8s-config-repo>
   cd <your-k8s-config-repo>
   ```

2. **Create VMs with Vagrant**
   ```bash
   vagrant up
   ```

3. **Configure Kubernetes with Ansible**
   ```bash
   cd ansible
   ansible-playbook playbooks/install-kubernetes.yml
   ```

4. **Access your cluster**
   ```bash
   kubectl get nodes
   ```

### Recommended Workflow

**For local development on your Mac:**
- Use **VS Code Remote SSH** extension to edit files directly on the instance
- Automatic port forwarding for web apps
- No need to commit/push for every change

**Setup VS Code Remote SSH:**
1. Install "Remote - SSH" extension in VS Code
2. Add SSH config:
   ```
   Host k8s-dev
     HostName <instance-public-ip>
     User ubuntu
     IdentityFile /path/to/k8s-vms-key.pem
   ```
3. Connect and start coding!

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
