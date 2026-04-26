############################################
# Monitoring
############################################
# CloudWatch Log Group for application logs.
# Receives logs forwarded from the EC2 instance
# via the CloudWatch Agent.
#
# MVP retention is set to 7 days to control cost.
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/hosted-external-data-integration-service/${var.environment}/app"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}