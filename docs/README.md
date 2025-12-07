# Documentation Index

## 🚀 Getting Started

Start here for production deployments:

### [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
- **What:** Complete guide for deploying to production
- **When:** Every time you deploy
- **Duration:** 5 min read + 8-12 min deployment
- **Key sections:**
  - Quick start (1 command)
  - What was fixed (4 critical issues)
  - Deployment steps with timeline
  - Configuration details
  - Best practices
  - Rollback procedure

### [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)
- **What:** Detailed troubleshooting for deployment issues
- **When:** Something goes wrong during/after deployment
- **Duration:** 2-5 min depending on issue
- **Key sections:**
  - Recent issues fixed (Dec 5, 2025)
  - Common issues with solutions
  - Post-deployment checklist
  - Deployment timeline expectations
  - Log locations
  - Quick recovery steps

### [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
- **What:** Complete summary of all deployment work done on Dec 5, 2025
- **When:** Understanding what was fixed, code changes, and verification
- **Duration:** 5 min read
- **Key sections:**
  - Detailed issue analysis
  - Code changes with explanations
  - Files changed and why
  - Complete timeline
  - Key learnings

---

## 🏗️ Architecture & Infrastructure

### [system_design.md](system_design.md)
- Overall architecture and design decisions

### [ARCHITECTURE_CLOUDFLARE_ALB.md](ARCHITECTURE_CLOUDFLARE_ALB.md)
- Load balancing with AWS ALB
- Cloudflare integration
- SSL/TLS setup
- DNS configuration

### [CLOUDFLARE_DNS_SETUP.md](CLOUDFLARE_DNS_SETUP.md)
- Step-by-step Cloudflare DNS configuration
- Records needed
- Verification steps

### [README_CLOUDFLARE_INTEGRATION.md](README_CLOUDFLARE_INTEGRATION.md)
- Cloudflare integration details
- Cache configuration
- Security settings

---

## 🔐 Secrets & Configuration

### [PRODUCTION_SECRETS_SETUP.md](PRODUCTION_SECRETS_SETUP.md)
- How to set up secrets for production
- Environment variables
- AWS credentials
- Kamal secrets file

---

## 🔑 SSH & Bastion Access

### [SSH_BASTION_ACCESS.md](SSH_BASTION_ACCESS.md)
- **What:** Complete SSH setup and bastion access guide
- **When:** First time setup or troubleshooting SSH issues
- **Duration:** 5 min read + 5 min setup
- **Key sections:**
  - Quick start (5 minutes)
  - SSH configuration
  - Kamal integration
  - Troubleshooting SSH issues
  - Team onboarding
  - Security best practices

## 📋 Quick Reference

### Deployment Checklist
```bash
# Before deploying
docker ps                                    # Docker is running
git status                                   # All changes committed
AWS_PROFILE=vndg aws sts get-caller-identity  # AWS access works

# Deploy
kamal deploy -d production

# Monitor
kamal logs -d production -f

# Verify
curl https://api.vndg.me/up  # Should return 200 OK
```

### Common Issues

