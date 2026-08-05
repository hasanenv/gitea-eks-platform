#checkov:skip=CKV_AWS_136: ECR uses default AES-256 encryption which is sufficient
resource "aws_ecr_repository" "gitea" {
  name                 = "${var.project_name}-gitea"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}