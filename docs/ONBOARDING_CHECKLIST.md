# Team Onboarding Checklist - Production Access

Use this checklist to onboard new team members to production deployment.

---

## Prerequisites ✅

- [ ] Team member has AWS credentials (configured as `AWS_PROFILE=vndg`)
- [ ] Team member has Docker installed locally
- [ ] Team member has Kamal installed locally
- [ ] Team member has Git access to the repository
- [ ] Team member received SSH private key (`vending-system-prod.pem`)

---

## SSH Setup (10 minutes)

### 1. Place SSH Key

```bash
# Have team member run:
mkdir -p ~/.ssh
# Copy vending-system-prod.pem to ~/.ssh/
chmod 600 ~/.ssh/vending-system-prod.pem

# Verify
ls -la ~/.ssh/vending-system-prod.pem
# Should show: -rw------- (permissions 600)
```

### 2. Add to SSH Agent

```bash
ssh-add ~/.ssh/vending-system-prod.pem
```

Verify:
```bash
ssh-add -l | grep vending
# Should show the key fingerprint
```

### 3. Test Connection

```bash
# Should connect without password
ssh ubuntu@158.252.98.228
# Type "yes" if asked about host key, then exit with Ctrl+D
```

### 4. (Optional) Configure SSH

Add to `~/.ssh/config`:

```bash
Host vending-bastion
  HostName 158.252.98.228
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem

Host 10.0.*
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  ProxyJump vending-bastion
```

---

## AWS Credentials Setup (5 minutes)

### 1. Verify AWS Profile

```bash
# Should return account info without errors
AWS_PROFILE=vndg aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "...",
    "Account": "471112976287",
    "Arn": "arn:aws:iam::471112976287:user/..."
}
```

### 2. Test AWS Access

```bash
# List EC2 instances
AWS_PROFILE=vndg aws ec2 describe-instances \
  --region me-central-1 \
  --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' \
  --output text | head -5
```

---

## Kamal Setup (5 minutes)

### 1. Install Kamal (if not already installed)

```bash
gem install kamal
kamal version
```

### 2. Test Configuration

```bash
cd backend/
kamal -d production config  # Should show config without errors
```

### 3. Verify Access to Instances

```bash
# Should list all instances
kamal details -d production
```

You should see output like:
```
Proxy Host: 10.0.2.225
CONTAINER ID   IMAGE...

App Host: 10.0.2.225
CONTAINER ID   IMAGE...
```

---

## Repository Access (5 minutes)

### 1. Clone Repo

```bash
git clone git@github.com:vndg-me/backend.git
cd backend
```

### 2. Verify SSH to GitHub

```bash
ssh -T git@github.com
# Should output: Hi <username>! You've successfully authenticated...
```

### 3. Test Git

```bash
git status
git log --oneline -n 5
```

---

## Docker Setup (5 minutes)

### 1. Verify Docker

```bash
docker ps
# Should list containers without sudo

# If permission denied:
# Your IT team already added you to docker group
# Log out and log back in
```

### 2. Test Image Build

```bash
docker build -t test:latest . --progress=plain
# Should complete successfully
```

---

## Database Access (10 minutes)

### 1. SSH to App Server

```bash
ssh ubuntu@10.0.2.225
# Should connect via bastion automatically
```

### 2. Test Database Connection (from app server)

```bash
# From app server SSH session:
docker ps  # Should show running containers
docker exec -it vndgme-web-production-* bin/rails dbconsole
```

Type `\q` to exit.

### 3. Check Migrations

```bash
# From local machine:
kamal app exec -d production "bin/rails db:migrate:status"
```

---

## Email Verification

### Send Welcome Email

```markdown
Subject: Welcome to Vending System Production Access!

Hi [Name],

You've been successfully onboarded to the Vending System production environment!

✅ SSH access configured
✅ Kamal deployment access granted
✅ Database access verified
✅ Docker environment ready

## Quick Start

Deploy to production:
```bash
kamal deploy -d production
```

Watch logs:
```bash
kamal logs -d production -f
```

SSH to app server:
```bash
ssh ubuntu@10.0.2.225
```

## Documentation

- **Deployment:** docs/PRODUCTION_DEPLOYMENT.md
- **SSH Setup:** docs/SSH_BASTION_ACCESS.md
- **Troubleshooting:** docs/DEPLOYMENT_TROUBLESHOOTING.md

## Key Contacts

- Deployment issues: @mahmoud
- Database issues: @[DBA]
- Infrastructure issues: @[DevOps]

Welcome aboard!
```

