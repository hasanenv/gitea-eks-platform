output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.eks_cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_db_name" {
  value = module.rds.db_name
  sensitive = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}