############################################
# RDS Outputs
############################################

# ARN of the AWS Secrets Manager secret created by RDS.
# Contains the generated master database password.
# Used by the EC2 application to retrieve credentials at runtime.
output "db_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS master password"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

# Database endpoint used by the application to connect to PostgreSQL.
# Passed to the EC2-hosted application as DB_HOST.
output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.address
}