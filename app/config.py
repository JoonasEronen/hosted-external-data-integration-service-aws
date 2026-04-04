import os

# Database connection settings loaded from environment variables
# Non-secret values are provided by Terraform / EC2 runtime configuration
# The database password is fetched separately from AWS Secrets Manager

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")  # Default PostgreSQL port
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_SECRET_ARN = os.getenv("DB_SECRET_ARN")