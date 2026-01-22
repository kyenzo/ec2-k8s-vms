#!/bin/bash
# Setup S3 Backend for Terraform State
# This creates the S3 bucket and DynamoDB table needed for remote state

set -e

BUCKET_NAME="${1:-terraform-state-$(whoami)-$(date +%s)}"
TABLE_NAME="${2:-terraform-state-lock}"
REGION="${3:-ca-west-1}"

echo "============================================"
echo "  Setup Terraform Remote State Backend"
echo "============================================"
echo ""
echo "This will create:"
echo "  • S3 Bucket: $BUCKET_NAME"
echo "  • DynamoDB Table: $TABLE_NAME"
echo "  • Region: $REGION"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "[1/3] Creating S3 bucket for state storage..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || echo "Bucket might already exist"

# Enable versioning
echo "[2/3] Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region "$REGION"

# Enable encryption
echo "      Enabling encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --region "$REGION"

# Block public access
echo "      Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"

# Create DynamoDB table for state locking
echo "[3/3] Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" 2>/dev/null || echo "Table might already exist"

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "============================================"
echo "  Next Steps"
echo "============================================"
echo ""
echo "1. Update backend.tf with these values:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$TABLE_NAME\""
echo ""
echo "2. Initialize terraform with the backend:"
echo "   terraform init -migrate-state"
echo ""
echo "3. Verify state is in S3:"
echo "   aws s3 ls s3://$BUCKET_NAME/ec2-k8s-vms/"
echo ""
