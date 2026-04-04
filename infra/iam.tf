############################################
# EC2 Assume Role Policy
############################################
# Allows the EC2 service to assume this IAM role

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

############################################
# EC2 IAM Role
############################################
# IAM role used by the application server instance

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

############################################
# EC2 Instance Profile
############################################
# Instance profile required to attach IAM role to EC2

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

############################################
# EC2 Secrets Manager Access Policy
############################################
# Allow EC2-hosted application to read the RDS-generated database secret
# The password is stored in AWS Secrets Manager and fetched at runtime

resource "aws_iam_role_policy" "ec2_secrets_access" {
  name = "${var.project_name}-ec2-secrets-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      }
    ]
  })
}