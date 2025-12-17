#!/bin/bash

# Wrapper script for production deployment
# Automatically fetches secrets from AWS before running kamal deploy

set -e

DEPLOY_CMD="kamal deploy -d production"

echo "=========================================="
echo "Production Deployment"
echo "=========================================="
echo ""

# Only fetch secrets for production deployments
if [[ "$*" == *"-d production"* ]] || [[ "$*" == *"production"* ]]; then
  echo "Step 1: Fetching secrets from AWS Secrets Manager..."
  cd "$(dirname "$0")/.."
  ./scripts/populate-production-secrets.rb || exit 1
  echo ""
fi

echo "Step 2: Starting Kamal deployment..."
$DEPLOY_CMD "$@"
