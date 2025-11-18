################################################################################
# Application Load Balancer (ALB)
#
# ALB distributes incoming traffic across multiple app servers.
# Provides HTTP/HTTPS termination, health checks, and routing.
#
# Key features:
# - Layer 7 (Application layer) load balancing
# - Path-based routing capability (future)
# - SSL/TLS termination
# - Health checks with automatic removal of unhealthy targets
# - Sticky sessions (optional)
# - Request logging (future)
################################################################################

# ==============================================================================
# 1. Target Group (Targets for ALB to route to)
# ==============================================================================
# Target group defines where traffic is sent and health check configuration

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  port        = 8080 # Rails/app server port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  # Health Check Configuration
  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    enabled             = true
  }

  # Stickiness: Keep requests from same client to same server
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 24 hours
  }

  # Deregistration delay: Time to drain connections before killing instance
  deregistration_delay = 30 # seconds

  # Preserve client IP
  preserve_client_ip = true

  tags = {
    Name = "${var.project_name}-app-target-group"
  }

  depends_on = [aws_vpc.main]
}

# ==============================================================================
# 2. Application Load Balancer
# ==============================================================================
# The ALB sits in the public subnet and routes traffic to app servers

resource "aws_lb" "main" {
  name_prefix        = "vnd-"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb"
  }

  depends_on = [aws_security_group.alb, aws_subnet.public_a, aws_subnet.public_b]
}

# ==============================================================================
# 3. HTTP Listener (Port 80)
# ==============================================================================
# Redirects HTTP traffic to HTTPS

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# ==============================================================================
# 4. HTTPS Listener (Port 443)
# ==============================================================================
# Main listener that routes HTTPS traffic to app servers

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01" # Strong security policy
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${var.project_name}-https-listener"
  }

  depends_on = [aws_acm_certificate_validation.main]
}

# ==============================================================================
# 5. SSL/TLS Certificate (from ACM)
# ==============================================================================
# For now using self-signed certificate
# In production, use valid certificate from CA or use AWS Certificate Manager

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "main" {
  private_key_pem = tls_private_key.main.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "main" {
  private_key      = tls_private_key.main.private_key_pem
  certificate_body = tls_self_signed_cert.main.cert_pem

  tags = {
    Name = "${var.project_name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# 6. ACM Certificate Validation (for real certificates)
# ==============================================================================
# For self-signed, validation is automatic
# For real certificates, uncomment the DNS validation below

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  timeouts {
    create = "5m"
  }
}

# ==============================================================================
# 7. Listener Rule (Optional Path-Based Routing)
# ==============================================================================
# Example: Route /api/* to a different target group (future)
#
# resource "aws_lb_listener_rule" "api" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 100
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }

# ==============================================================================
# Load Balancer Architecture Notes
# ==============================================================================
#
# TRAFFIC FLOW:
# 1. Client makes request to domain (e.g., api.vending.example.com)
# 2. Cloudflare DNS resolves to ALB's public IP (via CNAME)
# 3. ALB receives request on :443 (HTTPS)
# 4. ALB terminates SSL/TLS
# 5. ALB checks health of target group
# 6. ALB selects healthy target (app server)
# 7. ALB forwards request to selected app server on :8080
# 8. App server responds
# 9. ALB encrypts response and sends back to client
#
# HEALTH CHECKS:
# - Every 30 seconds, ALB calls /health endpoint
# - If 2 consecutive checks fail, marks as unhealthy
# - If 3 consecutive checks pass, marks as healthy
# - Unhealthy targets are removed from rotation
# - Auto Scaling detects this and launches replacement
#
# CERTIFICATE MANAGEMENT:
# Current: Self-signed certificate (for demo/testing)
# Production: Use AWS Certificate Manager with valid certificate
#   - Free for domain validation
#   - Auto-renewal
#   - Multiple domain support
#
# For production certificate setup:
# 1. Request certificate from ACM for your domain
# 2. Validate DNS ownership
# 3. Update certificate_arn in listener
# 4. Remove tls_private_key and tls_self_signed_cert resources
#
# STICKY SESSIONS:
# - Enabled (lb_cookie)
# - Keeps requests from same client to same server
# - Useful for session state (cookies)
# - Duration: 24 hours
# - Disable if using distributed session store (Redis)
#
# CROSS-ZONE LOAD BALANCING:
# - Enabled
# - Distributes traffic evenly across all targets
# - Small additional data transfer cost
# - Worth it for even distribution
#
# DEREGISTRATION DELAY (Connection Draining):
# - 30 seconds
# - When instance is marked for termination:
#   - No new requests sent to it
#   - Existing requests complete (up to 30 seconds)
#   - Then instance is terminated
# - Prevents request failures during deployments
#
# ==============================================================================
# Health Check Configuration Details
# ==============================================================================
#
# Path: /health
# Configure this endpoint in your Rails app:
#
# # config/routes.rb
# get '/health', to: 'health#check'
#
# # app/controllers/health_controller.rb
# class HealthController < ApplicationController
#   skip_before_action :authenticate_user!, if: :health_check?
#
#   def check
#     # Simple health check - if we respond, we're healthy
#     render json: { status: 'ok' }, status: :ok
#   end
#
#   private
#
#   def health_check?
#     request.path == '/health'
#   end
# end
#
# Health check should:
# - Return quickly (<5 seconds)
# - Verify basic dependencies (database connection)
# - Not perform heavy computation
# - Return 200 OK if healthy
# - Return 5xx if unhealthy
#
# ==============================================================================
# Monitoring & Debugging
# ==============================================================================
#
# CloudWatch Metrics (automatically collected):
# - ActiveConnectionCount: Concurrent connections
# - ClientTLSNegotiationErrorCount: SSL/TLS errors
# - HealthyHostCount: Healthy targets
# - UnHealthyHostCount: Unhealthy targets
# - HTTPCode_Target_2XX_Count: Successful responses
# - HTTPCode_Target_4XX_Count: Client errors
# - HTTPCode_Target_5XX_Count: Server errors
# - TargetResponseTime: Response latency
# - RequestCount: Total requests
#
# Enable Access Logs for detailed request logging (production):
# - Logs to S3 bucket
# - Contains source IP, request details, response codes
# - Useful for debugging and compliance
#
# ==============================================================================
# Future Enhancements
# ==============================================================================
#
# 1. WebSocket Support
#    - For real-time features (notifications, chat)
#    - Change protocol to HTTP (with sticky sessions)
#    - Or use NLB for Layer 4 load balancing
#
# 2. WAF (Web Application Firewall)
#    - Protect against:
#      - SQL injection
#      - Cross-site scripting
#      - DDoS attacks
#    - Add to ALB
#
# 3. Request Logging
#    - Send logs to S3
#    - Analyze with Athena or ELK
#    - Track user agents, geographic origin, etc.
#
# 4. Hosted Zone Certificate
#    - Use Route53 + ACM for full AWS integration
#    - Automatic renewal
#    - Easy validation
#
# 5. Canary Deployments
#    - Route small percentage to new version
#    - Verify before full rollout
#    - Automatic rollback on errors
#

