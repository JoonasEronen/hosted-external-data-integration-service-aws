############################################
# AWS Provider
############################################
# Configure AWS provider using region from variables

provider "aws" {
  region = var.aws_region
}