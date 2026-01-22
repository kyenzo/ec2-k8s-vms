# Terraform Remote State Backend Configuration
# This stores your terraform state in S3 so GitHub Actions can access it

terraform {
  backend "s3" {
    bucket = "REPLACE_WITH_YOUR_BUCKET_NAME"  # e.g., "my-terraform-state-bucket"
    key    = "ec2-k8s-vms/terraform.tfstate"
    region = "ca-west-1"

    # Enable state locking with DynamoDB
    dynamodb_table = "REPLACE_WITH_YOUR_TABLE_NAME"  # e.g., "terraform-state-lock"
    encrypt        = true
  }
}

# To initialize with this backend:
# 1. Create S3 bucket and DynamoDB table (see scripts/setup-backend.sh)
# 2. Update bucket and table names above
# 3. Run: terraform init -migrate-state
