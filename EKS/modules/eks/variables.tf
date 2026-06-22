variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR (for security group rules)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS nodes (private subnets)."
  type        = list(string)
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  type        = string
}

variable "node_instance_role_arn" {
  description = "IAM role ARN for worker nodes."
  type        = string
}

variable "node_groups" {
  description = "Map of node group configurations."
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

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
