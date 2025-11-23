# Deployment Quick Reference

## One-Command Deployment

```bash
AWS_PROFILE=vndg ./scripts/generate-kamal-config.sh && kamal deploy -d production
```

## Step-by-Step

### 1. Sync IPs

```bash
AWS_PROFILE=vndg ./scripts/generate-kamal-config.sh
```

- Fetches current instances from AWS
- Updates `config/deploy.production.yml`
- Shows which servers will be deployed to

### 2. Deploy

```bash
kamal deploy -d production
```

- Builds Docker image
- Pushes to ghcr.io
- Installs Docker on instances
- Pulls and starts container

### 3. Monitor Health

```bash
watch -n 5 'AWS_PROFILE=vndg aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:me-central-1:471112976287:targetgroup/app-20251119183937304400000001/a9cbeb29325324da" \
  --region me-central-1 \
  --output table'
```

- Wait for all instances to show "healthy"
- Typically 2-3 minutes after Kamal finishes

## Verification

```bash
# Check health status
AWS_PROFILE=vndg aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:me-central-1:471112976287:targetgroup/app-20251119183937304400000001/a9cbeb29325324da" \
  --region me-central-1

# View logs
kamal logs -d production -f

# SSH to instance
ssh -o ProxyCommand="ssh -W %h:%p ubuntu@40.172.242.129" ubuntu@10.0.2.27

# Test health endpoint
curl https://api.vndg.me/up
```

## Important Configuration

| Setting               | Value         | Purpose                                       |
| --------------------- | ------------- | --------------------------------------------- |
| Grace Period          | 600s (10 min) | Time for Kamal to finish before health checks |
| Health Check Interval | 30s           | How often ALB checks if app is running        |
| Healthy Threshold     | 2 checks      | Consecutive passes needed to mark healthy     |
| Unhealthy Threshold   | 3 failures    | Consecutive failures before termination       |
| Min Instances         | 2             | Minimum running at all times                  |
| Max Instances         | 4             | Maximum when scaled up                        |

## Troubleshooting

### IPs changed?

→ Run sync script again: `./scripts/generate-kamal-config.sh`

### Instances still restarting?

→ Check grace period: `aws autoscaling describe-auto-scaling-groups --region me-central-1`
→ Should show `"HealthCheckGracePeriod": 600`

### Health checks failing?

→ View logs: `kamal logs -d production -f`
→ Check app endpoint: `curl http://10.0.2.27:8080/up` (via bastion)

### Can't SSH via bastion?

→ Add your IP to bastion security group:

```bash
AWS_PROFILE=vndg aws ec2 authorize-security-group-ingress \
  --group-id sg-0557a6523c586f6ae \
  --region me-central-1 \
  --protocol tcp \
  --port 22 \
  --cidr $(curl https://checkip.amazonaws.com)/32
```

## Expected Deployment Timeline

```
0:00 - kamal deploy starts
2:00 - Image built and pushed
3:00 - Connecting to instances
3:30 - Docker install on instance 1
4:10 - Docker install on instance 2
4:15 - Image pull on instance 1
5:00 - Image pull on instance 2, container starts
5:30 - Container initialized
6:00 - GRACE PERIOD ENDS → Health checks start
6:05 - First health check passes
6:10 - 2 consecutive checks pass → Instance marked HEALTHY
6:15 - All instances HEALTHY → Deployment successful ✅
```

## Files Modified

- `terraform/environments/production/autoscaling_app.tf` - Grace period increased
- `config/deploy.production.yml` - Server IPs synced
- `scripts/generate-kamal-config.sh` - NEW: Auto-sync script

## Documentation

- `PRODUCTION_DEPLOYMENT_GUIDE.md` - Comprehensive guide
- `DYNAMIC_INVENTORY_GUIDE.md` - IP sync automation
- `INSTANCE_RESTART_DIAGNOSIS.md` - Understanding issues
