############################################
# Application artifact bucket
############################################
# Stores deployable application artifacts uploaded by GitHub Actions.
# The EC2 instance downloads the latest application package from this bucket.

resource "aws_s3_bucket" "app_artifacts" {
  bucket = "joonaseronen-external-data-integration-artifacts-eu-north-1"

  tags = {
    Name        = "app-artifacts"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

############################################
# Block public access
############################################
# Application artifacts should never be publicly accessible.

resource "aws_s3_bucket_public_access_block" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}