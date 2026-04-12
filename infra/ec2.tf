############################################
# Amazon Linux 2023 AMI
############################################
# Use the latest Amazon Linux 2023 AMI in the selected region

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################
# EC2 Application Instance
############################################
# Application-tier EC2 instance running in the private app subnet.
# IAM instance profile is attached so the application can read:
# - deployment artifacts from S3
# - database secret from AWS Secrets Manager at runtime

resource "aws_instance" "app_server_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_app_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

user_data = <<-EOF
#!/bin/bash
set -e

############################################
# Install runtime dependencies
############################################
dnf update -y
dnf install -y python3 python3-pip unzip awscli

############################################
# Prepare application directory
############################################
mkdir -p /opt/app
cd /opt/app

############################################
# Write runtime environment configuration
############################################
# Password is NOT stored here.
# The application fetches the DB password
# from AWS Secrets Manager at runtime.
cat > /opt/app/app.env <<ENVVARS
DB_HOST=${aws_db_instance.postgres.address}
DB_PORT=5432
DB_NAME=${var.db_name}
DB_USER=${var.db_username}
DB_SECRET_ARN=${aws_db_instance.postgres.master_user_secret[0].secret_arn}
AWS_REGION=${var.aws_region}
ENVVARS

############################################
# Create Python virtual environment
############################################
if [ ! -d /opt/app/.venv ]; then
python3 -m venv /opt/app/.venv
fi
/opt/app/.venv/bin/pip install --upgrade pip       


############################################
# Create systemd service
############################################
cat > /etc/systemd/system/p2-app.service <<SERVICE
[Unit]
Description=P2 FastAPI Service
After=network.target

[Service]
User=ec2-user
Group=ec2-user

WorkingDirectory=/opt/app

EnvironmentFile=/opt/app/app.env
ExecStartPre=/bin/sleep 5
Environment="PATH=/opt/app/.venv/bin"

ExecStart=/opt/app/.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port ${var.app_port}

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

############################################
# Enable service
############################################
systemctl daemon-reload
systemctl enable p2-app     

############################################
# Create deploy script
############################################
cat > /opt/app/deploy_app.sh <<DEPLOY
#!/bin/bash
set -e

echo "[deploy] downloading artifact from S3"
aws s3 cp s3://${aws_s3_bucket.app_artifacts.bucket}/app/latest.zip /opt/app/latest.zip

echo "[deploy] extracting artifact"
unzip -o /opt/app/latest.zip -d /opt/app

echo "[deploy] installing Python dependencies"
/opt/app/.venv/bin/pip install --upgrade pip
/opt/app/.venv/bin/pip install -r /opt/app/requirements.txt

echo "[deploy] restarting service"
systemctl restart p2-app

echo "[deploy] waiting for app startup"
sleep 5

echo "[deploy] health check"
curl -f http://localhost:${var.app_port}/health
DEPLOY

chmod +x /opt/app/deploy_app.sh

############################################
# Run initial deployment
############################################
/opt/app/deploy_app.sh

EOF



tags = {
Name        = "app-server-a"
Environment = var.environment
ManagedBy   = "terraform"
}
}

############################################
# ALB Target Group Attachment
############################################
# Register the EC2 instance as a target behind the Application Load Balancer

resource "aws_lb_target_group_attachment" "app_server_a" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_a.id
  port             = var.app_port
}