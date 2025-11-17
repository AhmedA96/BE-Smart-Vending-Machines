variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "me-south-1" # UAE (Middle East - Bahrain)
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
  default     = ["me-south-1a"] # Cost optimization: single AZ
}

# Database Configuration
variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "RDS instance class (Aurora)"
  type        = string
  default     = "db.t3.small" # Aurora requires at least t3.small
}

variable "db_allocated_storage" {
  description = "Allocated storage for database in GB (Aurora auto-scales)"
  type        = number
  default     = 20 # Aurora minimum, auto-scales as needed
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

variable "db_backup_retention_period" {
  description = "Database backup retention in days"
  type        = number
  default     = 7 # Keep 7 days of backups
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for Aurora (automatic failover)"
  type        = bool
  default     = false # Single AZ for cost optimization
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
