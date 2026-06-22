variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "node_instance_role_arn" {
  description = "ARN of the node instance IAM role."
  type        = string
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
  description = "Users with direct EKS access entries."
  type = list(object({
    arn        = string
    username   = string
    policy_arn = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
