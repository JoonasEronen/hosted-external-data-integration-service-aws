import json
import os

import boto3


############################################
# AWS Secrets Manager helper
############################################
# Retrieves database credentials securely from
# AWS Secrets Manager at runtime.
#
# The EC2 instance IAM role provides permission
# to access the secret. No credentials are stored
# in the application code or environment variables.


############################################
# Get database password
############################################
# Fetch PostgreSQL password from AWS Secrets Manager.
#
# The secret is expected to contain JSON like:
# {
#   "username": "...",
#   "password": "...",
#   "engine": "postgres",
#   "host": "...",
#   "port": 5432,
#   "dbname": "..."
# }
def get_db_password(secret_arn: str) -> str:
    # Resolve AWS region from runtime environment
    # Default used for local fallback
    region = os.getenv("AWS_REGION", "eu-north-1")

    # Create Secrets Manager client
    client = boto3.client("secretsmanager", region_name=region)

    # Fetch secret value using ARN
    response = client.get_secret_value(SecretId=secret_arn)

    # Secret is stored as JSON string
    secret_string = response["SecretString"]

    # Parse JSON payload
    secret_data = json.loads(secret_string)

    # Return database password field
    return secret_data["password"]