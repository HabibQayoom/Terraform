variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL from the EKS cluster."
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
