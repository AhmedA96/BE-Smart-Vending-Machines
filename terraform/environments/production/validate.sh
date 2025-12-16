#!/bin/bash
#
# Terraform Production Validation Script
# Run this before deploying to catch common issues
#

set -e

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                            ║"
echo "║              TERRAFORM PRODUCTION VALIDATION                               ║"
echo "║                                                                            ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((ERRORS++))
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((WARNINGS++))
}

# Check 1: Terraform installed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking Terraform installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v terraform &> /dev/null; then
  VERSION=$(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)
  pass "Terraform installed (v$VERSION)"
else
  fail "Terraform not installed"
fi

# Check 2: AWS CLI configured
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking AWS credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if aws sts get-caller-identity &> /dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region)
  pass "AWS credentials configured (Account: $ACCOUNT, Region: $REGION)"
else
  fail "AWS credentials not configured. Run: aws configure"
fi

# Check 3: Correct directory
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Checking working directory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $(pwd) == */terraform/environments/production ]]; then
  pass "In correct directory: $(pwd)"
else
  fail "Not in production directory. Expected: terraform/environments/production"
fi

# Check 4: Required files exist
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking required files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REQUIRED_FILES=(
  "main.tf"
  "variables.tf"
  "outputs.tf"
  "vpc.tf"
  "database.tf"
  "redis.tf"
  "load_balancer.tf"
  "autoscaling_app.tf"
  "autoscaling_worker.tf"
  "security_groups.tf"
  "secrets.tf"
  "storage.tf"
  "cloudwatch.tf"
  "backend.tf"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    pass "$file exists"
  else
    fail "$file missing"
  fi
done

# Check 5: terraform.tfvars exists
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking terraform.tfvars"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "terraform.tfvars" ]; then
  pass "terraform.tfvars exists"
  
  # Check for required variables
  REQUIRED_VARS=(
    "aws_region"
    "project_name"
    "db_password"
    "rails_master_key"
    "rails_secret_key_base"
    "jwt_secret"
  )
  
  for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^$var\s*=" terraform.tfvars 2>/dev/null; then
      # Check if it's not a default value
      if grep "^$var\s*=" terraform.tfvars | grep -q "CHANGE"; then
        warn "$var is set but appears to be default value"
      else
        pass "$var is configured"
      fi
    else
      fail "$var not found in terraform.tfvars"
    fi
  done
else
  fail "terraform.tfvars not found. Run: cp terraform.tfvars.example terraform.tfvars"
fi

# Check 6: Terraform format
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Checking Terraform format"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if terraform fmt -check -recursive &> /dev/null; then
  pass "All files properly formatted"
else
  warn "Some files need formatting. Run: terraform fmt -recursive"
fi

# Check 7: Terraform validate
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Validating Terraform configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -d ".terraform" ]; then
  warn "Terraform not initialized. Run: terraform init"
else
  if terraform validate &> /dev/null; then
    pass "Configuration is valid"
  else
    fail "Configuration validation failed. Run: terraform validate"
  fi
fi

# Check 8: Security check
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Checking security"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check gitignore
if grep -q "terraform.tfvars" ../../.gitignore 2>/dev/null; then
  pass "terraform.tfvars is gitignored"
else
  fail "terraform.tfvars NOT in .gitignore - secrets may be committed!"
fi

# Check if tfvars is tracked by git
if git ls-files terraform.tfvars &> /dev/null; then
  fail "terraform.tfvars is tracked by git! Remove it: git rm --cached terraform.tfvars"
else
  pass "terraform.tfvars not tracked by git"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  echo ""
  echo "You can proceed with deployment:"
  echo "  terraform init"
  echo "  terraform plan -out=tfplan"
  echo "  terraform apply tfplan"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  echo ""
  echo "Review warnings above. You may proceed with caution."
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s) found${NC}"
  if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  fi
  echo ""
  echo "Fix errors above before deploying."
  exit 1
fi
