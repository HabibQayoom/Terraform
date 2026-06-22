# ── dev: cheapest viable config ──────────────────────────────
aws_region         = "us-east-1"
vpc_name           = "eks-dev-vpc"
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets    = ["10.1.10.0/24", "10.1.20.0/24"]

cluster_name    = "eks-dev"
cluster_version = "1.30"

node_groups = {
  general = {
    instance_types = ["t3.small"]
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT" # Use spot to save cost in dev
    labels         = { env = "dev", role = "general" }
    taints         = []
  }
}

common_tags = {
  Environment = "dev"
  Project     = "eks-platform"
  ManagedBy   = "terraform"
}
