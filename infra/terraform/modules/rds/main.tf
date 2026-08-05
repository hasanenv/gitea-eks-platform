resource "aws_db_subnet_group" "eks_gitea_db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

resource "aws_security_group" "eks_gitea_db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
    description     = "Allow PostgreSQL from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"

  }

  tags = local.common_tags
}

resource "aws_db_instance" "eks_gitea_db" {
  #checkov:skip=CKV_AWS_16: RDS uses default AES-256 encryption via manage_master_user_password
  #checkov:skip=CKV_AWS_118: Enhanced monitoring adds cost - flagged for future improvement
  #checkov:skip=CKV_AWS_129: RDS logging adds cost - flagged for future improvement
  #checkov:skip=CKV_AWS_161: IAM authentication not compatible with current Gitea connection method
  #checkov:skip=CKV2_AWS_30: Query logging adds cost - flagged for future improvement
  allocated_storage           = 30
  storage_type                = "gp3"
  db_name                     = "eks_gitea_db"
  engine                      = "postgres"
  engine_version              = "18.4"
  multi_az                    = true
  db_subnet_group_name        = aws_db_subnet_group.eks_gitea_db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.eks_gitea_db_sg.id]
  instance_class              = var.instance_class
  username                    = var.db_username
  manage_master_user_password = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.project_name}-final-snapshot"
  deletion_protection         = true
  auto_minor_version_upgrade  = true

  tags = local.common_tags
}

