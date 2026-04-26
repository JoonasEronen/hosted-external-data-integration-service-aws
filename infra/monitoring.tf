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


############################################
# CloudWatch Alarm: ALB Unhealthy Backend
############################################
# Triggers if the ALB has no healthy EC2 targets.
# This indicates that the application is down or unreachable.

resource "aws_cloudwatch_metric_alarm" "alb_no_healthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-no-healthy-hosts"
  alarm_description   = "ALB target group has no healthy EC2 targets."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  period              = 60
  statistic           = "Minimum"
  treat_missing_data  = "breaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"

  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-no-healthy-hosts"
  }
}


############################################
# CloudWatch Alarm: EC2 High CPU
############################################
# Triggers when the EC2 application instance CPU usage
# stays above 80% for multiple evaluation periods.

resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ec2-high-cpu"
  alarm_description   = "EC2 application instance CPU utilization is above 80%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period              = 300
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    InstanceId = aws_instance.app_server_a.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-high-cpu"
  }
}