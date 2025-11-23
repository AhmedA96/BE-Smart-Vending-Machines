# Kamal Hooks vs Separate Scripts - Decision Guide

## The Question You Asked

"Instead of generate-kamal-config script, why didn't we use kamal hooks?"

**Answer:** You were absolutely right! Hooks are better. Here's why and what changed.

## Side-by-Side Comparison

### Approach 1: Separate Script (Original)

```bash
# Deployment process:
./scripts/generate-kamal-config.sh    # Step 1: Manual
kamal deploy -d production            # Step 2: Manual
```

| Aspect | Script Approach |
|--------|-----------------|
| **Steps to deploy** | 2 manual commands |
| **Easy to forget** | ❌ Yes (forgot step 1?) |
| **Automatic** | ❌ No, requires user action |
| **CI/CD** | ⚠️ Need extra command |
| **Kamal-native** | ❌ External to Kamal |
| **Maintenance** | Separate file to maintain |
| **Consistency** | Depends on user discipline |

### Approach 2: Kamal Hook (Recommended)

```bash
# Deployment process:
kamal deploy -d production    # One command!
# Hook runs automatically first ✅
```

| Aspect | Hook Approach |
|--------|---------------|
| **Steps to deploy** | 1 command |
| **Easy to forget** | ✅ No (automatic!) |
| **Automatic** | ✅ Yes, always runs |
| **CI/CD** | ✅ Works seamlessly |
| **Kamal-native** | ✅ Yes, standard pattern |
| **Maintenance** | Part of Kamal workflow |
| **Consistency** | Guaranteed every time |

## How Hooks Work

Kamal hooks are scripts placed in `.kamal/hooks/` that run at specific deployment stages:

```
User runs: kamal deploy -d production
    ↓
pre-deploy hook executes
    ↓
🔍 Syncing instance IPs from AWS...
✅ Found 2 running instances
    ↓
[Normal deployment continues]
```

## Deployment Evolution

### Generation 1: Manual (Worst)
```bash
# User must remember all steps
kamal server bootstrap
aws elbv2 describe-target-groups
./scripts/some-setup.sh
./scripts/generate-kamal-config.sh
kamal deploy -d production

# Easy to mess up!
```

### Generation 2: Script (Better)
```bash
# One script handles some prep
./scripts/generate-kamal-config.sh
kamal deploy -d production

# Still 2 steps, can forget first step
```

### Generation 3: Hook (Best) ✅
```bash
# One command, everything automated
kamal deploy -d production

# Hook runs first automatically
# Can't forget anything!
```

## Files

### What We Created

#### `.kamal/hooks/pre-deploy` (NEW - Recommended)
```bash
#!/bin/bash
# Automatically syncs instance IPs from AWS
# Runs before every deployment
# Only for production (safety check)
```

#### `scripts/generate-kamal-config.sh` (Old - Optional)
```bash
#!/bin/bash
# Manual script for syncing IPs
# Useful if you want manual control
# No longer needed if using hook
```

### Which to Use?

**Recommendation: Use the hook only**

- ✅ Delete `scripts/generate-kamal-config.sh` (optional)
- ✅ Keep `.kamal/hooks/pre-deploy` (use this)
- ✅ One command to deploy: `kamal deploy -d production`

## Implementation Details

### The Hook (.kamal/hooks/pre-deploy)

```bash
#!/bin/bash
# 1. Safety check - only for production
if [ "$DESTINATION" != "production" ]; then
  exit 0  # Skip staging/dev
fi

# 2. Query AWS for current instances
AWS_PROFILE=vndg aws ec2 describe-instances ...

# 3. Update config with latest IPs
# 4. Show results to user
```

Key features:
- ✅ Automatic execution
- ✅ AWS querying
- ✅ Config updating
- ✅ Clear logging
- ✅ Error handling

### Safety Features

1. **Skips Non-Production**
   - Only runs for `kamal deploy -d production`
   - Safe for staging/dev

2. **Fails Fast**
   - If no instances found, deployment fails
   - Better than deploying to wrong IPs

3. **Idempotent**
   - Safe to run multiple times
   - Same result each time

4. **Clear Output**
   - Shows what it found
   - Helps with debugging

## Deployment Workflow Comparison

### Before (Script Approach)

```
1. Run IP sync script
   $ ./scripts/generate-kamal-config.sh
   ✅ Found 2 instances
   
2. Deploy
   $ kamal deploy -d production
   
3. Monitor
   $ kamal logs -d production -f
   
Problem: Step 1 is easy to forget!
```

### After (Hook Approach)

