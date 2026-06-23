provider "aws" {
  region = var.aws_region
  # Credentials: set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars
  # or configure ~/.aws/credentials
}
