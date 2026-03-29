# Main VPC for the external data integration service
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "external-data-integration-vpc"
  }
}

# Internet Gateway attached to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway"
  }
}

# -----------------------------
# Public subnets (ALB layer)
# -----------------------------

# Public subnet in AZ A for internet-facing components (ALB, NAT)
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

# Public subnet in AZ B for internet-facing components (ALB high availability)
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

# -----------------------------
# Private application subnets
# -----------------------------

# Private application subnet in AZ A for EC2 app tier
resource "aws_subnet" "private_app_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_a_cidr
  availability_zone = var.az_a

  tags = {
    Name = "private-app-subnet-a"
  }
}

# Private application subnet in AZ B for future multi-AZ app tier
resource "aws_subnet" "private_app_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_b_cidr
  availability_zone = var.az_b

  tags = {
    Name = "private-app-subnet-b"
  }
}

# -----------------------------
# Private database subnets
# -----------------------------

# Private database subnet in AZ A
resource "aws_subnet" "private_db_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_a_cidr
  availability_zone = var.az_a

  tags = {
    Name = "private-db-subnet-a"
  }
}

# Private database subnet in AZ B (for future RDS multi-AZ)
resource "aws_subnet" "private_db_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_b_cidr
  availability_zone = var.az_b

  tags = {
    Name = "private-db-subnet-b"
  }
}

# -----------------------------
# Route tables
# -----------------------------

# Public route table for internet-facing resources
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Elastic IP required by the NAT Gateway
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-a"
  }
}

# Single NAT Gateway in AZ A
# Used by private subnets in both AZs to keep MVP simple and reduce cost.
# Can be expanded later to one NAT Gateway per AZ.
resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "nat-gateway-a"
  }

  depends_on = [aws_internet_gateway.main]
}

# Shared private app route table for both AZs
# Both private app subnets use the same NAT Gateway
resource "aws_route_table" "private_app_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_a.id
  }

  tags = {
    Name = "private-app-route-table"
  }
}

# Private database route table (no internet access)
resource "aws_route_table" "private_db_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-route-table"
  }
}

# -----------------------------
# Route table associations
# -----------------------------

# Public subnets -> public route table
resource "aws_route_table_association" "public_subnet_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private app subnets -> shared app route table
resource "aws_route_table_association" "private_app_subnet_a" {
  subnet_id      = aws_subnet.private_app_subnet_a.id
  route_table_id = aws_route_table.private_app_route_table.id
}

resource "aws_route_table_association" "private_app_subnet_b" {
  subnet_id      = aws_subnet.private_app_subnet_b.id
  route_table_id = aws_route_table.private_app_route_table.id
}

# Private DB subnets -> DB route table (no internet)
resource "aws_route_table_association" "private_db_subnet_a" {
  subnet_id      = aws_subnet.private_db_subnet_a.id
  route_table_id = aws_route_table.private_db_route_table.id
}

resource "aws_route_table_association" "private_db_subnet_b" {
  subnet_id      = aws_subnet.private_db_subnet_b.id
  route_table_id = aws_route_table.private_db_route_table.id
}