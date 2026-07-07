terraform {
  required_version = ">= 1.15"

  backend "s3" {
    bucket       = "gitea-eks-platform-terraform-state"
    key          = "prod/terraform.tfstate" #file path within the bucket to store the state file
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}