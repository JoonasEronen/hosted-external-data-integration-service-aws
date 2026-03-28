# Latest Amazon Linux 2023 AMI in the selected region
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

# EC2 instance for the application tier in the private app subnet
resource "aws_instance" "app_server_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_app_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3

              mkdir -p /opt/app
              cd /opt/app

              cat > index.html <<HTML
              <html>
                <head><title>External Data Integration Service</title></head>
                <body>
                  <h1>External Data Integration Service</h1>
                  <p>EC2 application instance is running.</p>
                </body>
              </html>
              HTML

              nohup python3 -m http.server ${var.app_port} --directory /opt/app > /var/log/app-server.log 2>&1 &
              EOF

  tags = {
    Name = "app-server-a"
  }
}

# Attach the EC2 instance to the ALB target group
resource "aws_lb_target_group_attachment" "app_server_a" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_a.id
  port             = var.app_port
}