# Security group for the public Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic from the internet to the ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
  }
}

# Allow inbound HTTP from the internet to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Allow all outbound traffic from the ALB
resource "aws_vpc_security_group_egress_rule" "alb_egress_all_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security group for the private EC2 application instance
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow application traffic from the ALB to the EC2 app tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "app-sg"
  }
}

# Allow inbound app traffic from the ALB security group to EC2
resource "aws_vpc_security_group_ingress_rule" "app_ingress_from_alb" {
  security_group_id            = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
}

# Allow all outbound traffic from EC2
resource "aws_vpc_security_group_egress_rule" "app_egress_all_ipv4" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security group for the private PostgreSQL database
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow PostgreSQL traffic from the EC2 app tier to RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "db-sg"
  }
}

# Allow inbound PostgreSQL traffic from the EC2 application security group
resource "aws_vpc_security_group_ingress_rule" "db_ingress_from_app" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

# Allow all outbound traffic from the database security group
resource "aws_vpc_security_group_egress_rule" "db_egress_all_ipv4" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}