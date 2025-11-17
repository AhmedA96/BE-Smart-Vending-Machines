################################################################################
# VPC Networking Foundation (Cost-Optimized Single AZ)
# 
# COST OPTIMIZATION CHANGES:
# - Single AZ instead of multi-AZ (saves ~50% on infrastructure)
# - Single public subnet (instead of 2)
# - Single private app subnet (instead of 2)
# - Single private db subnet (instead of 2)
# - Single NAT Gateway (instead of 2)
#
# Suitable for: Development, staging, or cost-conscious production
# Trade-off: No automatic failover across AZs, but significant cost savings
################################################################################

# ==============================================================================
# 1. VPC (Virtual Private Cloud)
# ==============================================================================
# The VPC is the isolated network environment where all our infrastructure lives.
# Think of it as a private data center in AWS.
#
# Key concepts:
# - CIDR block: 10.0.0.0/16 gives us 65,536 IP addresses to work with
# - DNS support: Enabled so resources can resolve internal DNS names
# - DNS hostnames: Enabled so EC2 instances get DNS hostnames automatically

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ==============================================================================
# 2. Internet Gateway (IGW)
# ==============================================================================
# The Internet Gateway allows communication between resources in the VPC 
# and the public internet.
#
# Usage:
# - Attached to the VPC
# - Required for public subnets to reach the internet
# - Load balancer uses this to receive traffic from clients

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ==============================================================================
# 3. Public Subnet (Single AZ - Cost Optimized)
# ==============================================================================
# Single public subnet hosts:
# - Application Load Balancer (receives client traffic)
# - NAT Gateway (provides outbound internet for private subnets)
#
# CIDR: 10.0.1.0/24 (256 IPs)

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }
}

# ==============================================================================
# 4. Private Subnets - Application Tier (2 Subnets for HA within Single AZ)
# ==============================================================================
# Hosts application servers and worker processes across 2 subnets.
# Two subnets provide network redundancy and better distribution within the AZ.
#
# CIDR: 10.0.2.0/24 and 10.0.3.0/24 (256 IPs each)

resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-private-app-subnet-1"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-private-app-subnet-2"
    Tier = "private-app"
  }
}

# ==============================================================================
# 5. Private Subnet - Database Tier (Single AZ - Cost Optimized)
# ==============================================================================
# Hosts Aurora PostgreSQL and Redis ElastiCache.
# Separate tier for database isolation and security.
#
# CIDR: 10.0.4.0/24 (256 IPs)

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-private-db-subnet"
    Tier = "private-db"
  }
}

# ==============================================================================
# 6. Elastic IP for NAT Gateway (Single - Cost Optimized)
# ==============================================================================
# Static public IP for NAT Gateway.
# Single NAT Gateway reduces costs compared to multi-AZ setup.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# 7. NAT Gateway (Single - Cost Optimized)
# ==============================================================================
# Enables private subnets to access internet (outbound only).
# Single NAT Gateway in the public subnet serves both private tiers.

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# 8. Route Tables (Simplified for Single AZ)
# ==============================================================================

# ===== Public Route Table =====
# Routes: 0.0.0.0/0 → Internet Gateway
# Used by: Public subnet (ALB and NAT Gateway)

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ===== Private Route Table =====
# Routes: 0.0.0.0/0 → NAT Gateway
# Used by: Private app and db subnets (outbound internet via NAT)

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ==============================================================================
# 9. Route Table Associations (Updated for 2 App Subnets)
# ==============================================================================

# Public subnet → Public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private app subnet 1 → Private route table
resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private.id
}

# Private app subnet 2 → Private route table
resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private.id
}

# Private db subnet → Private route table
resource "aws_route_table_association" "private_db" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private.id
}

# ==============================================================================
# Network Architecture (Cost-Optimized Single AZ with 2 App Subnets)
# ==============================================================================
#
# ┌──────────────────────────────────────────────────────┐
# │ VPC: 10.0.0.0/16                                     │
# │                                                      │
# │ PUBLIC SUBNET (10.0.1.0/24)                         │
# │ ├─ ALB (receives client traffic)                    │
# │ └─ NAT Gateway (outbound internet access)           │
# │        ↓ [IGW]                                       │
# │   Internet Clients                                   │
# │                                                      │
# │ PRIVATE APP SUBNET 1 (10.0.2.0/24)                  │
# │ ├─ Application Servers                             │
# │ └─ Worker Servers                                  │
# │                                                      │
# │ PRIVATE APP SUBNET 2 (10.0.3.0/24)                  │
# │ ├─ Application Servers (replicated)                │
# │ └─ Worker Servers (replicated)                     │
# │        ↓ [NAT Gateway - same AZ]                     │
# │   Outbound internet (packages, updates)             │
# │                                                      │
# │ PRIVATE DB SUBNET (10.0.4.0/24)                     │
# │ ├─ Aurora PostgreSQL Primary                       │
# │ ├─ Aurora PostgreSQL Read Replica                  │
# │ └─ Redis ElastiCache                               │
# │        ↓ [NAT Gateway - same AZ]                     │
# │   Outbound internet (if needed)                     │
# │                                                      │
# └──────────────────────────────────────────────────────┘
#
# DESIGN IMPROVEMENTS FROM PREVIOUS VERSION:
# ──────────────────────────────────────────
# - 2 Private App Subnets: Better distribution and HA within single AZ
# - Aurora PostgreSQL: Multi-master with automatic failover
# - Read Replica: Offload read traffic, data redundancy
#
# COST CONSIDERATIONS:
# ────────────────────
# - Single AZ: Still cost-optimized vs multi-AZ
# - 2 App Subnets: Minimal added cost (just network resources)
# - Aurora: More cost than single RDS but with HA benefits
# - Read Replica: Redundancy for production workloads
