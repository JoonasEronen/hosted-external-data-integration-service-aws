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
# IAM instance profile is attached so the application can later
# read the database secret from AWS Secrets Manager at runtime.

resource "aws_instance" "app_server_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_app_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3

              mkdir -p /opt/app
              cd /opt/app

              # Runtime environment placeholder file for the future application service.
              # Password is NOT stored here.
              cat > /opt/app/app.env <<ENVVARS
              DB_HOST=${aws_db_instance.postgres.address}
              DB_PORT=5432
              DB_NAME=${var.db_name}
              DB_USER=${var.db_username}
              DB_SECRET_ARN=${aws_db_instance.postgres.master_user_secret[0].secret_arn}
              ENVVARS

              cat > index.html <<HTML
              <html>
                <head><title>External Data Integration Service</title></head>
                <body>
                  <h1>External Data Integration Service</h1>
                  <p>EC2 application instance is running.</p>
                  <p>Database runtime configuration file created.</p>
                </body>
              </html>
              HTML

              nohup python3 -m http.server ${var.app_port} --directory /opt/app > /var/log/app-server.log 2>&1 &
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