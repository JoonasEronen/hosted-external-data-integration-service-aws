############################################
# Terraform Configuration
############################################

# Restrict Terraform to version 1.x to avoid breaking changes from 2.0.
terraform {
  required_version = "~> 1.14"

  # Use the latest compatible AWS provider within the 5.x series.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}