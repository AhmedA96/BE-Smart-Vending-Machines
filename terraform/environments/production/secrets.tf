# AWS Secrets Manager Configuration
# Manages sensitive data: DB credentials, API keys, third-party secrets
# Encrypted with KMS for additional security

# ============================================
# KMS Key for Secrets Encryption
# ============================================

resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets in ${var.project_name}-${var.environment}"
  deletion_window_in_days = 10   # Allow recovery if accidentally deleted
  enable_key_rotation     = true # Rotate key automatically yearly

  tags = {
    Name        = "${var.project_name}-secrets-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ============================================
# Database Credentials Secret
# ============================================

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/${var.environment}/db/credentials"
  description             = "Aurora PostgreSQL master credentials for ${var.project_name}"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7 # Allow recovery if accidentally deleted

  tags = {
    Name        = "${var.project_name}-db-credentials"
    Environment = var.environment
    Component   = "database"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_rds_cluster.main.endpoint
    port     = 5432
    dbname   = var.db_name
  })
}

# ============================================
# Redis Credentials Secret
# ============================================

resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.project_name}/${var.environment}/redis/credentials"
  description             = "Redis ElastiCache credentials for ${var.project_name}"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-redis-credentials"
    Environment = var.environment
    Component   = "cache"
  }
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({
    host = aws_elasticache_replication_group.redis.primary_endpoint_address
    port = aws_elasticache_replication_group.redis.port
  })
}

# ============================================
# Application Secrets Container
# ============================================

resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}/${var.environment}/app/secrets"
  description             = "Application secrets: API keys, third-party credentials, etc."
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-app-secrets"
    Environment = var.environment
    Component   = "application"
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    rails_master_key      = var.rails_master_key
    rails_secret_key_base = var.rails_secret_key_base
    jwt_secret            = var.jwt_secret
    api_keys = {
      supplier_api_key    = var.supplier_api_key
      supplier_api_secret = var.supplier_api_secret
    }
    external_services = {
      payment_provider_key = var.payment_provider_key
      sms_provider_key     = var.sms_provider_key
    }
  })
}

# ============================================
# Secret Rotation Lambda (Optional Future Enhancement)
# ============================================

# This sets up the infrastructure for automatic password rotation
# Lambda function implementation is a separate step
# Currently disabled - uncomment rotation_rules when Lambda is ready

# resource "aws_secretsmanager_secret_rotation" "db_credentials_rotation" {
#   secret_id           = aws_secretsmanager_secret.db_credentials.id
#   rotation_enabled    = false
#
#   rotation_rules {
#     automatically_after_days = 30
#   }
#
#   rotation_lambda_arn = aws_lambda_function.db_rotation.arn
# }

# ============================================
# IAM Role for EC2 to Access Secrets
# ============================================

resource "aws_iam_role" "app_secrets_access" {
  name = "${var.project_name}-${var.environment}-app-secrets-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-app-secrets-access"
    Environment = var.environment
  }
}

# Policy to read secrets from Secrets Manager
resource "aws_iam_role_policy" "app_secrets_read" {
  name = "${var.project_name}-${var.environment}-secrets-read"
  role = aws_iam_role.app_secrets_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.redis_credentials.arn,
          aws_secretsmanager_secret.app_secrets.arn
        ]
      },
      {
        Sid    = "DecryptSecrets"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}

# IAM instance profile for attaching to EC2 instances
resource "aws_iam_instance_profile" "app_secrets_profile" {
  name = "${var.project_name}-${var.environment}-app-secrets-profile"
  role = aws_iam_role.app_secrets_access.id
}

# ============================================
# Attach instance profile to EC2 Launch Templates
# ============================================

# Note: When creating launch templates, attach the instance profile using:
# iam_instance_profile {
#   name = aws_iam_instance_profile.app_secrets_profile.name
# }
