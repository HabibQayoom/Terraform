output "access_entry_arns" {
  value = { for k, v in aws_eks_access_entry.direct : k => v.principal_arn }
}
