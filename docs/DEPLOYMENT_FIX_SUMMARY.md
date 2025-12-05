# December 5, 2025 - Production Deployment Issues & Fixes

## Summary

Fixed critical production deployment issues that were causing 502/500 errors. All systems are now operational.

## Issues Fixed

### 1. ✅ Docker Permission Denied
- **Symptom:** `permission denied while trying to connect to the docker API`
- **Root Cause:** New ASG instances don't have ubuntu user in docker group
- **Fix:** Added ubuntu to docker group on all instances
- **Permanent Solution:** Add to EC2 launch template user data

### 2. ✅ Solid Queue Configuration Error  
- **Symptom:** Containers kept restarting, "Solid Queue has gone away"
- **Root Cause:** `config/puma.rb` was checking `if ENV['SOLID_QUEUE_IN_PUMA']` which treats string "false" as truthy
- **Fix:** Changed to `if ENV['SOLID_QUEUE_IN_PUMA'] == 'true'` (explicit string comparison)
- **Files Modified:**
  - `config/puma.rb` - Added explicit string comparison with detailed comments
  - `config/deploy.production.yml` - Added explanatory comments for env vars

### 3. ✅ Database Missing on Scale-Up
- **Symptom:** 500 errors on `/users/sign_in` with `ActiveRecord::NoDatabaseError`
- **Root Cause:** When ASG scales up, new instances don't have database initialized
- **Fix:** Ran database creation and migrations:
  ```bash
  kamal app exec -d production "bin/rails db:create"
  kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"
  ```
- **Permanent Solution:** Add to post-deployment hook or documentation

### 4. ✅ Bastion SSH Access
- **Symptom:** Couldn't connect to app servers via bastion
- **Root Cause:** User's IP not in bastion security group
- **Fix:** Added IP 102.44.221.234/32 to bastion security group
- **Permanent Solution:** Document IP allowlisting process

## Documentation Added

### New Files
- **`docs/DEPLOYMENT_TROUBLESHOOTING.md`** - Comprehensive troubleshooting guide
  - Detailed explanations of each issue
  - Step-by-step solutions
  - Post-deployment checklist
  - Common issues and quick fixes
  - Log location guide

### Updated Files
- **`docs/PRODUCTION_DEPLOYMENT.md`** - Added extended troubleshooting section
- **`config/puma.rb`** - Added comments explaining the Solid Queue config fix
- **`config/deploy.production.yml`** - Added comments explaining SOLID_QUEUE_IN_PUMA usage

## Verification

All endpoints are working:
```
✓ GET /up → 200 OK (health check)
✓ GET / → 301 redirect (working redirects)
✓ GET /admin → 302 redirect (working redirects)
✓ GET /users/sign_in → 200 OK (login page loads)
```

Database is accessible:
```
✓ Database created
✓ Migrations applied
✓ Rails can query database
```

Containers are running:
```
✓ Web servers up and healthy
✓ Worker servers up
✓ All ALB target groups healthy
```

## Key Takeaways

1. **Solid Queue env var must use exact string comparison** - This is a common Ruby pitfall
2. **ASG scale-up requires database initialization** - Add to deployment hooks
3. **Docker group permissions needed on new instances** - Add to EC2 launch template
4. **Clear documentation prevents issues** - Created comprehensive troubleshooting guide

## Next Steps

1. ✅ Code changes deployed and tested
2. ✅ Documentation updated
3. ✅ Verification complete
4. **TODO:** Add post-deployment database migration to automated hooks
5. **TODO:** Add docker group membership to EC2 launch template user data
6. **TODO:** Add these fixes to deployment runbook

## Files Changed

```
config/deploy.production.yml          - Added comments explaining SOLID_QUEUE_IN_PUMA
config/puma.rb                        - Fixed Solid Queue config check + comments
docs/PRODUCTION_DEPLOYMENT.md         - Added troubleshooting section
docs/DEPLOYMENT_TROUBLESHOOTING.md    - NEW: Comprehensive troubleshooting guide
```

## Timeline

- **23:00** - Started debugging 502 error
- **23:05** - Fixed Bastion connection (security group)
- **23:10** - Fixed docker permissions on instances
- **23:15** - Deployed successfully, but Solid Queue error
- **23:20** - Fixed Solid Queue config issue in puma.rb
- **23:23** - Redeployed successfully
- **23:25** - Found database missing, ran migrations
- **23:27** - All endpoints working (✓ 200 OK)
- **23:35** - Updated documentation
- **23:45** - Committed all changes

## Commands Reference

Useful commands for future deployments:

```bash
# Deploy
kamal deploy -d production

# Check status
kamal app status -d production

# View logs
kamal logs -d production -f

# Initialize database on new deployment
kamal app exec -d production "bin/rails db:create"
kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"

# Verify endpoints
curl https://api.vndg.me/up                # Health check
curl -L https://api.vndg.me/                # Full flow
```
