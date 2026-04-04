############################################
# RDS DB Subnet Group
############################################
# Defines which private subnets the RDS instance can use.
# Must include at least two subnets in different AZs.
# These are the dedicated DB private subnets.

resource "aws_db_subnet_group" "rds" {
  name        = "${var.project_name}-db-subnet-group"
  description = "DB subnet group for PostgreSQL RDS instance"

  subnet_ids = [
    aws_subnet.private_db_subnet_a.id,
    aws_subnet.private_db_subnet_b.id
  ]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

############################################
# RDS PostgreSQL Instance
############################################
# Private PostgreSQL database for the application.
# - Not publicly accessible
# - Runs in private DB subnets
# - Only accessible from EC2 security group
# - Single-AZ for MVP (HA in later iteration)

resource "aws_db_instance" "postgres" {
  identifier = var.db_identifier

  # Database engine
  engine         = "postgres"
  engine_version = "17.9"

  # Instance sizing (small for MVP)
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  # Initial database
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Security
  publicly_accessible = false
  storage_encrypted   = true

  # Availability
  multi_az = false # V1: single AZ, HA later

  # Lifecycle (dev friendly)
  skip_final_snapshot = true
  deletion_protection = false

  # Ops
  backup_retention_period = 7
  apply_immediately       = true

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}