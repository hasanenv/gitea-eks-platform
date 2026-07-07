locals {
  common_tags = {
    Owner     = var.owner
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}