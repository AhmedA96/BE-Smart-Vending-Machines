# Deployment Troubleshooting Guide

## Recent Issues Fixed (December 5, 2025)

### Issue 1: Docker Permission Denied

**Error:**
```
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**Root Cause:** New instances from AWS ASG don't have the `ubuntu` user in the `docker` group.

**Solution:**
```bash
# Option 1: Via SSH (if you already have access)
ssh ubuntu@<instance-ip>
sudo usermod -aG docker ubuntu
newgrp docker  # Activate group for current session

# Option 2: Via AWS Systems Manager (recommended for new instances)
aws ssm start-session --target i-XXXXXXXXX --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["sudo usermod -aG docker ubuntu"]'
```

**Prevention:** Add this to the ASG launch template user data script.

---

### Issue 2: Solid Queue Configuration Error

**Error:**
```
ActiveRecord::ConfigurationError: You must specify mode for solid_queue
[container kept restarting]
```

**Root Cause:** The puma configuration check was wrong:
```ruby
# WRONG - treats any non-nil value as true
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']

# RIGHT - explicit string comparison
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA'] == 'true'
```

In Ruby, the string `"false"` is truthy because it's not `nil` or `false`. So even when we set `SOLID_QUEUE_IN_PUMA="false"` on web servers, the plugin was still being loaded.

**Solution:** Update `config/puma.rb`:
```ruby
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA'] == 'true'
```

**Configuration:**
- **Web servers:** `SOLID_QUEUE_IN_PUMA: "false"` (process requests only)
- **Worker servers:** `SOLID_QUEUE_IN_PUMA: "true"` (run job processor)

---

### Issue 3: 502 Bad Gateway During Startup

**Error:**
```
502 Bad Gateway - Unable to proxy request
dial tcp [::1]:3000: connect: connection refused
```

**Root Cause:** Kamal health check ran before Rails app fully booted.

**Solution:** This is expected during deployment. The proxy automatically retries until the app is ready. Monitor with:
```bash
kamal logs -d production -f
```

Wait for:
```
[12] - Worker 0 (PID: 21) booted in 0.01s, phase: 0
[12] - Worker 1 (PID: 32) booted in 0.0s, phase: 0
[12] * Listening on http://0.0.0.0:3000
```

---

### Issue 4: 500 Error on /users/sign_in (Database Missing)

**Error:**
```
ActiveRecord::NoDatabaseError (Database not found: vndgme_production)
Caused by: PG::ConnectionBad (connection to server at "10.0.6.214", port 5432 failed: 
FATAL: database "vndgme_production" does not exist)
```

**Root Cause:** When ASG scales up to new instances, the database hasn't been initialized yet.

**Solution:**

**Step 1: Create the database**
```bash
kamal app exec -d production "bin/rails db:create"
```

Expected output:
```
App Host: 10.0.3.12
Database 'vndgme_production' created
```

(Errors on other hosts about duplicate key are OK - database already exists)

**Step 2: Run migrations**
```bash
kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"
```

**Why SKIP_POSTGIS_EXTENSION?** The postgis extension was already created on the RDS instance. Trying to create it again causes:
```
PG::UniqueViolation: ERROR duplicate key value violates unique constraint "pg_extension_name_index"
DETAIL: Key (extname)=(postgis) already exists.
```

**Verify:**
```bash
curl https://api.vndg.me/users/sign_in
# Should return HTML login page (200 OK)
```

---

### Issue 5: 301 Redirect Chain

**Flow:**
```
GET / → 301 Redirect to /admin
GET /admin → 302 Redirect to /users/sign_in
GET /users/sign_in → 200 (login page)
```

**If you get 500 at the end:** Make sure database is created (Issue 4).

---

## Post-Deployment Checklist

After deploying, verify:

```bash
# 1. Health check endpoint
curl https://api.vndg.me/up
# Expected: 200 OK with green HTML body

