resource "aws_s3_bucket" "terraform_state" {
  #checkov:skip=CKV_AWS_18: Access logging not required for Terraform state bucket
  #checkov:skip=CKV_AWS_19: S3 encrypts by default with AES-256 since 2023 - no additional config needed
  #checkov:skip=CKV_AWS_21: Versioning configured via separate aws_s3_bucket_versioning resource in this module
  #checkov:skip=CKV_AWS_144: Cross-region replication not required for Terraform state bucket
  #checkov:skip=CKV_AWS_145: S3 default encryption with AES-256 is sufficient - KMS not required
  bucket = "${var.project_name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "${var.project_name}-terraform-state"
    Owner     = var.owner
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}