output "db_instance_endpoint" {
  value = aws_db_instance.eks_gitea_db.endpoint
}

output "db_instance_arn" {
  value = aws_db_instance.eks_gitea_db.arn
}

output "db_instance_identifier" {
  value = aws_db_instance.eks_gitea_db.identifier
}

output "db_instance_username" {
  value = aws_db_instance.eks_gitea_db.username
}

output "db_name" {
  value     = aws_db_instance.eks_gitea_db.db_name
  sensitive = true
}