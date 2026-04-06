#################################################
# Terraform Remote State
#################################################

terraform {
  backend "s3" {

    # Remote state bucket 
    bucket = "tfstate-joonaseronen-eu-north-1"

    # Project-specific state key
    key = "hosted-external-data-integration-service-aws/terraform.tfstate"

    # State bucket region
    region = "eu-north-1"

    # State locking
    dynamodb_table = "terraform-locks"

    # Encrypt state at rest
    encrypt = true
  }
}