| Issue | Solution | Doc |
|-------|----------|-----|
| Docker permission denied | `sudo usermod -aG docker ubuntu` | [Troubleshooting](DEPLOYMENT_TROUBLESHOOTING.md#issue-1-docker-permission-denied) |
| Solid Queue error | Check puma.rb uses `== 'true'` | [Troubleshooting](DEPLOYMENT_TROUBLESHOOTING.md#issue-2-solid-queue-configuration-error) |
| 500 error on login | Run `db:create` and `db:migrate` | [Troubleshooting](DEPLOYMENT_TROUBLESHOOTING.md#issue-4-500-error-on-userssign_in-database-missing) |
| Can't SSH to bastion | SSH key setup required | [SSH_BASTION_ACCESS.md](SSH_BASTION_ACCESS.md#troubleshooting) |

### Useful Commands

```bash
# Deployment
kamal deploy -d production              # Deploy to production
kamal rollback -d production            # Rollback to previous version
kamal app status -d production          # Check deployment status

# Logs
kamal logs -d production -f             # Follow logs in real-time
kamal logs -d production --lines 100    # View last 100 lines

# Database
kamal app exec -d production "bin/rails db:create"
kamal app exec -d production "bin/rails db:migrate SKIP_POSTGIS_EXTENSION=true"

# SSH & Bastion (see SSH_BASTION_ACCESS.md for setup)
ssh ubuntu@158.252.98.228               # Connect to bastion
ssh ubuntu@10.0.2.225                   # Connect to app server (via bastion)
ssh-add ~/.ssh/vending-system-prod.pem  # Add key to agent

# Verification
curl https://api.vndg.me/up             # Health check
curl -L https://api.vndg.me/            # Full login flow
```

---

## 📝 File Structure

```
docs/
├── PRODUCTION_DEPLOYMENT.md           ← START HERE for deployments
├── SSH_BASTION_ACCESS.md              ← SSH setup & bastion access
├── ONBOARDING_CHECKLIST.md            ← Onboarding new team members
├── DEPLOYMENT_TROUBLESHOOTING.md      ← Go here if something breaks
├── DEPLOYMENT_FIX_SUMMARY.md          ← What was fixed on Dec 5
├── PRODUCTION_SECRETS_SETUP.md        ← Secrets configuration
├── system_design.md                   ← Overall architecture
├── ARCHITECTURE_CLOUDFLARE_ALB.md    ← Load balancing & CDN
├── CLOUDFLARE_DNS_SETUP.md           ← DNS configuration steps
├── README_CLOUDFLARE_INTEGRATION.md  ← Cloudflare details
└── README.md (this file)              ← You are here!
```

---

## 👥 Team Onboarding

### [ONBOARDING_CHECKLIST.md](ONBOARDING_CHECKLIST.md)
- **What:** Step-by-step checklist for onboarding new team members
- **When:** Adding someone new to the team
- **Duration:** 45 minutes (setup + verification)
- **Key sections:**
  - SSH setup (10 min)
  - AWS credentials (5 min)
  - Kamal setup (5 min)
  - Verification checklist
  - Troubleshooting during onboarding

---

## 🎯 Quick Links by Use Case

### "I want to deploy"
1. Read: [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
2. Run: `kamal deploy -d production`
3. Monitor: `kamal logs -d production -f`

### "Deployment failed"
1. Read: [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)
2. Find your error in the common issues section
3. Follow the fix steps

### "I see a 500 error"
1. Check [DEPLOYMENT_TROUBLESHOOTING.md - Database issues](DEPLOYMENT_TROUBLESHOOTING.md#issue-4-500-error-on-userssign_in-database-missing)
2. Run migrations if needed
3. Verify with `curl https://api.vndg.me/users/sign_in`

### "I can't SSH to app servers"
1. Check [DEPLOYMENT_TROUBLESHOOTING.md - SSH issues](DEPLOYMENT_TROUBLESHOOTING.md#symptom-new-instances-in-asg-but-deploy-fails-to-connect)
2. Add your IP to bastion security group
3. Try SSH to bastion first

### "I want to understand the architecture"
1. Read: [system_design.md](system_design.md)
2. Read: [ARCHITECTURE_CLOUDFLARE_ALB.md](ARCHITECTURE_CLOUDFLARE_ALB.md)

### "I need to set up production for the first time"
1. Read: [PRODUCTION_SECRETS_SETUP.md](PRODUCTION_SECRETS_SETUP.md)
2. Read: [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
3. Read: [CLOUDFLARE_DNS_SETUP.md](CLOUDFLARE_DNS_SETUP.md)

---

## 📞 Support

Having issues? Check the docs:

1. **During deployment:**
   - View logs: `kamal logs -d production -f`
   - Check status: `kamal app status -d production`

2. **After deployment fails:**
   - See [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)
   - Gather diagnostics and check logs

3. **Not sure where to start:**
   - See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
   - Follow the steps carefully

---

## 📅 Recent Updates

- **Dec 5, 2025** - Fixed production deployment issues
  - Docker permission denied
  - Solid Queue configuration error
  - Database initialization on scale-up
  - See [DEPLOYMENT_FIX_SUMMARY.md](DEPLOYMENT_FIX_SUMMARY.md)

---

## ✅ System Status

Last verified: **Dec 5, 2025 23:45 UTC**

| Component | Status |
|-----------|--------|
| API Health Check | ✅ 200 OK |
| Login Page | ✅ 200 OK |
| Database | ✅ Accessible |
| Web Servers | ✅ Healthy |
| Worker Servers | ✅ Healthy |
| ALB Targets | ✅ All healthy |

---

**Happy deploying! 🚀**
