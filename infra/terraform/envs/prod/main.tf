data "aws_caller_identity" "current" {}

module "vpc" {
  source          = "../../modules/vpc"
  owner           = var.owner
  project_name    = var.project_name
  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
}

module "eks" {
  source                  = "../../modules/eks"
  cluster_name            = var.cluster_name
  project_name            = var.project_name
  owner                   = var.owner
  eks_public_access_cidrs = var.eks_public_access_cidrs
  desired_size            = var.desired_size
  max_size                = var.max_size
  min_size                = var.min_size
  instance_types          = var.instance_types
  capacity_type           = var.capacity_type
  private_subnets         = module.vpc.private_subnets
  ebs_csi_role_arn        = module.iam.ebs_csi_role_arn
}

module "iam" {
  source                    = "../../modules/iam"
  owner                     = var.owner
  project_name              = var.project_name
  github_repo               = var.github_repo
  github_branch             = var.github_branch
  state_bucket_name         = var.state_bucket_name
  aws_region                = var.aws_region
  aws_account_id            = data.aws_caller_identity.current.account_id
  cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
  cluster_oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  owner        = var.owner
}

module "rds" {
  source                     = "../../modules/rds"
  owner                      = var.owner
  project_name               = var.project_name
  instance_class             = var.instance_class
  db_username                = var.db_username
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnets
  eks_node_security_group_id = module.eks.eks_node_security_group_id
}