################################################################################
# CloudWatch Monitoring & Alarms
#
# This configuration sets up monitoring for critical infrastructure metrics
# and creates alarms to alert on issues before they impact users.
#
# Alarms created:
# 1. Application Servers (CPU, network, health)
# 2. Database (CPU, connections, query performance)
# 3. Redis (memory, evictions, replication lag)
# 4. Load Balancer (HTTP errors, target health)
# 5. Infrastructure (NAT gateway, VPC)
################################################################################

# ==============================================================================
# 1. SNS Topic for Alarm Notifications
# ==============================================================================
# All alarms will send notifications to this SNS topic
# You can subscribe to this topic via email, SMS, Slack, etc.

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-${var.environment}-alerts"
  kms_master_key_id = aws_kms_key.secrets.id # Encrypt notifications

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# ==============================================================================
# 2. Application Server Alarms
# ==============================================================================

# CPU Utilization - Indicates if servers are overloaded
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.project_name}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when app server CPU exceeds 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-app-cpu-high"
    Environment = var.environment
  }
}

# Network In - Monitor incoming traffic
resource "aws_cloudwatch_metric_alarm" "app_network_in_high" {
  alarm_name          = "${var.project_name}-app-network-in-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "104857600" # 100 MB in bytes
  alarm_description   = "Alert when app server inbound traffic exceeds 100 MB/5min"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# Disk Space - Monitor if we're running out of storage
resource "aws_cloudwatch_metric_alarm" "app_status_check_failed" {
  alarm_name          = "${var.project_name}-app-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60" # 1 minute
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when app server status check fails"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# ==============================================================================
# 3. Worker Server Alarms
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "worker_cpu_high" {
  alarm_name          = "${var.project_name}-worker-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when worker CPU exceeds 75% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker.name
  }
}

# ==============================================================================
# 4. Aurora Database Alarms
# ==============================================================================

# CPU Utilization
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${var.project_name}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when Aurora CPU exceeds 75% (potential slow queries)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# Database Connections - Connection pool exhaustion
resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  alarm_name          = "${var.project_name}-aurora-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80" # Adjust based on max_connections
  alarm_description   = "Alert when database connections exceed 80 (possible connection leak)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# Read Latency - Query performance
resource "aws_cloudwatch_metric_alarm" "aurora_read_latency_high" {
  alarm_name          = "${var.project_name}-aurora-read-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10" # milliseconds
  alarm_description   = "Alert when read queries take >10ms (possible slow queries)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# Write Latency
resource "aws_cloudwatch_metric_alarm" "aurora_write_latency_high" {
  alarm_name          = "${var.project_name}-aurora-write-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "20" # milliseconds
  alarm_description   = "Alert when write queries take >20ms (replication lag or slow inserts)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# Replica Lag - Replication health
resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  alarm_name          = "${var.project_name}-aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AuroraBinlogReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100" # milliseconds
  alarm_description   = "Alert when replica is >100ms behind primary (replication lag)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# Storage Space
resource "aws_cloudwatch_metric_alarm" "aurora_storage_space_low" {
  alarm_name          = "${var.project_name}-aurora-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648" # 2 GB in bytes
  alarm_description   = "Alert when Aurora storage is below 2 GB (may run out)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}

# ==============================================================================
# 5. Redis ElastiCache Alarms
# ==============================================================================

# Memory Usage - Cache eviction detection
resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  alarm_name          = "${var.project_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Alert when Redis memory usage exceeds 90% (eviction risk)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
}

# Evictions - Cache items being evicted
resource "aws_cloudwatch_metric_alarm" "redis_evictions_high" {
  alarm_name          = "${var.project_name}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100" # evictions in 5 min
  alarm_description   = "Alert when Redis evicts >100 keys (not enough memory)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
}

# CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when Redis CPU exceeds 80% (possible bottleneck)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
}

# Replication Lag - Redis replication health
resource "aws_cloudwatch_metric_alarm" "redis_replication_lag" {
  alarm_name          = "${var.project_name}-redis-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "1" # seconds
  alarm_description   = "Alert when Redis replica is >1 second behind primary"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
}

# Swap Usage - Indicates memory pressure
resource "aws_cloudwatch_metric_alarm" "redis_swap_usage" {
  alarm_name          = "${var.project_name}-redis-swap-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SwapUsage"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"
  threshold           = "52428800" # 50 MB (should never happen)
  alarm_description   = "Alert when Redis uses swap (critical: resize or upgrade)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
}

# ==============================================================================
# 6. Application Load Balancer Alarms
# ==============================================================================

# HTTP 5xx Errors - Application errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10" # errors in 5 min
  alarm_description   = "Alert when ALB sees >10 HTTP 500 errors (application issues)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# HTTP 4xx Errors - Client errors
resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  alarm_name          = "${var.project_name}-alb-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100" # errors in 5 min
  alarm_description   = "Alert when ALB sees >100 HTTP 4xx errors (possible attack or bad requests)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# Unhealthy Host Count - Target health
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1" # any unhealthy host
  alarm_description   = "Alert when ALB has unhealthy targets"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}

# Request Count - Traffic volume
resource "aws_cloudwatch_metric_alarm" "alb_request_count_low" {
  alarm_name          = "${var.project_name}-alb-no-traffic"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1" # at least 1 request in 5 min
  alarm_description   = "Alert when ALB receives no traffic for 15 minutes (possible DNS/network issue)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# ==============================================================================
# 7. NAT Gateway Alarms
# ==============================================================================

# NAT Gateway CPU
resource "aws_cloudwatch_metric_alarm" "nat_gateway_cpu" {
  alarm_name          = "${var.project_name}-nat-gateway-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/NatGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when NAT Gateway CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.nat.id
  }
}

# NAT Gateway Packet Drop
resource "aws_cloudwatch_metric_alarm" "nat_gateway_packet_drop" {
  alarm_name          = "${var.project_name}-nat-gateway-packet-drop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PacketsOutDropCount"
  namespace           = "AWS/NatGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Alert when NAT Gateway drops >100 packets (port exhaustion)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.nat.id
  }
}

