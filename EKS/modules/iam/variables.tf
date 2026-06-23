variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

