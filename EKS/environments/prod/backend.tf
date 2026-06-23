# Remote state in S3.
# Bootstrap once with: scripts/bootstrap-remote-state.sh
# Then fill in bucket name below.
#
# Comment out this whole block to use local state for quick tests.
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_YOUR_BUCKET_NAME"
    key            = "prod/eks.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
