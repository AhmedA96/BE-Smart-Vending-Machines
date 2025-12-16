# SSH and Bastion Access Setup Guide

## Overview

The production infrastructure uses a **Bastion Host** (jumpbox) for secure SSH access to private app servers.

- **Bastion Host (Public):** 158.252.98.228
- **App Servers (Private):** 10.0.2.x, 10.0.3.x (in private subnets)
- **Security Model:** SSH key-based authentication (not IP-restricted)

---

## Quick Start (5 minutes)

### 1. Get the SSH Private Key

Ask your team lead for the SSH private key file:
```bash
vending-system-prod.pem
```

Place it in your home directory:
```bash
mkdir -p ~/.ssh
# Copy vending-system-prod.pem to ~/.ssh/
chmod 600 ~/.ssh/vending-system-prod.pem
```

### 2. Add to SSH Agent

```bash
ssh-add ~/.ssh/vending-system-prod.pem
```

Verify it's added:
```bash
ssh-add -l | grep vending
```

Output should show:
```
2048 SHA256:N4Ciq43oIzhrHqu2ndxqnrS+Ahkgx22I9FEuxK36vg4 /Users/username/.ssh/vending-system-prod.pem (RSA)
```

### 3. Configure SSH (Optional but Recommended)

Add this to `~/.ssh/config`:

```bash
# Production bastion host
Host vending-bastion
  HostName 158.252.98.228
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  StrictHostKeyChecking no

# Private app servers through bastion
Host 10.0.*
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  ProxyJump vending-bastion
  StrictHostKeyChecking no
```

### 4. Test Connection

```bash
# Test bastion connection
ssh ubuntu@158.252.98.228
# Should print: Welcome to Ubuntu...

# Test app server via bastion
ssh ubuntu@10.0.2.225
# Should connect through bastion automatically
```

### 5. Use with Kamal

```bash
# Deploy to production
kamal deploy -d production

# View logs
kamal logs -d production -f

# Access console
kamal console -d production

# Run commands
kamal app exec -d production "bin/rails db:migrate"
```

---

## How It Works

### SSH Connection Flow

```
Your Machine
    ↓ SSH key: vending-system-prod.pem
    ↓
Bastion Host (158.252.98.228)
    ↓ SSH proxy through bastion
    ↓
Private App Server (10.0.2.225)
```

### Security Architecture

```
INTERNET (anywhere)
    ↓
[SSH Port 22 - OPEN 0.0.0.0/0]
    ↓
Bastion Security Group
    ├─ Inbound: SSH from anywhere (0.0.0.0/0)
    │   ✅ Security relies on SSH key authentication
    │   ✅ No IP whitelisting needed
    ├─ Outbound: SSH to private app servers (10.0.0.0/16)
    └─ Outbound: HTTPS to internet

App Servers (Private Subnets)
    ├─ Inbound: SSH only from bastion
    ├─ Inbound: HTTP/HTTPS from ALB
    └─ Outbound: Database, Redis, Internet
```

---

## SSH Commands

### Direct SSH Access

```bash
# SSH to bastion
ssh ubuntu@158.252.98.228

# SSH to app server (proxies through bastion automatically)
ssh ubuntu@10.0.2.225

# SSH with specific key
ssh -i ~/.ssh/vending-system-prod.pem ubuntu@10.0.2.225

# SSH with command execution
ssh ubuntu@10.0.2.225 "docker ps"

# SSH with port forwarding
ssh -L 5432:rds-endpoint:5432 ubuntu@10.0.2.225
```

### SCP (File Transfer)

```bash
# Copy file from bastion to local
scp ubuntu@158.252.98.228:/tmp/file.txt ./file.txt

# Copy file from app server to local (via bastion)
scp ubuntu@10.0.2.225:/tmp/file.txt ./file.txt

# Copy local file to app server (via bastion)
scp ./file.txt ubuntu@10.0.2.225:/tmp/file.txt
```

