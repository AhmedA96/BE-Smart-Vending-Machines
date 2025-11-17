################################################################################
# Security Groups - Network Access Control
#
# Security groups implement a firewall at the instance level.
# Each component has a dedicated security group with least-privilege access.
#
# Traffic Flow:
# Internet → IGW → ALB SG (port 80/443) → App SG (8080/3000)
#         ↓
#       App SG (port 5432) → Database SG
#       App SG (port 6379) → Redis SG
################################################################################

# ==============================================================================
# 1. Application Load Balancer Security Group
# ==============================================================================
# Allows inbound HTTPS/HTTP from anywhere (clients on internet)
# Allows outbound to app servers only

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  # Ingress: Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet (Cloudflare)"
  }

  # Egress: Allow to app servers in private subnets (port 8080/3000 for Rails)
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "To app servers on port 8080"
  }

  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "To app servers on port 3000 (alternative)"
  }

  # Egress: Allow DNS (required for domain lookups)
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ==============================================================================
# 2. Application Server Security Group
# ==============================================================================
# Allows inbound from ALB only
# Allows outbound to database and Redis

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow from ALB on port 8080 (Rails server)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Rails server from ALB"
  }

  # Ingress: Allow from ALB on port 3000 (alternative)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Puma/Rails from ALB (alternative)"
  }

  # Ingress: Allow SSH from internal IPs only (for debugging)
  # Optional: Replace with bastion host for production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "SSH from VPC only (no internet access)"
  }

  # Ingress: Allow from other app servers (for internal communication)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "All TCP from other app servers"
  }

  # Egress: Allow to database on port 5432 (PostgreSQL)
  # Using VPC CIDR instead of SG reference to avoid circular dependency
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "PostgreSQL database"
  }

  # Egress: Allow to Redis on port 6379
  # Using VPC CIDR instead of SG reference to avoid circular dependency
  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Redis cache"
  }

  # Egress: Allow HTTPS to internet (for external APIs, package managers)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to internet (API calls, bundle install)"
  }

  # Egress: Allow HTTP to internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP to internet"
  }

  # Egress: Allow DNS queries
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# ==============================================================================
# 3. Database Security Group
# ==============================================================================
# Allows inbound from app servers only on PostgreSQL port

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-database-"
  description = "Security group for Aurora PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow PostgreSQL from app servers only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "PostgreSQL from app servers"
  }

  # Ingress: Allow from other database instances (replication)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
    description = "PostgreSQL between cluster members"
  }

  # Egress: Minimal (databases don't typically need outbound)
  # Allow for backups to S3 via IAM role
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for Aurora backups to S3"
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

# ==============================================================================
# 4. Redis Security Group
# ==============================================================================
# Allows inbound from app servers only on Redis port

resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  description = "Security group for Redis ElastiCache"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow Redis from app servers only
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Redis from app servers"
  }

  # Ingress: Allow from other Redis nodes (replication)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
    description = "Redis between cluster members"
  }

  # Egress: Allow all (for cluster communication and monitoring)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# ==============================================================================
# 5. NAT Gateway EIP (Already in vpc.tf but referenced here for completeness)
# ==============================================================================
# The NAT gateway itself is not in a security group.
# It uses the Elastic IP from the public subnet.
# Traffic flows: Private subnets → NAT Gateway → Internet

# ==============================================================================
# Security Group Architecture Diagram
# ==============================================================================
#
# INTERNET (0.0.0.0/0)
#     ↓
# [Internet Gateway]
#     ↓
# ALB Security Group (ports 80, 443)
#     ↓
# [Application Load Balancer]
#     ↓
# App Security Group (port 8080/3000)
#     ├─→ [App Servers]
#     │
#     ├─→ Database Security Group (port 5432)
#     │       └─→ [Aurora PostgreSQL Cluster]
#     │
#     └─→ Redis Security Group (port 6379)
#             └─→ [Redis ElastiCache]
#
# NAT Gateway (in public subnet)
#     ↓
# Private subnets → outbound internet (HTTPS/HTTP)
#
# ==============================================================================
# Principle: Least Privilege Access
# ==============================================================================
#
# Each security group only allows:
# 1. Inbound from necessary sources (ALB → App, App → DB/Redis)
# 2. Outbound to necessary destinations
#
# No unnecessary ports exposed
# No default "allow all" rules
#
# Examples of blocked traffic:
# - Internet directly to app servers (must go through ALB)
# - App servers directly accessing other app servers' ports (SSH only from VPC)
# - Database accepting connections from internet
# - Redis exposed publicly
#
# ==============================================================================
# Notes on Security Group Rules
# ==============================================================================
#
# EGRESS from ALB:
# - Only to app servers (8080/3000)
# - Not to database or Redis (app servers do that)
#
# EGRESS from App:
# - Database (5432) and Redis (6379) in private subnets
# - HTTPS/HTTP to internet for external APIs
# - DNS for domain resolution
#
# INGRESS to Database:
# - Only from app servers (no internet access)
# - Between cluster members for replication
#
# INGRESS to Redis:
# - Only from app servers (no internet access)
# - Between cluster members for replication
#
# ==============================================================================
# Future Security Enhancements
# ==============================================================================
#
# 1. WAF (Web Application Firewall)
#    - Add to ALB for DDoS protection
#    - Rate limiting rules
#    - SQL injection prevention
#
# 2. Network ACLs
#    - Subnet-level firewall rules
#    - More granular control than security groups
#
# 3. VPN / Bastion Host
#    - Secure SSH access instead of allowing VPC-wide
#    - Reduces SSH attack surface
#
# 4. VPC Flow Logs
#    - Monitor all network traffic
#    - Detect anomalies
#    - Compliance and forensics
#
# 5. GuardDuty
#    - AWS managed threat detection
#    - Alerts on suspicious activity
#

