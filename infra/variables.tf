# =====================
# Project metadata
# =====================

variable "project_name" {
  description = "Project name used in tags and resource naming."
  type        = string
  default     = "hosted-external-data-integration-service"
}

variable "environment" {
  description = "Environment name used in tags and naming (dev/stage/prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-north-1"
}

# =====================
# Networking
# =====================

variable "vpc_cidr" {
  description = "CIDR block for the main VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A (ALB and NAT Gateway)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B (ALB subnet)."
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_app_subnet_a_cidr" {
  description = "CIDR block for private application subnet A (EC2 app tier)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_app_subnet_b_cidr" {
  description = "CIDR block for private application subnet B (EC2 app tier)."
  type        = string
  default     = "10.0.5.0/24"
}

variable "private_db_subnet_a_cidr" {
  description = "CIDR block for private database subnet A (RDS subnet group)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_db_subnet_b_cidr" {
  description = "CIDR block for private database subnet B (RDS subnet group)."
  type        = string
  default     = "10.0.6.0/24"
}

variable "az_a" {
  description = "Availability Zone A for multi-AZ resources."
  type        = string
  default     = "eu-north-1a"
}

variable "az_b" {
  description = "Availability Zone B for multi-AZ resources."
  type        = string
  default     = "eu-north-1b"
}

# =====================
# Compute
# =====================

variable "instance_type" {
  description = "EC2 instance type for the application server."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Application port exposed by the FastAPI service on EC2."
  type        = number
  default     = 8000
}

# =====================
# Database
# =====================

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "p2-postgres"
}

variable "db_name" {
  description = "Name of the PostgreSQL application database."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the PostgreSQL database."
  type        = string
  default     = "appuser"
}

variable "db_instance_class" {
  description = "RDS instance class for PostgreSQL."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage size in GB for the PostgreSQL database."
  type        = number
  default     = 20
}