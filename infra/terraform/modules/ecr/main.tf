resource "aws_ecr_repository" "gitea" {
  name                 = "${var.project_name}-gitea"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}