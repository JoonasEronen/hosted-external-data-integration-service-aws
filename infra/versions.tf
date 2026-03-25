# Allow Terraform 1.x versions, block 2.0 breaking changes
terraform {
  required_version = "~> 1.14"
  
# Use latest compatible AWS provider in 5.x series
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}