### Tunneling/Port Forwarding

```bash
# Forward local port to RDS through app server
ssh -L 5432:rds-endpoint:5432 ubuntu@10.0.2.225

# Then connect locally
psql -h localhost -U vndg -d vendingdb

# Forward local port to Redis
ssh -L 6379:redis-endpoint:6379 ubuntu@10.0.2.225
redis-cli -h localhost -p 6379 ping
```

---

## Troubleshooting

### Issue: "Permission denied (publickey)"

**Cause:** SSH key not found or not in SSH agent

**Solution:**
```bash
# Check if key file exists
ls -la ~/.ssh/vending-system-prod.pem

# Add to SSH agent
ssh-add ~/.ssh/vending-system-prod.pem

# Verify it's added
ssh-add -l
```

### Issue: "Connection timed out"

**Possible causes:**
1. Network connectivity issue
2. Bastion instance down
3. Security group misconfigured

**Solutions:**
```bash
# Check if bastion is reachable
ping 158.252.98.228

# Check AWS instance status
aws ec2 describe-instances \
  --instance-ids i-0e2902157b4a51daf \
  --region me-central-1 \
  --query 'Reservations[0].Instances[0].State.Name'

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-000962cc7b2d73f9f \
  --region me-central-1 \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'
```

### Issue: "ssh_exchange_identification: Connection closed by remote host"

**Cause:** SSH key permissions incorrect

**Solution:**
```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/vending-system-prod.pem

# Verify permissions (should be exactly 600)
ls -la ~/.ssh/vending-system-prod.pem
```

### Issue: "Host key verification failed"

**Cause:** StrictHostKeyChecking enabled in SSH config

**Solution:** Either disable or accept the host key:
```bash
# Option 1: Add to ~/.ssh/config
Host vending-bastion
  StrictHostKeyChecking no  # or "accept-new"

# Option 2: Manually accept during first connection
ssh ubuntu@158.252.98.228
# Type "yes" when asked to accept the host key
```

### Issue: SSH Agent Not Working (macOS)

If SSH agent doesn't persist across sessions:

```bash
# Add to ~/.zshrc or ~/.bash_profile
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/vending-system-prod.pem
```

Or use macOS Keychain:

```bash
# Add this to ~/.ssh/config
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/vending-system-prod.pem
```

---

## SSH Config Setup

### Minimal Config

```bash
# ~/.ssh/config
Host vending-bastion
  HostName 158.252.98.228
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem

Host 10.0.*
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  ProxyJump vending-bastion
```

### Full Config (with Strict Checking)

```bash
Host vending-bastion
  HostName 158.252.98.228
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts
  IdentitiesOnly yes
  ConnectTimeout 10

Host 10.0.*
  User ubuntu
  IdentityFile ~/.ssh/vending-system-prod.pem
  ProxyJump vending-bastion
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentitiesOnly yes
```

---

## Kamal Deployment

### How Kamal Uses SSH

1. **SSH Proxy Configuration:**
   - Defined in `config/deploy.production.yml`
   - Uses bastion as proxy host
   - All app servers accessed through bastion

2. **Configuration:**
   ```yaml
   ssh:
     user: ubuntu
     proxy: ubuntu@158.252.98.228
   ```

3. **Kamal Commands:**
   ```bash
   # Deploy (automatically uses SSH proxy)
   kamal deploy -d production

   # View logs
   kamal logs -d production -f

   # Run command on app
   kamal app exec -d production "bin/rails db:migrate"

   # Access console
   kamal console -d production

   # View app details
   kamal details -d production
   ```

### Kamal SSH Requirements

- SSH key must be in SSH agent: `ssh-add ~/.ssh/vending-system-prod.pem`
- SSH config optional (Kamal handles proxy internally)
- AWS credentials configured: `export AWS_PROFILE=vndg`

---

## Security Considerations

### SSH Key Management

