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
# Triggers if the ALB target group has no healthy targets.
# This indicates that all application instances are unhealthy or unreachable.

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

  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [aws_sns_topic.alarm_notifications.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-no-healthy-hosts"
  }
}

############################################
# CloudWatch Alarm: EC2 High CPU
############################################
# Creates one CPU alarm per EC2 instance using for_each.
# Triggers when an instance's CPU utilization stays above 80%.

resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  for_each = aws_instance.app_server

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-ec2-high-cpu"
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
    InstanceId = each.value.id
  }

  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
  ok_actions    = [aws_sns_topic.alarm_notifications.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-ec2-high-cpu"
  }
}

############################################
# SNS Alarm Notifications
############################################
# SNS topic used by CloudWatch alarms.

resource "aws_sns_topic" "alarm_notifications" {
  name = "${var.project_name}-${var.environment}-alarm-notifications"
}

############################################
# SNS Email Subscription
############################################
# Email address is provided via variable and not hardcoded.

resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}