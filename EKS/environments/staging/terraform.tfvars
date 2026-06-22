# ── staging: mirrors prod topology, smaller instances ────────
aws_region         = "us-east-1"
vpc_name           = "eks-staging-vpc"
vpc_cidr           = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnets    = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]

cluster_name    = "eks-staging"
cluster_version = "1.30"

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 3
    desired_size   = 1
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    labels         = { env = "staging", role = "general" }
    taints         = []
  }
}

common_tags = {
  Environment = "staging"
  Project     = "eks-platform"
  ManagedBy   = "terraform"
}
