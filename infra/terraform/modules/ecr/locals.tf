locals {
  common_tags = {
    Project   = var.project_name
    Owner     = var.owner
    ManagedBy = "Terraform"
  }
}