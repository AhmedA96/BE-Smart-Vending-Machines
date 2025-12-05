# Production Deployment Guide

## Quick Start

```bash
# Deploy to production (everything automated)
kamal deploy -d production
```

That's it! The pre-deploy hook automatically syncs instance IPs from AWS.

**Timeline:** ~8-12 minutes for first deploy, 6-8 minutes for subsequent deployments with cached layers.

---

## What Was Fixed

### 1. Instance Restart Cycle ✅

**Problem:** ASG was terminating instances before Kamal finished deploying (5 min grace period < 8 min deployment)

**Solution:** Increased ASG health check grace period to 10 minutes

- File: `terraform/environments/production/autoscaling_app.tf`
- Change: `health_check_grace_period = 300` → `600`

### 2. Dynamic IP Changes ✅

**Problem:** Instance IPs change constantly with ASG scaling

**Solution:** Pre-deploy hook automatically syncs IPs from AWS

- File: `.kamal/hooks/pre-deploy`
- Runs automatically before every `kamal deploy`
- Queries AWS for current instances and updates config

### 3. Large Docker Images ✅

**Problem:** Image was 1.5-2.0 GB (included terraform, cache, tests, etc.)

**Solution:** Optimized .dockerignore

- File: `.dockerignore`
- Excludes unnecessary files
- Reduced to 500-700 MB

### 4. Slow Push/Export ✅

**Problem:** Export and push took 8-10 minutes

**Solutions:**

- Dockerfile: Added BuildKit cache mounts (2-3 min savings on cached builds)
- Kamal config: Enabled registry caching
- Result: 4-6 min push (vs 8-10 min before)

---

## Deployment Steps

### 1. Before Deploying

```bash
# Ensure you're ready
docker ps                     # Docker running
git status                    # All changes committed
AWS_PROFILE=vndg aws sts get-caller-identity  # AWS access
```

### 2. Deploy

```bash
kamal deploy -d production
```

The deployment will:

1. Run pre-deploy hook: Sync instance IPs from AWS
2. Build Docker image locally (uses cache if Gemfile unchanged)
3. Push to ghcr.io
4. SSH to instances via bastion
5. Pull image and start container
6. Health checks pass

### 3. Monitor

```bash
# Watch logs during deploy
kamal logs -d production -f

# Or wait for health checks
watch -n 5 'aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:me-central-1:471112976287:targetgroup/app-20251119183937304400000001/a9cbeb29325324da" \
  --region me-central-1 \
  --output table'
```

### 4. Verify

```bash
# Test API
curl https://api.vndg.me/up

# Check app status
kamal app status -d production

# View recent logs
kamal logs -d production --lines 50
```

---

## Configuration

### Kamal Hook (.kamal/hooks/pre-deploy)

Automatically syncs instance IPs before each deployment:

- Only runs for production
- Queries AWS for instances tagged `vending-system-app-server`
- Updates `config/deploy.production.yml`
- Shows what it found

### ASG Grace Period

- **Duration:** 600 seconds (10 minutes)
- **Purpose:** Time for Kamal setup before health checks
- **Verified:** ✅ Applied to live ASG

### Docker Image

- **Size:** ~500-700 MB
- **Base:** ruby:3.4-slim
- **Optimization:** BuildKit cache mounts, jemalloc

### Registry Cache

- **Type:** Registry-based layer caching
- **Image:** ghcr.io/vndg-me/backend-build-cache
- **Benefit:** 2-3 min faster builds when Gemfile unchanged

---

## Performance Timeline

### First Deploy (Cold Build)

```
0:00 - kamal deploy starts
0:05 - Hook syncs IPs (auto)
0:10 - Build starts
0:15 - Gems compiled
0:30 - Assets precompiled
4:30 - Build complete
5:30 - Image pushed to registry
6:30 - Connect to instances
7:00 - Docker installed
8:00 - Image pulled
8:30 - Container started
9:00 - Health checks pass

Total: ~9-10 minutes
```

