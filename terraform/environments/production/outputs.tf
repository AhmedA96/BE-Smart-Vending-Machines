output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_a_id" {
  description = "Public subnet A ID (AZ-a, for ALB)"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "Public subnet B ID (AZ-b, for ALB)"
  value       = aws_subnet.public_b.id
}

output "private_app_subnet_1_id" {
  description = "Private app subnet 1 ID (for app servers)"
  value       = aws_subnet.private_app_1.id
}

output "private_app_subnet_2_id" {
  description = "Private app subnet 2 ID (for app servers)"
  value       = aws_subnet.private_app_2.id
}

output "private_db_subnet_a_id" {
  description = "Private database subnet A ID (AZ-a)"
  value       = aws_subnet.private_db_a.id
}

output "private_db_subnet_b_id" {
  description = "Private database subnet B ID (AZ-b)"
  value       = aws_subnet.private_db_b.id
}

output "load_balancer_dns" {
  description = "Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "Load Balancer ARN"
  value       = aws_lb.main.arn
}

output "app_target_group_arn" {
  description = "Application target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "rds_endpoint" {
  description = "Aurora cluster writer endpoint (for writes)"
  value       = aws_rds_cluster.main.endpoint
  sensitive   = true
}

output "rds_reader_endpoint" {
  description = "Aurora cluster reader endpoint (for read-only queries)"
  value       = aws_rds_cluster.main.reader_endpoint
  sensitive   = true
}

output "rds_cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "rds_primary_instance_id" {
  description = "Aurora primary instance identifier"
  value       = aws_rds_cluster_instance.primary.identifier
}

output "rds_replica_instance_id" {
  description = "Aurora read replica instance identifier"
  value       = aws_rds_cluster_instance.replica.identifier
}

output "redis_endpoint" {
  description = "Redis primary node endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive   = true
}

output "app_asg_name" {
  description = "Application Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "worker_asg_name" {
  description = "Worker Auto Scaling Group name"
  value       = aws_autoscaling_group.worker.name
}

output "security_group_alb_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "security_group_app_id" {
  description = "Security group ID for application servers"
  value       = aws_security_group.app.id
}

output "security_group_redis_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "security_group_database_id" {
  description = "Security group ID for database"
  value       = aws_security_group.database.id
}

output "s3_backups_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.app_backups.id
}

output "s3_media_bucket_name" {
  description = "S3 bucket name for media storage"
  value       = aws_s3_bucket.app_media.id
}

# ============================================
# Secrets Manager Outputs
# ============================================

output "kms_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = aws_kms_key.secrets.id
}

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "db_credentials_secret_arn" {
  description = "ARN of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "redis_credentials_secret_arn" {
  description = "ARN of Redis credentials secret"
  value       = aws_secretsmanager_secret.redis_credentials.arn
}

output "redis_credentials_secret_name" {
  description = "Name of Redis credentials secret"
  value       = aws_secretsmanager_secret.redis_credentials.name
}

output "app_secrets_secret_arn" {
  description = "ARN of application secrets"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "app_secrets_secret_name" {
  description = "Name of application secrets"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "app_secrets_access_role_arn" {
  description = "ARN of IAM role for accessing secrets from EC2"
  value       = aws_iam_role.app_secrets_access.arn
}

output "app_secrets_instance_profile_name" {
  description = "Name of IAM instance profile for accessing secrets"
  value       = aws_iam_instance_profile.app_secrets_profile.name
}

