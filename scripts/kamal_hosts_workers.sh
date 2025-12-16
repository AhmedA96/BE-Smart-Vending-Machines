#!/usr/bin/env bash
# Helper script used by config/deploy.production.yml to fetch worker host IPs
# Returns a space-separated list of private IPs for running worker servers.
set -euo pipefail

WORKER_NAME_TAG="${WORKER_NAME_TAG:-vending-system-worker-server}"
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
  --filters "Name=tag:Name,Values=${WORKER_NAME_TAG}" \
            "Name=tag:Environment,Values=${ENV_TAG}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text 2>/dev/null | tr '\t' ' ')

if [[ -z "${INSTANCE_IDS// }" || "${INSTANCE_IDS}" == "None" ]]; then
  # Fallback: pick the newest ASG starting with "worker-" and grab its healthy instances
  ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
    --query "reverse(sort_by(AutoScalingGroups[?starts_with(AutoScalingGroupName, \`worker-\`)], &CreatedTime))[0].AutoScalingGroupName" \
    --output text 2>/dev/null || true)

  if [[ -n "${ASG_NAME// }" && "${ASG_NAME}" != "None" ]]; then
    INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "${ASG_NAME}" \
      --query 'AutoScalingGroups[].Instances[?LifecycleState==`InService` && HealthStatus==`Healthy`].InstanceId' \
      --output text 2>/dev/null | tr '\t' ' ')
  fi
fi

if [[ -z "${INSTANCE_IDS// }" || "${INSTANCE_IDS}" == "None" ]]; then
  echo "No running worker instances found" >&2
  exit 1
fi

fetch_ips_from_instance_ids "${INSTANCE_IDS}"