### Subsequent Deploy (Warm Build)

```
0:00 - kamal deploy starts
0:05 - Hook syncs IPs (auto)
0:10 - Build starts
2:10 - Build complete (cached!)
3:10 - Image pushed
4:10 - Instances updated
5:00 - Health checks pass

Total: ~6-8 minutes
```

---

## Health Check Configuration

The ALB checks if your app is healthy:

- **Endpoint:** `/up` on port 8080
- **Interval:** Every 30 seconds
- **Healthy when:** 2 consecutive passes
- **Unhealthy when:** 3 consecutive failures

Your Rails app must have a `/up` endpoint. Rails 7.1+ includes this by default:

```ruby
# config/routes.rb
get '/up', to: 'rails/health#show', as: :rails_health_check

# Built-in Rails health check controller
class HealthController < ApplicationController
  def check
    render json: { status: 'ok' }, status: :ok
  end
end
```

---

## Kamal Hooks

The `.kamal/hooks/pre-deploy` hook runs automatically before deployment:

```bash
#!/bin/bash
# 1. Only runs for production
if [ "$DESTINATION" != "production" ]; then
  exit 0
fi

# 2. Queries AWS for current instances
AWS_PROFILE=vndg aws ec2 describe-instances ...

# 3. Updates config with latest IPs
# 4. Shows results to user
```

**Why hooks instead of manual scripts?**

