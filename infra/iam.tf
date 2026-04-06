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

############################################
# EC2 S3 artifact read access
############################################
# Allow the EC2 application instance to download
# deployment artifacts from the S3 artifact bucket.

resource "aws_iam_role_policy" "ec2_s3_artifact_read" {
  name = "${var.project_name}-ec2-s3-artifact-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.app_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.app_artifacts.arn
      }
    ]
  })
}

############################################
# EC2 SSM Session Manager access
############################################
# Allow EC2 instance to register with AWS Systems Manager
# so the instance can be accessed through Session Manager
# without a public IP or SSH.

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}