```
1. Deploy (hook handles everything)
   $ kamal deploy -d production
   
   [pre-deploy hook runs automatically]
   🔍 Syncing instance IPs from AWS...
   ✅ Found 2 running instances
   ✨ Instance IPs synced successfully
   
   [Normal deployment continues]
   
2. Monitor
   $ kamal logs -d production -f
   
Advantage: Can't forget anything!
```

## CI/CD Integration

### With Script Approach
```yaml
deploy:
  steps:
    - run: ./scripts/generate-kamal-config.sh  # Extra step
    - run: kamal deploy -d production
```

### With Hook Approach
```yaml
deploy:
  steps:
    - run: kamal deploy -d production  # Hook runs automatically!
```

Much cleaner!

## Testing the Hook

### Manual Test
```bash
# Test the hook directly
AWS_PROFILE=vndg KAMAL_DESTINATION=production \
  bash .kamal/hooks/pre-deploy

# Output:
# 🔍 Syncing instance IPs from AWS...
# ✅ Found 2 running instances
# ✨ Instance IPs synced successfully
```

### Integration Test
```bash
# Deploy and watch hook run
kamal deploy -d production

# You'll see:
# 🔍 Syncing instance IPs from AWS...
# ✅ Found 2 running instances
#    1. 10.0.2.149
#    2. 10.0.3.53
# ✨ Instance IPs synced successfully
#
# Building with...
# Pushing image...
```

## When to Use Hooks

**Use hooks for:**
- Deployment prerequisites ✅
- Configuration validation
- Pre-flight checks
- Environment setup
- Data migrations prep

**Use scripts for:**
- One-time setup
- Manual troubleshooting
- Operations that might run standalone

## Kamal Hook Best Practices

1. **Keep hooks simple**
   - One concern per hook
   - Clear, readable code

2. **Fast execution**
   - Hooks run before deployment
   - Don't delay deployments unnecessarily

3. **Idempotent**
   - Safe to run multiple times
   - Same result each time

4. **Good output**
   - Show what's happening
   - Help with debugging

5. **Fail fast**
   - Use `set -e`
   - Exit on errors
   - Don't let broken deployments proceed

## Migration Path

If you're currently using the script:

### Option 1: Hook Only (Recommended)
```bash
# Delete the script (hook replaces it)
rm scripts/generate-kamal-config.sh

# Use hook going forward
kamal deploy -d production  # Hook runs first!
```

### Option 2: Keep Both
```bash
# Keep script for manual use if needed
# Hook runs automatically

kamal deploy -d production  # Hook handles it
./scripts/generate-kamal-config.sh  # Manual if needed
```

## Available Kamal Hooks

Kamal supports these standard hooks:

| Hook | Timing | Use Case |
|------|--------|----------|
| `pre-build` | Before image build | Validation, setup |
| `pre-deploy` | Before deployment | **← IP sync** |
| `post-deploy` | After deployment | Notifications, verification |
| `pre-connect` | Before SSH connect | SSH validation |
| `docker-setup` | Docker config | Docker-specific setup |

## Troubleshooting

### Hook Not Running?

1. **Check executable:**
   ```bash
   ls -la .kamal/hooks/pre-deploy
   # Should show: -rwxr-xr-x
   ```

2. **Check file location:**
   ```bash
   # Must be in: .kamal/hooks/
   # Must be named: pre-deploy (no extension)
   ```

3. **Test manually:**
   ```bash
   bash .kamal/hooks/pre-deploy
   ```

### Deployment Fails?

The hook runs before deployment, so if it fails:
- Deployment won't proceed ✅ (safe)
- Error message shows why
- Fix and retry

## Summary

| Aspect | Script | Hook |
|--------|--------|------|
| **Manual step** | ❌ Yes | ✅ No |
| **Automatic** | ❌ No | ✅ Yes |
| **Easy to forget** | ❌ Yes | ✅ No |
| **CI/CD friendly** | ⚠️ Extra command | ✅ Works seamlessly |
| **Kamal-native** | ❌ No | ✅ Yes |
| **Recommended** | ❌ No | ✅ Yes |

## Conclusion

**Kamal hooks are the standard, recommended approach for deployment prerequisites.**

Advantages:
- ✅ Automatic (can't be forgotten)
- ✅ Consistent (always runs)
- ✅ Clean (no extra scripts)
- ✅ Professional (Kamal best practice)
- ✅ Reliable (fails fast if there's an issue)

**Use the hook approach for your IP syncing!**

```bash
# Simple, reliable, one-command deployment:
kamal deploy -d production
```
