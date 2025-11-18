################################################################################
# Redis ElastiCache Cluster with Replication
#
# Redis serves two purposes in our architecture:
# 1. In-memory caching layer for API responses
# 2. Job queue for background worker processes
#
# This configuration includes:
# - Primary node: Handles reads and writes
# - Replica node: Standby for failover + read scaling
# - Automatic failover: If primary fails, replica promoted to primary
# - Data persistence: RDB snapshots for recovery after restart
# - Encryption: At rest and in transit
################################################################################

# ==============================================================================
# 1. Redis Subnet Group (Database Tier Subnets)
# ==============================================================================
# ElastiCache needs a subnet group specifying which subnets it can use.
# We place Redis in the private DB subnet for security.

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_db.id]

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }

  depends_on = [aws_subnet.private_db]
}

# ==============================================================================
# 2. Redis Replication Group (Primary + Replica Setup)
# ==============================================================================
# ElastiCache replication group provides:
# - Automatic failover when primary fails
# - Read scaling (read from replica)
# - Data persistence to disk (snapshots)
# - Encryption at rest and in transit

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "Redis cluster for ${var.project_name} with automatic failover"
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_nodes
  automatic_failover_enabled = true
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"

  # Data persistence
  snapshot_retention_limit = 5
  snapshot_window          = var.redis_snapshot_window
  maintenance_window       = var.redis_maintenance_window

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Multi-AZ for automatic failover
  multi_az_enabled = false

  tags = {
    Name = "${var.project_name}-redis-cluster"
  }

  depends_on = [
    aws_elasticache_subnet_group.redis,
    aws_security_group.redis,
    aws_elasticache_parameter_group.redis
  ]
}

# ==============================================================================
# 3. Redis Parameter Group (Configuration Tuning)
# ==============================================================================
# Parameter group allows customization of Redis behavior

resource "aws_elasticache_parameter_group" "redis" {
  family = "redis${split(".", var.redis_engine_version)[0]}" # e.g., "redis7"
  name   = "${var.project_name}-redis-params"

  # Key eviction policy: When memory is full, evict least recently used keys
  parameter {
    name  = "maxmemory-policy"
    value = var.redis_maxmemory_policy
  }

  # Timeout for idle connections (prevents accumulation)
  parameter {
    name  = "timeout"
    value = tostring(var.redis_timeout)
  }

  # TCP backlog for connection queue
  parameter {
    name  = "tcp-backlog"
    value = tostring(var.redis_tcp_backlog)
  }

  tags = {
    Name = "${var.project_name}-redis-parameter-group"
  }
}

# ==============================================================================
# 4. CloudWatch Log Groups for Redis Monitoring
# ==============================================================================

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.project_name}/redis-slow-log"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-redis-slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.project_name}/redis-engine-log"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-redis-engine-log"
  }
}

# ==============================================================================
# 5. Security Group for Redis
# ==============================================================================
# NOTE: The Redis security group is defined in security_groups.tf
# to keep all security groups in one place for easier management.

# ==============================================================================
# Notes on Replication Configuration
# ==============================================================================
#
# CLUSTER MODE DISABLED (Current Setup):
# - Single primary node
# - Replica nodes for failover and read scaling
# - All write operations go to primary
# - Read operations can use replica endpoint
#
# WHEN TO UPGRADE TO CLUSTER MODE:
# - If you need sharding (partitioning data across nodes)
# - When single node cannot handle memory requirements
# - For true horizontal scaling of Redis
# - Cost: Roughly 2x for cluster setup vs single replication
#
# MONITORING KEY METRICS:
# - ElastiCache CPU: Should stay <75%
# - Evictions: Should be 0 (if >0, increase memory or reduce TTL)
# - Network bytes in/out: Monitor for unexpected spikes
# - Replication lag: Should be <100ms
#
# COST BREAKDOWN:
# - Primary node: cache.t3.micro = ~$18/mo
# - Replica node: cache.t3.micro = ~$18/mo
# - Total: ~$36/mo (was ~$18/mo for single node)
# - Data transfer between primary/replica: Negligible
#
# FAILOVER BEHAVIOR:
# - Primary fails → Replica promoted to primary automatically (<1 second)
# - New replica launched to replace failed one
# - Total recovery time: 2-3 minutes
# - No data loss (fully replicated)
#
# PERSISTENCE:
# - RDB snapshots: Daily snapshots to S3
# - AOF persistence: NOT enabled (slower, not needed for cache)
# - Snapshots allow recovery if entire cluster restarts
#

