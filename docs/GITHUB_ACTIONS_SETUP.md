# GitHub Actions Setup Guide

This guide explains how to set up the GitHub Actions workflow to automatically update secrets in your application repository when you recreate the EC2 instance.

## Architecture

```
┌─────────────────────────────────────────┐
│  ec2-k8s-vms (infrastructure repo)      │
│                                         │
│  1. terraform apply                     │
│     → Creates EC2 instance              │
│     → Generates SSH key locally         │
│     → Stores state in S3                │
│                                         │
│  2. ./scripts/upload-pem-to-github.sh   │
│     → Uploads PEM to THIS repo secrets  │
│                                         │
│  3. Run GitHub Actions workflow         │
│     → Reads EC2 IP from S3 state        │
│     → Reads PEM from THIS repo secrets  │
│     → Updates target repo secrets       │
└─────────────┬───────────────────────────┘
              │
              │ Updates secrets via GH API
              ↓
┌─────────────────────────────────────────┐
│  k8s-app-repo (application repo)        │
│                                         │
│  Secrets updated:                       │
│  • EC2_HOST                             │
│  • EC2_USER                             │
│  • EC2_SSH_PRIVATE_KEY                  │
│  • DEPLOY_PATH                          │
└─────────────────────────────────────────┘
```

## Prerequisites

### 1. Setup Remote Terraform State (S3 Backend)

This is **required** for GitHub Actions to access your terraform outputs.

```bash
# Run the setup script
./scripts/setup-backend.sh

# Follow the prompts - it will create:
# - S3 bucket for state storage (with versioning & encryption)
# - DynamoDB table for state locking
```

After the script completes:

1. Edit `backend.tf` and update the bucket and table names
2. Initialize terraform with the new backend:
   ```bash
   terraform init -migrate-state
   ```
3. Verify state is in S3:
   ```bash
   aws s3 ls s3://YOUR-BUCKET-NAME/ec2-k8s-vms/
   ```

### 2. Create GitHub Personal Access Token (PAT)

The workflow needs a PAT to update secrets in your application repository.

1. Go to GitHub Settings → Developer settings → Personal access tokens → **Tokens (classic)**
2. Click **"Generate new token (classic)"**
3. Select scopes:
   - ✅ `repo` (full control of private repositories)
   - ✅ `admin:org` → `write:org` (for organization repositories)