- ✅ Automatic (can't forget)
- ✅ Guaranteed to run
- ✅ CI/CD friendly
- ✅ Part of Kamal workflow

---

## Files Changed/Created

| File                               | Change   | Purpose                              |
| ---------------------------------- | -------- | ------------------------------------ |
| `.kamal/hooks/pre-deploy`          | NEW      | Auto-sync IPs before deploy          |
| `Dockerfile`                       | Enhanced | Added BuildKit cache mounts          |
| `config/deploy.yml`                | Enhanced | Enabled registry caching             |
| `.dockerignore`                    | Enhanced | Excludes 890 MB of unnecessary files |
| `terraform/.../autoscaling_app.tf` | Updated  | Grace period 300→600 seconds         |

---

## Troubleshooting

### Database Not Found (500 Error)

**Symptom:** `ActiveRecord::NoDatabaseError (Database not found: vndgme_production)`

**Solution:**
```bash
# Create the database
kamal app exec -d production "bin/rails db:create"

# Run migrations (skip postgis if it already exists)
kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"

# Verify
curl https://api.vndg.me/users/sign_in  # Should return login page (200)
```

**Note:** When ASG scales up with new instances, they need the database migrations applied.

### Solid Queue Configuration Error

**Symptom:** Container keeps exiting with "Solid Queue has gone away"

**Root Cause:** Puma config was checking `if ENV['SOLID_QUEUE_IN_PUMA']` which treats string `"false"` as truthy in Ruby

**Fix:** Changed to `if ENV['SOLID_QUEUE_IN_PUMA'] == 'true'` in `config/puma.rb`

**Details:**
- Web servers should have `SOLID_QUEUE_IN_PUMA: "false"`
- Worker servers should have `SOLID_QUEUE_IN_PUMA: "true"`
- The check must be explicit string comparison, not just truthiness

### Docker Permissions Error

**Symptom:** `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`

**Solution:** Add ubuntu user to docker group:
```bash
# Via SSH to instance
sudo usermod -aG docker ubuntu

# Or via Systems Manager
aws ssm start-session --target i-XXXXXXXXX --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["sudo usermod -aG docker ubuntu"]'
```

**When:** New instances from ASG don't have ubuntu in docker group

### Instances Still Restarting?

1. Check grace period: `aws autoscaling describe-auto-scaling-groups --region me-central-1 --query "AutoScalingGroups[].HealthCheckGracePeriod"`
2. Should show: `[600]`
3. Check health: `aws elbv2 describe-target-health --target-group-arn <arn> --region me-central-1`

### Health Checks Failing?

1. Check logs: `kamal logs -d production -f`
2. Test endpoint: `curl http://10.0.2.X:8080/up` (via bastion)
3. Common issues: missing `/up` endpoint, database not accessible, Redis not accessible

### Deploy Taking Too Long?

1. Check if gems changed: `git diff Gemfile.lock | wc -l`
2. If 0, build should be 2-3 min (cached)
3. If >0, build will be 4-5 min (recompiling)

### Can't SSH via Bastion?

1. Check bastion SG: `aws ec2 describe-security-groups --region me-central-1 --filters "Name=tag:Name,Values=*bastion*"`
2. Add your IP if needed: `aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 22 --cidr <your-ip>/32 --region me-central-1`

---

## Monitoring After Deploy

### Key Metrics

- Instance health: All green in ALB
- Application logs: No errors in Kamal logs
- Request latency: Response time normal
- Error rate: <1% of requests

### CloudWatch Alarms (Already Configured)

- ALB unhealthy hosts
- ALB 4xx/5xx errors
- App CPU utilization
- Network in/out

### Check Status

```bash
# Overall app status
kamal app status -d production

# Specific instance
kamal app exec "ps aux | grep rails"

# Database connection
kamal app exec "bin/rails dbconsole"
```

---

## CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
deploy:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GithubActionsRole
        aws-region: me-central-1

    - name: Deploy with Kamal
      run: kamal deploy -d production
      # Hook runs automatically!

    - name: Wait for health checks
      run: |
        for i in {1..30}; do
          HEALTHY=$(aws elbv2 describe-target-health ... | grep -c "healthy")
          [ "$HEALTHY" -ge 2 ] && exit 0
          sleep 10
        done
        exit 1
```

---

## Rollback

If something goes wrong:

```bash
# See previous versions
kamal version -d production

# Rollback to previous
kamal rollback -d production

# Verify
kamal logs -d production -f
```

---

## Best Practices

1. **Always commit before deploying**

   - Kamal uses git refs for version tracking

2. **Monitor logs during deployment**

   - `kamal logs -d production -f`

3. **Test health endpoint**

   - Ensure `/up` returns 200 OK

4. **Check database migrations**

   - Run before deploying if schema changed
   - `kamal app exec "bin/rails db:migrate"`

5. **Use CI/CD for deployments**
   - More reliable
   - Automated verification
   - Audit trail

---

## Summary

| Aspect            | Status                              |
| ----------------- | ----------------------------------- |
| Instance restarts | ✅ Fixed (grace period 10 min)      |
| Dynamic IPs       | ✅ Handled (auto-sync hook)         |
| Image size        | ✅ Optimized (500-700 MB)           |
| Push/export       | ✅ Fast (4-6 min)                   |
| Total deploy time | ✅ 8-12 min (cold) / 6-8 min (warm) |

**Result:** Reliable, fast, automated production deployments!

---

## Quick Reference Commands

```bash
# Deploy
kamal deploy -d production

# View logs
kamal logs -d production -f

# Check status
kamal app status -d production

# Run command on app
kamal app exec "bin/rails db:migrate"

# SSH to instance
ssh -o ProxyCommand="ssh -W %h:%p ubuntu@40.172.242.129" ubuntu@10.0.2.X

# Check health
aws elbv2 describe-target-health --target-group-arn <arn> --region me-central-1

# Rollback
kamal rollback -d production
```

For more details, see:

- `KAMAL_HOOKS_GUIDE.md` - How hooks work
- `KAMAL_HOOKS_VS_SCRIPTS.md` - Why hooks are better
- `PUSH_OPTIMIZATION_GUIDE.md` - Docker optimization details
- `DOCKER_IMAGE_OPTIMIZATION.md` - Image size optimization
- `DEPLOYMENT_QUICK_REFERENCE.md` - Quick command reference