---

## Verification Checklist

### Before Declaring Success

- [ ] Team member can SSH to bastion: `ssh ubuntu@158.252.98.228`
- [ ] Team member can SSH to app server: `ssh ubuntu@10.0.2.225`
- [ ] AWS credentials work: `AWS_PROFILE=vndg aws sts get-caller-identity`
- [ ] Can view instance details: `kamal details -d production`
- [ ] Can view logs: `kamal logs -d production --lines 5`
- [ ] Can list database migrations: `kamal app exec -d production "bin/rails db:migrate:status"`
- [ ] Can access console: `kamal console -d production` (and exit with `exit`)

---

## Troubleshooting During Onboarding

### SSH Key Not Working

**Problem:** Permission denied (publickey)

**Solution:**
```bash
# Verify key exists
ls -la ~/.ssh/vending-system-prod.pem

# Verify permissions are 600
chmod 600 ~/.ssh/vending-system-prod.pem

# Add to agent
ssh-add ~/.ssh/vending-system-prod.pem

# Test
ssh -v ubuntu@158.252.98.228
```

### AWS Credentials Not Working

**Problem:** `Unable to locate credentials`

**Solution:**
```bash
# Verify AWS config
cat ~/.aws/config
cat ~/.aws/credentials

# Test profile
AWS_PROFILE=vndg aws sts get-caller-identity

# Make sure to use AWS_PROFILE in commands:
AWS_PROFILE=vndg kamal deploy -d production
```

### Docker Permission Issues

**Problem:** `permission denied while trying to connect to docker`

**Solution:**
```bash
# Check if user is in docker group
groups
# Should include 'docker'

# If not, IT team needs to add:
sudo usermod -aG docker $USER

# Then restart shell/terminal
exit
# Log back in
```

### Kamal Can't Connect

**Problem:** SSH proxy errors when running `kamal` commands

**Solution:**
```bash
# Verify SSH key is in agent
ssh-add -l | grep vending

# Verify SSH config
cat ~/.ssh/config
# Should have vending-bastion and 10.0.* entries

# Test manual SSH
ssh ubuntu@10.0.2.225

# Then retry Kamal
kamal details -d production -v  # verbose
```

---

## Success Criteria

Team member is successfully onboarded when they can:

1. ✅ SSH directly to bastion: `ssh ubuntu@158.252.98.228`
2. ✅ SSH through bastion to app server: `ssh ubuntu@10.0.2.225`
3. ✅ Run Kamal commands: `kamal details -d production`
4. ✅ Deploy: `kamal deploy -d production` (read-only first)
5. ✅ View logs: `kamal logs -d production -f`
6. ✅ Access database: `kamal app exec -d production "bin/rails dbconsole"`

---

## Post-Onboarding

### Day 1
- [ ] Shadowed a production deployment
- [ ] Reviewed PRODUCTION_DEPLOYMENT.md
- [ ] Reviewed SSH_BASTION_ACCESS.md

### Week 1
- [ ] Made first deployment (with review)
- [ ] Troubleshot a minor issue
- [ ] Reviewed monitoring/alerting setup

### Week 2+
- [ ] Independent deployments
- [ ] Can troubleshoot common issues
- [ ] Can onboard next team member

---

## Files to Share

1. `docs/SSH_BASTION_ACCESS.md` - Complete SSH setup guide
2. `docs/PRODUCTION_DEPLOYMENT.md` - Deployment guide
3. `docs/DEPLOYMENT_TROUBLESHOOTING.md` - Common issues
4. `terraform/environments/production/bastion.tf` - Infrastructure details
5. `config/deploy.production.yml` - Kamal configuration

---

## Notes

- SSH key (`vending-system-prod.pem`) should be kept secure and never committed to git
- AWS_PROFILE should always be set to `vndg` when deploying to production
- Kamal hooks automatically sync instance IPs - no manual updates needed
- Database credentials are stored in AWS Secrets Manager, not in code

---

## Related Documentation

- [SSH & Bastion Access](SSH_BASTION_ACCESS.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Troubleshooting](DEPLOYMENT_TROUBLESHOOTING.md)
- [Secrets Setup](PRODUCTION_SECRETS_SETUP.md)