# ==============================================================================
# 8. Dashboard
# ==============================================================================
# CloudWatch dashboard for visual monitoring

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "App CPU" }],
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "Aurora CPU" }],
            ["AWS/ElastiCache", "EngineCPUUtilization", { stat = "Average", label = "Redis CPU" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", { stat = "Sum" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", { stat = "Average" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Health"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }],
            ["AWS/RDS", "ReadLatency", { stat = "Average" }],
            ["AWS/RDS", "WriteLatency", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Database Performance"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", { stat = "Average" }],
            ["AWS/ElastiCache", "Evictions", { stat = "Sum" }],
            ["AWS/ElastiCache", "ReplicationLag", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Redis Health"
        }
      }
    ]
  })
}

# ==============================================================================
# Notes on Alarm Thresholds
# ==============================================================================
#
# TUNING ALARMS:
# - Thresholds are conservative starting points
# - Monitor for 1-2 weeks, then adjust based on normal baselines
# - Consider time-of-day patterns (off-peak vs peak traffic)
# - Set escalation: Warning (80%) → Critical (90%)
#
# COMMON ISSUES & ALARMS:
# - High CPU: Slow queries, unoptimized code, or traffic spike
# - High memory (Redis): Too much cache or eviction policy too loose
# - High latency: Slow queries, network congestion, or hot partitions
# - 5xx errors: Application crashes, OOM kills, or unhandled exceptions
# - Replica lag: Slow primary or network issues
#
# ESCALATION STRATEGY:
# 1. Info alerts (threshold 60%) → Log only
# 2. Warning alerts (threshold 75%) → Notify team
# 3. Critical alerts (threshold 85%) → Page on-call
#
# SUBSCRIBE TO SNS:
# aws sns subscribe \
#   --topic-arn arn:aws:sns:me-south-1:123456789:vending-system-production-alerts \
#   --protocol email \
#   --notification-endpoint your-email@example.com

