variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "me-central-1" # UAE (Middle East - UAE)
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "vending-system"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for deployment"
  type        = list(string)
  default     = ["me-central-1a", "me-central-1b"] # 2 AZs required for ALB/RDS (resources stay in AZ-a)
}

# Database Configuration
variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.8" # Aurora PostgreSQL compatible version
}

variable "db_instance_class" {
  description = "RDS instance class (Aurora)"
  type        = string
  default     = "db.t3.small" # Aurora requires at least t3.small
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "vendingdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Initial database storage in GB"
  type        = number
  default     = 50
}

variable "db_backup_retention_period" {
  description = "Database backup retention in days"
  type        = number
  default     = 7 # Keep 7 days of backups
}

# Redis Configuration
variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro" # Cost optimization: smallest instance
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes (primary + replicas)"
  type        = number
  default     = 2 # Primary + 1 replica for automatic failover and data protection
}

# Load Balancer Configuration
variable "app_instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro" # Cost optimization: smallest viable instance
}

variable "app_desired_capacity" {
  description = "Desired number of application instances"
  type        = number
  default     = 2 # 2 app servers for redundancy
}

variable "app_min_capacity" {
  description = "Minimum number of application instances"
  type        = number
  default     = 2 # Maintain 2 servers minimum
}

variable "app_max_capacity" {
  description = "Maximum number of application instances"
  type        = number
  default     = 4 # Allow scaling up to 4 under load
}

# Worker Configuration
variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.micro" # Cost optimization: smallest viable instance
}

variable "worker_desired_capacity" {
  description = "Desired number of worker instances"
  type        = number
  default     = 2 # 2 workers for redundancy and reliability
}

variable "worker_min_capacity" {
  description = "Minimum number of worker instances"
  type        = number
  default     = 2 # Keep 2 workers running for fault tolerance
}

variable "worker_max_capacity" {
  description = "Maximum number of worker instances"
  type        = number
  default     = 2 # Scale to 2 workers if queue gets large
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application (e.g., api.vending.example.com)"
  type        = string
}

# ============================================
# Secrets Manager Configuration
# ============================================

# Application Secrets
variable "rails_master_key" {
  description = "Rails master key for credentials"
  type        = string
  sensitive   = true
}

variable "rails_secret_key_base" {
  description = "Rails SECRET_KEY_BASE for session signing"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for API token signing"
  type        = string
  sensitive   = true
}

# Third-party API Keys
variable "supplier_api_key" {
  description = "API key for supplier integration"
  type        = string
  sensitive   = true
  default     = "" # Optional, set in tfvars if needed
}

variable "supplier_api_secret" {
  description = "API secret for supplier integration"
  type        = string
  sensitive   = true
  default     = "" # Optional, set in tfvars if needed
}

variable "payment_provider_key" {
  description = "Payment provider API key"
  type        = string
  sensitive   = true
  default     = "" # Optional, set in tfvars if needed
}

variable "sms_provider_key" {
  description = "SMS provider API key"
  type        = string
  sensitive   = true
  default     = "" # Optional, set in tfvars if needed
}

# ============================================
# EC2 Instance Configuration
# ============================================

variable "app_ebs_volume_size" {
  description = "EBS volume size for application servers (GB)"
  type        = number
  default     = 50
}

variable "app_ebs_volume_type" {
  description = "EBS volume type for application servers"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.app_ebs_volume_type)
    error_message = "EBS volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "worker_ebs_volume_size" {
  description = "EBS volume size for worker servers (GB)"
  type        = number
  default     = 50
}

variable "worker_ebs_volume_type" {
  description = "EBS volume type for worker servers"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.worker_ebs_volume_type)
    error_message = "EBS volume type must be one of: gp2, gp3, io1, io2."
  }
}

# ============================================
# AMI Configuration
# ============================================

variable "ami_owner" {
  description = "AWS account ID of AMI owner (Canonical for Ubuntu)"
  type        = string
  default     = "099720109477"
}

variable "ami_name_filter" {
  description = "AMI name filter pattern"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

# ============================================
# Health Check Configuration
# ============================================

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/up"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful checks to mark healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed checks to mark unhealthy"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP status codes to consider healthy"
  type        = string
  default     = "200-404"
}

# ============================================
# Auto Scaling Thresholds
# ============================================

variable "app_scale_up_cpu_threshold" {
  description = "CPU percentage to trigger scale up for app servers"
  type        = number
  default     = 70
}

variable "app_scale_down_cpu_threshold" {
  description = "CPU percentage to trigger scale down for app servers"
  type        = number
  default     = 30
}

variable "worker_scale_up_cpu_threshold" {
  description = "CPU percentage to trigger scale up for worker servers"
  type        = number
  default     = 60
}

variable "worker_scale_down_cpu_threshold" {
  description = "CPU percentage to trigger scale down for worker servers"
  type        = number
  default     = 20
}

# ============================================
# Backup and Maintenance Windows
# ============================================

variable "db_backup_window" {
  description = "Preferred backup window for database (UTC)"
  type        = string
  default     = "03:00-04:00" # 1-2 AM Gulf time
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window for database (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "redis_snapshot_window" {
  description = "Preferred snapshot window for Redis (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Preferred maintenance window for Redis (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

# ============================================
# Redis Configuration
# ============================================

variable "redis_maxmemory_policy" {
  description = "Redis eviction policy when max memory is reached"
  type        = string
  default     = "allkeys-lru"

  validation {
    condition = contains([
      "volatile-lru", "allkeys-lru", "volatile-lfu", "allkeys-lfu",
      "volatile-random", "allkeys-random", "volatile-ttl", "noeviction"
    ], var.redis_maxmemory_policy)
    error_message = "Invalid Redis maxmemory policy."
  }
}

variable "redis_timeout" {
  description = "Redis connection timeout in seconds"
  type        = number
  default     = 300
}

variable "redis_tcp_backlog" {
  description = "Redis TCP backlog size"
  type        = number
  default     = 511
}

# ============================================
# CloudWatch Logs Configuration
# ============================================

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

# ============================================
# S3 Lifecycle Configuration
# ============================================

variable "s3_backup_retention_days" {
  description = "Days to retain backups in S3"
  type        = number
  default     = 365
}

variable "s3_version_retention_days" {
  description = "Days to retain non-current object versions"
  type        = number
  default     = 90
}

variable "s3_incomplete_upload_cleanup_days" {
  description = "Days after which to abort incomplete multipart uploads"
  type        = number
  default     = 7
}

# ============================================
# Bastion Host Configuration
# ============================================

variable "bastion_admin_ips" {
  description = "List of IP addresses/CIDRs allowed to SSH to bastion"
  type        = list(string)
  default     = ["154.179.17.169/32"] # Your public IP
}
