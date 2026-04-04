import json
import boto3


# Retrieve the database password from AWS Secrets Manager
# The EC2 instance role provides access to this secret
def get_db_password(secret_arn: str) -> str:
    client = boto3.client("secretsmanager", region_name="eu-north-1")

    response = client.get_secret_value(SecretId=secret_arn)

    secret_string = response["SecretString"]
    secret_data = json.loads(secret_string)

    return secret_data["password"]