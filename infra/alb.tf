############################################
# Application Load Balancer
############################################
# Internet-facing ALB deployed across both public subnets.
# Receives HTTP traffic from users and forwards requests
# to the EC2 application target group.

resource "aws_lb" "app_alb" {
  name               = "external-data-integration-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]

  tags = {
    Name = "external-data-integration-alb"
  }
}

############################################
# Target Group
############################################
# Backend target group for the FastAPI application
# running on the private EC2 instance.
# ALB forwards traffic here on the application port.

resource "aws_lb_target_group" "app_tg" {
  name     = "external-data-integration-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health checks validate that the application responds.
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "external-data-integration-tg"
  }
}

############################################
# HTTP Listener
############################################
# Public listener on port 80.
# Forwards incoming traffic to the application target group.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}