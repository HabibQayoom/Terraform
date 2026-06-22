variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "vpc_name" {
  description = "VPC name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs (EKS nodes)."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways."
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Create VPN Gateway."
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Map of node groups."
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
    capacity_type  = string
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "admin_user_arns" {
  description = "IAM user ARNs granted admin access."
  type        = list(string)
  default     = []
}

variable "developer_user_arns" {
  description = "IAM user ARNs granted developer access."
  type        = list(string)
  default     = []
}

variable "direct_user_access" {
  description = "Users with direct cluster access entries."
  type = list(object({
    arn        = string
    username   = string
    policy_arn = string
  }))
  default = []
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