4. Click **"Generate token"**
5. **Copy the token** (you won't see it again!)

### 3. Add Secrets to THIS Repository

Go to this repo's **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value | Required |
|-------------|-------|----------|
| `GH_PAT` | Your GitHub Personal Access Token | ✅ Yes |
| `AWS_ACCESS_KEY_ID` | Your AWS access key | ✅ Yes |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | ✅ Yes |
| `EC2_SSH_PRIVATE_KEY` | The PEM key (added after terraform apply) | ✅ Yes |

## Usage Workflow

### Step 1: Create EC2 Instance

```bash
# Apply terraform configuration
terraform apply
```

This creates:
- EC2 instance in AWS
- SSH key pair (`k8s-vms-key.pem` locally)
- Remote state in S3

### Step 2: Upload PEM Key to GitHub

```bash
# Upload the PEM key to THIS repository's secrets
./scripts/upload-pem-to-github.sh
```

Or manually:
```bash
# Copy PEM to clipboard
cat k8s-vms-key.pem | pbcopy  # macOS
cat k8s-vms-key.pem | xclip   # Linux

# Go to Settings → Secrets → Actions
# Add secret: EC2_SSH_PRIVATE_KEY
# Paste the PEM key content
```

### Step 3: Run GitHub Actions Workflow

1. Go to **Actions** tab in this repository
2. Select **"Update Application Repository Secrets"**
3. Click **"Run workflow"**
4. Fill in the inputs:
   - **target_repo**: `username/k8s-app-repo`
   - **deploy_path**: `/home/ubuntu/app` (or your custom path)
5. Click **"Run workflow"**

The workflow will:
- ✅ Read EC2 public IP from S3 state
- ✅ Read PEM key from THIS repo's secrets
- ✅ Update all secrets in target repository
- ✅ Show summary of updated secrets

### Step 4: Verify and Deploy

1. Go to your application repository
2. Check **Settings → Secrets → Actions** to verify secrets
3. Trigger your deployment workflow

## Security Model

### ✅ What's Secure

1. **AWS Credentials in GitHub Secrets**
   - Industry standard practice
   - Encrypted at rest
   - Masked in logs

2. **PEM Key Storage**
   - Stored in GitHub Secrets (encrypted)
   - Transferred directly via GitHub API (HTTPS)
   - Never exposed in logs
   - Only visible to workflows with proper permissions

3. **Remote State in S3**
   - Encrypted at rest (AES-256)
   - Versioned (can recover from mistakes)
   - Access controlled by AWS IAM

### 🔒 Security Best Practices

1. **Limit PAT Scope**
   - Only grant necessary scopes
   - Use fine-grained tokens if possible
   - Rotate tokens periodically

2. **Restrict S3 Access**
   - Block public access (done by setup script)
   - Use IAM roles with least privilege
   - Enable MFA delete for production

3. **Secret Rotation**
   - Rotate PEM keys when compromised
   - Update GitHub PAT every 90 days
   - Rotate AWS credentials regularly

4. **Audit Logs**
   - Monitor GitHub Actions runs
   - Enable AWS CloudTrail
   - Review secret access logs

## Troubleshooting

### Error: "Could not get EC2 public IP from terraform"

**Cause**: Terraform state is still local, not in S3

**Fix**:
```bash
# 1. Setup S3 backend
./scripts/setup-backend.sh

# 2. Update backend.tf with bucket/table names
# 3. Migrate state
terraform init -migrate-state
```

### Error: "EC2_SSH_PRIVATE_KEY secret not found"

**Cause**: PEM key hasn't been uploaded to GitHub secrets

**Fix**:
```bash
./scripts/upload-pem-to-github.sh
```

### Error: "Cannot access repository"

**Cause**: PAT doesn't have required scopes or target repo doesn't exist

**Fix**:
1. Verify repository name is correct (format: `owner/repo`)
2. Check PAT has `repo` and `admin:org` scopes
3. Ensure you have admin access to target repository

### Workflow Fails with "Permission denied"

**Cause**: AWS credentials don't have required permissions

**Fix**: Ensure AWS credentials have these permissions:
- `s3:GetObject` on state bucket
- `s3:ListBucket` on state bucket
- `dynamodb:GetItem` on lock table

## Alternative: Local Script

If you prefer not to use GitHub Actions, you can use the local script:

```bash
./scripts/update-secrets.sh username/k8s-app-repo /home/ubuntu/app
```

**Pros:**
- ✅ No need for S3 backend
- ✅ Works with local terraform state
- ✅ Simpler setup

**Cons:**
- ❌ Manual process (not automated)
- ❌ Must run from machine with terraform state
- ❌ Requires local gh CLI setup

## Cost Considerations

### S3 Backend Costs (minimal)

- **S3 Storage**: ~$0.02/month for state files
- **S3 Requests**: Negligible (a few cents/month)
- **DynamoDB**: Free tier covers state locking
- **Total**: < $0.10/month

### GitHub Actions

- **Free tier**: 2,000 minutes/month for private repos
- This workflow uses ~1 minute per run
- Effectively free for normal usage

## Migration from Local State

If you've already been using local state:

```bash
# 1. Setup S3 backend
./scripts/setup-backend.sh

# 2. Update backend.tf with outputs from script

# 3. Migrate existing state
terraform init -migrate-state

# 4. Verify migration
terraform plan  # Should show no changes

# 5. Confirm state in S3
aws s3 ls s3://YOUR-BUCKET/ec2-k8s-vms/
```

Your local state file will be backed up automatically during migration.
