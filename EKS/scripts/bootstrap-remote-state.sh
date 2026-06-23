#!/usr/bin/env bash
# Creates S3 bucket + DynamoDB table for Terraform remote state.
# Run ONCE before the first terraform init.
#
# Usage: ./scripts/bootstrap-remote-state.sh [region]
set -euo pipefail

REGION="${1:-us-east-1}"
BUCKET="tf-eks-state-$(date +%s | tail -c 8)"
TABLE="terraform-lock"

echo "Creating S3 bucket: $BUCKET"
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
fi

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Creating DynamoDB lock table: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "Done. Update each environments/<env>/backend.tf with:"
echo "  bucket         = \"$BUCKET\""
echo "  region         = \"$REGION\""
echo "  dynamodb_table = \"$TABLE\""
