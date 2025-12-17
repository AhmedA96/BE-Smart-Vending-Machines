#!/usr/bin/env bash
# Helper script used by config/deploy.production.yml to fetch app host IPs
# Returns a space-separated list of private IPs for running app servers.
set -euo pipefail

APP_NAME_TAG="${APP_NAME_TAG:-vending-system-app-server}"
ENV_TAG="${ENV_TAG:-production}"

fetch_ips_from_instance_ids() {
  local ids="$1"
  aws ec2 describe-instances \
    --instance-ids $ids \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text 2>/dev/null | tr '\t' ' '
}

# First try by tags (most reliable across rolling ASG names)
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${APP_NAME_TAG}" \
            "Name=tag:Environment,Values=${ENV_TAG}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text 2>/dev/null | tr '\t' ' ')

if [[ -z "${INSTANCE_IDS// }" || "${INSTANCE_IDS}" == "None" ]]; then
  # Fallback: pick the newest ASG starting with "app-" and grab its healthy instances
  ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
    --query "reverse(sort_by(AutoScalingGroups[?starts_with(AutoScalingGroupName, \`app-\`)], &CreatedTime))[0].AutoScalingGroupName" \
    --output text 2>/dev/null || true)

  if [[ -n "${ASG_NAME// }" && "${ASG_NAME}" != "None" ]]; then
    INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "${ASG_NAME}" \
      --query 'AutoScalingGroups[].Instances[?LifecycleState==`InService` && HealthStatus==`Healthy`].InstanceId' \
      --output text 2>/dev/null | tr '\t' ' ')
  fi
fi

if [[ -z "${INSTANCE_IDS// }" || "${INSTANCE_IDS}" == "None" ]]; then
  echo "No running app instances found" >&2
  exit 1
fi

fetch_ips_from_instance_ids "${INSTANCE_IDS}"
