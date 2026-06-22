# Grant direct users access via EKS access entries
resource "aws_eks_access_entry" "direct" {
  for_each      = { for u in var.direct_user_access : u.username => u }
  cluster_name  = var.cluster_name
  principal_arn = each.value.arn
  type          = "STANDARD"
  tags          = var.tags
}

resource "aws_eks_access_policy_association" "direct" {
  for_each      = { for u in var.direct_user_access : u.username => u }
  cluster_name  = var.cluster_name
  principal_arn = each.value.arn
  policy_arn    = each.value.policy_arn
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.direct]
}
