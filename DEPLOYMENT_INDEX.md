# Documentation Index

This project has been optimized for production deployment with Kamal. Here's what you need to know:

## Main Documentation

### 📖 [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md) ⭐ START HERE

Complete guide for deploying to production. Covers everything from quick start to troubleshooting.

**Quick command:**

```bash
kamal deploy -d production
```

---

## Detailed Guides

### [KAMAL_HOOKS_GUIDE.md](./KAMAL_HOOKS_GUIDE.md)

How the pre-deploy hook works:

- Automatically syncs instance IPs from AWS
- Runs before every deployment
- Eliminates manual steps

### [KAMAL_HOOKS_VS_SCRIPTS.md](./KAMAL_HOOKS_VS_SCRIPTS.md)

Why we use Kamal hooks instead of separate scripts:

- Automatic vs manual
- CI/CD integration
- Best practices

### [PUSH_OPTIMIZATION_GUIDE.md](./PUSH_OPTIMIZATION_GUIDE.md)

Docker image push optimization:

- BuildKit cache mounts
- Registry caching
- Performance improvements (30-50% faster)

### [DOCKER_IMAGE_OPTIMIZATION.md](./DOCKER_IMAGE_OPTIMIZATION.md)

Docker image size optimization:

- .dockerignore cleanup (890 MB saved)
- Build context reduction
- Image size: 500-700 MB

### [DEPLOYMENT_QUICK_REFERENCE.md](./DEPLOYMENT_QUICK_REFERENCE.md)

Quick command reference for common tasks:

- Deploy, logs, status
- Health checks
- Troubleshooting commands

---

## What Was Fixed

| Issue                 | Solution                   | Status |
| --------------------- | -------------------------- | ------ |
| **Instance Restarts** | ASG grace period 5→10 min  | ✅     |
| **Dynamic IPs**       | Pre-deploy hook auto-syncs | ✅     |
| **Large Images**      | .dockerignore optimization | ✅     |
| **Slow Push**         | BuildKit + registry cache  | ✅     |

---

## Files Changed

| File                               | Change   | Purpose           |
| ---------------------------------- | -------- | ----------------- |
| `.kamal/hooks/pre-deploy`          | NEW      | Auto-sync IPs     |
| `Dockerfile`                       | Enhanced | BuildKit cache    |
| `config/deploy.yml`                | Enhanced | Registry caching  |
| `.dockerignore`                    | Enhanced | Size optimization |
| `terraform/.../autoscaling_app.tf` | Updated  | Grace period      |

---

## Quick Start

```bash
# 1. Deploy (everything automated)
kamal deploy -d production

# 2. Monitor (watch logs)
kamal logs -d production -f

# 3. Verify (check health)
curl https://api.vndg.me/up
```

**Deployment time:**

- First deploy: 8-12 minutes
- Subsequent: 6-8 minutes (with cached layers)

---

## Configuration Overview

### Health Checks

- **Endpoint:** `/up` on port 8080
- **Interval:** Every 30 seconds
- **Healthy:** 2 consecutive passes
- **Unhealthy:** 3 consecutive failures

### Grace Period

- **Duration:** 10 minutes (600 seconds)
- **Purpose:** Time for Kamal setup before health checks
- **Applied:** ✅ Live in production

### Docker Image

- **Size:** 500-700 MB
- **Base:** ruby:3.4-slim
- **Optimization:** BuildKit cache mounts + jemalloc

### Auto IP Sync

- **Hook:** `.kamal/hooks/pre-deploy`
- **Runs:** Before every deployment
- **Scope:** Production only
- **Source:** AWS EC2 instances

---

## Common Commands

```bash
# Deploy
kamal deploy -d production

# View logs
kamal logs -d production -f

# Check status
kamal app status -d production

# Run migrations
kamal app exec "bin/rails db:migrate"

# Rollback
kamal rollback -d production

# SSH to instance
ssh -o ProxyCommand="ssh -W %h:%p ubuntu@40.172.242.129" ubuntu@10.0.2.X
```

---

## Troubleshooting

### Instances Restarting?

1. Check grace period: `aws autoscaling describe-auto-scaling-groups --region me-central-1 --query "AutoScalingGroups[].HealthCheckGracePeriod"`
2. Should show: `[600]`

### Health Checks Failing?

1. Check logs: `kamal logs -d production -f`
2. Test endpoint: `curl http://10.0.2.X:8080/up` (via bastion)
3. Ensure `/up` endpoint exists in Rails

### Deploy Too Slow?

1. Check if Gemfile changed: `git diff Gemfile.lock | wc -l`
2. If 0: Build uses cache (2-3 min) ✅
3. If >0: Build recompiles (4-5 min) - normal

### CI/CD Integration?

See: **PRODUCTION_DEPLOYMENT.md** → CI/CD Integration section

---

## Key Metrics

| Metric            | Target   | Status |
| ----------------- | -------- | ------ |
| Build time (cold) | 4-5 min  | ✅     |
| Build time (warm) | 2-3 min  | ✅     |
| Push time         | 4-6 min  | ✅     |
| Total deploy      | 8-12 min | ✅     |
| Image size        | <700 MB  | ✅     |
| Instance uptime   | 100%     | ✅     |

---

## Next Steps

1. **Read** [PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)
2. **Deploy** with `kamal deploy -d production`
3. **Monitor** with `kamal logs -d production -f`
4. **Verify** with `curl https://api.vndg.me/up`

---

## Questions?

Refer to specific guides:

- **How to deploy?** → PRODUCTION_DEPLOYMENT.md
- **Why hooks?** → KAMAL_HOOKS_VS_SCRIPTS.md
- **How fast?** → PUSH_OPTIMIZATION_GUIDE.md
- **Quick commands?** → DEPLOYMENT_QUICK_REFERENCE.md
- **Image size?** → DOCKER_IMAGE_OPTIMIZATION.md

Everything is optimized and ready to go! 🚀