✅ **Do:**
- Keep key file permissions as 600 (`chmod 600`)
- Store in `~/.ssh/` directory
- Add to SSH agent for session
- Rotate keys periodically
- Audit who has access to keys

❌ **Don't:**
- Commit SSH keys to git
- Share keys via email
- Use overly permissive file permissions (777, 644)
- Leave key in `/tmp` or public locations
- Use same key across multiple projects

### Bastion Security Model

- **IP Restriction:** ❌ None (open to 0.0.0.0/0)
- **SSH Key Authentication:** ✅ Required
- **Key-Based Access:** ✅ Primary security layer
- **Audit Trail:** ✅ CloudWatch logs
- **Monitoring:** ✅ CloudWatch alarms

**Rationale:**
- Team members from any location can deploy
- No need to add/remove IPs when someone moves
- SSH key authentication is industry-standard security
- More flexible than IP whitelisting

---

## AWS Systems Manager Alternative

For debugging without SSH (if SSH key lost):

```bash
# List instances
aws ec2 describe-instances \
  --region me-central-1 \
  --query 'Reservations[].Instances[].{Id:InstanceId,Ip:PrivateIpAddress}' \
  --filters "Name=tag:Name,Values=*app*"

# Connect via Systems Manager
aws ssm start-session \
  --target i-0af124655aa605e4f \
  --region me-central-1

# Run command
aws ssm start-session \
  --target i-0af124655aa605e4f \
  --region me-central-1 \
  --document-name "AWS-StartInteractiveCommand" \
  --parameters 'command=["whoami"]'
```

**Note:** Requires IAM permissions and EC2 Instance Connect Endpoint

---

## Team Onboarding

### For New Team Members

1. **Provide SSH Key**
   - Share `vending-system-prod.pem` securely (password-protected file transfer)
   - Verify they received it

2. **Send Setup Instructions**
   - Share this doc: `docs/SSH_BASTION_ACCESS.md`
   - Point them to "Quick Start" section

3. **Verify Access**
   - Ask them to run: `ssh ubuntu@158.252.98.228`
   - Confirm they can SSH successfully

4. **Grant Kamal Permissions**
   - Ensure they have AWS_PROFILE configured
   - Test: `kamal details -d production`

### For SSH Key Rotation

```bash
# 1. Generate new key
ssh-keygen -t rsa -b 4096 -f vending-system-prod-new.pem -N ""

# 2. Add to bastion's authorized_keys
ssh ubuntu@158.252.98.228
  echo "$(cat ~/.ssh/vending-system-prod-new.pub)" >> ~/.ssh/authorized_keys

# 3. Update all team members
# 4. Remove old key from authorized_keys (after everyone updated)
# 5. Delete old key files
```

---

## Quick Reference

```bash
# Add key to agent
ssh-add ~/.ssh/vending-system-prod.pem

# Test bastion
ssh ubuntu@158.252.98.228

# Test app server
ssh ubuntu@10.0.2.225

# Deploy
kamal deploy -d production

# View logs
kamal logs -d production -f

# SSH to specific instance
ssh ubuntu@10.0.2.225

# Run command on app
kamal app exec -d production "whoami"
```

---

## Related Docs

- `PRODUCTION_DEPLOYMENT.md` - Kamal deployment guide
- `terraform/environments/production/bastion.tf` - Bastion infrastructure
- `config/deploy.production.yml` - Kamal production config

---

## Support

For SSH access issues:
1. Check `~/.ssh/config` syntax
2. Verify SSH key permissions: `ls -la ~/.ssh/vending-system-prod.pem`
3. Check if key is in agent: `ssh-add -l`
4. Test bastion directly: `ssh -v ubuntu@158.252.98.228`
5. Check AWS security group: `aws ec2 describe-security-groups --group-ids sg-000962cc7b2d73f9f --region me-central-1`

For Kamal issues:
1. Check environment: `echo $AWS_PROFILE`
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Test SSH agent: `ssh-add -l`
4. Run with verbose: `kamal deploy -d production -v`
