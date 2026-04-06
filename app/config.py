import os

############################################
# Database configuration
############################################
# Database connection settings loaded from environment variables.
#
# These values are injected at runtime by:
# - Terraform (EC2 user data / launch template)
# - or environment configuration on the instance
#
# Sensitive values (like password) are NOT stored here.
# The database password is retrieved separately from AWS Secrets Manager.

# Database host (RDS endpoint)
DB_HOST = os.getenv("DB_HOST")

# PostgreSQL port (default 5432)
DB_PORT = os.getenv("DB_PORT", "5432")

# Database name
DB_NAME = os.getenv("DB_NAME")

# Database username
DB_USER = os.getenv("DB_USER")

# AWS Secrets Manager ARN containing DB credentials
DB_SECRET_ARN = os.getenv("DB_SECRET_ARN")