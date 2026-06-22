module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.common_tags
}

module "iam" {
  source       = "../../modules/iam"
  cluster_name = var.cluster_name
  tags         = var.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  vpc_cidr                             = module.vpc.vpc_cidr_block
  subnet_ids                           = module.vpc.private_subnets
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_groups                          = var.node_groups
  cluster_service_role_arn             = module.iam.cluster_service_role_arn
  node_instance_role_arn               = module.iam.node_instance_role_arn
  tags                                 = var.common_tags

  depends_on = [module.vpc]
}

module "iam_oidc" {
  source = "../../modules/iam_oidc"

  cluster_name              = var.cluster_name
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  tags                      = var.common_tags

  depends_on = [module.eks]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = module.iam_oidc.ebs_csi_driver_role_arn
  preserve                    = true
  depends_on                  = [module.eks, module.iam_oidc]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true
  depends_on                  = [module.eks]
}

module "iam_cluster_access" {
  source = "../../modules/iam_cluster_access"

  cluster_name           = var.cluster_name
  node_instance_role_arn = module.iam.node_instance_role_arn
  admin_user_arns        = var.admin_user_arns
  developer_user_arns    = var.developer_user_arns
  direct_user_access     = var.direct_user_access
  tags                   = var.common_tags

  depends_on = [module.eks]
}