# 2. Sign-in page
curl -L https://api.vndg.me/
# Expected: 200 OK with login form (after following redirects)

# 3. Docker containers running
kamal app status -d production
# Expected: All servers showing running containers

# 4. Recent logs have no errors
kamal logs -d production --lines 50
# Expected: No ERROR or exception messages

# 5. Database is responsive
kamal app exec -d production "bin/rails dbconsole --mode=inspect"
# Expected: Can query the database
```

---

## Common Issues and Fixes

### Symptom: "Cannot connect to Docker daemon"

**Cause:** Docker socket permissions  
**Fix:**
```bash
sudo usermod -aG docker ubuntu
# Restart container or re-login
```

### Symptom: "Unable to proxy request" in logs (after ~30 seconds auto-resolves)

**Cause:** App still booting  
**Fix:** Normal - just wait. Monitor with `kamal logs -d production -f`

### Symptom: "Solid Queue has gone away, stopping Puma"

**Cause:** Wrong SOLID_QUEUE_IN_PUMA value or configuration error  
**Fix:** Check `config/puma.rb` uses `== 'true'` comparison. Check deployment config sets correct env vars for roles.

### Symptom: Database migration errors with "duplicate key" on postgis

**Cause:** Extension already exists on RDS  
**Fix:** Use `SKIP_POSTGIS_EXTENSION=true` flag

### Symptom: New instances in ASG but deploy fails to connect

**Cause:** Bastion security group doesn't allow your IP  
**Fix:**
```bash
# Find your IP
curl https://checkip.amazonaws.com

# Add to Bastion security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-XXXXXXXXX \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32 \
  --region me-central-1
```

---

## Deployment Timeline (Expected)

### First Deploy (Cold Build)
```
0:00  Deploy starts
0:05  Pre-hook syncs IPs from AWS
0:10  Build starts
4:30  Build complete
5:30  Image pushed to registry
6:30  SSH to instances
7:30  Create/update containers
8:30  Containers starting
9:00  Health checks passing ✓

Total: ~9-10 minutes
```

### Subsequent Deploys (Warm Build)
```
0:00  Deploy starts
0:05  Pre-hook syncs IPs from AWS
0:10  Build starts (cached!)
2:10  Build complete
3:10  Image pushed
4:10  Containers updated
5:00  Health checks passing ✓

Total: ~6-8 minutes
```

---

## Log Locations

### View live logs
```bash
kamal logs -d production -f
```

### Check specific container
```bash
# Get container name
aws ssm start-session --target i-XXXXXXXXX --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["sudo docker ps | grep vndgme"]'

# View logs
aws ssm start-session --target i-XXXXXXXXX --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["sudo docker logs <container-name>"]'
```

---

## Quick Recovery

If deployment fails:

```bash
# 1. Check what's happening
kamal logs -d production -f

# 2. If database issue
kamal app exec -d production "bin/rails db:create"
kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"

# 3. If Solid Queue issue
# Check config/puma.rb and config/deploy.production.yml

# 4. If Docker issue
aws ssm start-session --target i-XXXXXXXXX --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["sudo usermod -aG docker ubuntu"]'

# 5. If still failing, rollback
kamal rollback -d production

# 6. Investigate root cause
# Check logs and error messages carefully
```

---

## When to Ask for Help

Have these ready:

1. **Full error message** from `kamal logs -d production -f`
2. **Deploy command** you ran
3. **Recent git changes** with `git log --oneline -5`
4. **AWS instance status** from AWS Console
5. **Bastion connectivity** test result

```bash
# Quick diagnostics
echo "=== Your IP ===" && curl https://checkip.amazonaws.com
echo "=== Bastion connectivity ===" && ssh ubuntu@158.252.98.228 echo "ok"
echo "=== API status ===" && curl -w "\nHTTP %{http_code}\n" https://api.vndg.me/up
echo "=== Recent deploy log ===" && kamal logs -d production --lines 100
```
