################################################################################
# Aurora PostgreSQL Database with Read Replica
#
# Aurora is a MySQL/PostgreSQL-compatible relational database engine that combines
# the speed and availability of high-end commercial databases with the
# simplicity and cost-effectiveness of open source databases.
#
# Benefits:
# - Automatic Multi-Master: Read replicas can be promoted to primary instantly
# - Auto-scaling: Storage scales automatically (no need to provision)
# - Point-in-time restore: Up to 35 days of backups
# - Automated failover: If primary fails, replica takes over
# - 6x replication: Data replicated across 6 nodes for durability
################################################################################

# ==============================================================================
# 1. RDS Aurora Cluster (Database Cluster Group)
# ==============================================================================
# Aurora uses a cluster model:
# - Cluster: Contains one primary instance and optional read replicas
# - Writer: Primary instance (accepts reads/writes)
# - Readers: Read replicas (accept reads only)
#
# This allows us to scale reads without scaling the write capacity.

resource "aws_rds_cluster" "main" {
  cluster_identifier     = "${var.project_name}-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_version         = var.db_engine_version
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  # Backup and restore configuration
  backup_retention_period      = var.db_backup_retention_period
  preferred_backup_window      = var.db_backup_window
  preferred_maintenance_window = var.db_maintenance_window

  # Performance and availability
  enabled_cloudwatch_logs_exports = ["postgresql"]
  deletion_protection             = true  # Protected from accidental deletion
  storage_encrypted               = true  # Encrypt data at rest
  skip_final_snapshot             = false # Create snapshot on deletion
  final_snapshot_identifier       = "${var.project_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Single AZ configuration (cost optimization)
  availability_zones = [var.availability_zones[0]] # Use only first AZ

  tags = {
    Name = "${var.project_name}-aurora-cluster"
  }

  # Ignore changes that would force cluster replacement
  lifecycle {
    ignore_changes = [
      engine_version,             # AWS auto-upgrades minor versions
      availability_zones,         # Can't change AZs on existing cluster
      master_username,            # Can't change username on existing cluster
      final_snapshot_identifier,  # Timestamp will change, ignore it
    ]
  }

  depends_on = [aws_db_subnet_group.main, aws_security_group.database]
}

# ==============================================================================
# 2. Aurora Single Instance (Writer Node)
# ==============================================================================
# Single instance handles both reads and writes
# Cost-optimized for development/staging environments

resource "aws_rds_cluster_instance" "primary" {
  cluster_identifier  = aws_rds_cluster.main.id
  identifier          = "${var.project_name}-aurora-primary"
  instance_class      = var.db_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = false # Private subnet - no internet access

  # Monitoring and metrics
  monitoring_interval          = 60 # Monitor every 60 seconds
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled = true

  # When to perform maintenance
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-aurora-primary"
    Role = "writer-reader"
  }

  depends_on = [aws_rds_cluster.main]
}

# ==============================================================================
# REMOVED: Aurora Read Replica Instance
# ==============================================================================
# The replica has been removed to reduce costs and simplify the setup.
# All reads and writes now go through the single primary instance.

# ==============================================================================
# 3. DB Subnet Group
# ==============================================================================
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ==============================================================================
# 5. Security Group for Aurora Database
# ==============================================================================
# NOTE: The database security group is defined in security_groups.tf
# to keep all security groups in one place for easier management.

# ==============================================================================
# 6. IAM Role for RDS Monitoring
# ==============================================================================
# Aurora needs an IAM role to send enhanced monitoring metrics to CloudWatch.

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

# Attach AWS managed policy for RDS monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ==============================================================================
# Aurora Cluster Endpoints (Available After Cluster Creation)
# ==============================================================================
#
# Writer Endpoint: Use for all writes (INSERT, UPDATE, DELETE)
#   - Points to the primary instance
#   - Example: vending-system-aurora-cluster.cluster-abc123.me-south-1.rds.amazonaws.com
#
# Reader Endpoint: Use for reads only (SELECT queries)
#   - Load balances across all replicas
#   - Example: vending-system-aurora-cluster.cluster-ro-abc123.me-south-1.rds.amazonaws.com
#
# Instance Endpoints: Connect to specific instances
#   - Primary: vending-system-aurora-primary.c123.me-south-1.rds.amazonaws.com
#   - Replica: vending-system-aurora-replica.c123.me-south-1.rds.amazonaws.com
#
# Connection string example:
#   postgresql://master:password@cluster-endpoint:5432/vendingdb
#
# For Rails:
#   DATABASE_URL=postgresql://master:password@endpoint:5432/vendingdb

# ==============================================================================
# Updated Cost Breakdown
# ==============================================================================
#
# Aurora Single Instance (db.t3.small): ~$60/month
# I/O (estimate 1M requests):           ~$1/month
# Storage (auto-scaling):               ~$0.10/GB/month
# 
# Total: ~$61/month
# Savings: ~$59/month compared to primary + replica setup
#
# Trade-offs:
# ✓ Reduced cost by ~50%
# ✓ Simpler architecture
# ✗ No automatic failover to replica
# ✗ Single point of failure
# ✗ Cannot offload read traffic
#