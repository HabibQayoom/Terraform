# ── prod: based on your actual cluster config ─────────────────
aws_region         = "us-east-1" # change to your real region
vpc_name           = "eks-prod-vpc"
vpc_cidr           = "10.3.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
private_subnets    = ["10.3.10.0/24", "10.3.20.0/24", "10.3.30.0/24"]

cluster_name    = "eks-prod"
cluster_version = "1.30"

node_groups = {
  # On-demand general workload pool
  general = {
    instance_types = ["t3.large"]
    min_size       = 1
    max_size       = 3
    desired_size   = 1
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    labels         = { env = "prod", role = "general" }
    taints         = []
  }
  # Spot pool for cost savings on bursty workloads (uncomment to enable)
  # spot = {
  #   instance_types = ["t3.medium", "t3.large"]
  #   min_size       = 0
  #   max_size       = 3
  #   desired_size   = 0
  #   disk_size      = 20
  #   ami_type       = "AL2_x86_64"
  #   capacity_type  = "SPOT"
  #   labels         = { env = "prod", role = "spot" }
  #   taints         = []
  # }
}

# Add IAM user ARNs to grant cluster access
# admin_user_arns     = ["arn:aws:iam::YOUR_ACCOUNT_ID:user/your-user"]
# developer_user_arns = ["arn:aws:iam::YOUR_ACCOUNT_ID:user/dev-user"]

common_tags = {
  Environment = "prod"
  Project     = "eks-platform"
  ManagedBy   = "terraform"
}
