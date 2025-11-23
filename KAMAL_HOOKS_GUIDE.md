# Kamal Hooks for Dynamic IP Syncing

## Why Hooks Are Better Than Separate Scripts

Instead of manually running a separate `generate-kamal-config.sh` script before each deployment, Kamal hooks **automate this completely**.

### Comparison

| Approach | Manual Script | Kamal Hook |
|----------|---------------|-----------|
| **Automatic** | ❌ Manual step | ✅ Automatic |
| **Easy to forget** | ❌ Error-prone | ✅ Guaranteed |
| **CI/CD friendly** | ❌ Extra command | ✅ Built-in |
| **Consistency** | ❌ Depends on user | ✅ Always runs |
| **Maintenance** | ❌ Separate file | ✅ Part of Kamal |

## How Kamal Hooks Work

Kamal hooks are scripts in `.kamal/hooks/` that run at specific stages of deployment:

```
kamal deploy
    ↓
.kamal/hooks/pre-deploy (runs FIRST) ← IP SYNC HAPPENS HERE
    ↓
Build image
    ↓
Connect to servers
    ↓
Stop old container
    ↓
Start new container
    ↓
.kamal/hooks/post-deploy (runs LAST)
```

## The Pre-Deploy Hook

File: `.kamal/hooks/pre-deploy`

This hook:
1. **Automatically runs** before every `kamal deploy`
2. **Skips non-production** deployments (safety check)
3. **Queries AWS** for current instances
4. **Updates config** with latest IPs
5. **Logs output** showing what it did

### How It Works

```bash
kamal deploy -d production
    ↓
[pre-deploy hook triggers]
    ↓
🔍 Syncing instance IPs from AWS...
✅ Found 2 running instances
   1. 10.0.2.149
   2. 10.0.3.53
✨ Instance IPs synced successfully
    ↓
[continue with actual deployment]
```

## Deployment Now

With hooks, deployment is **one command**:

```bash
kamal deploy -d production
```

That's it! No separate script needed.

### Before (Manual Script Approach)
```bash
# Step 1: Sync IPs
./scripts/generate-kamal-config.sh

# Step 2: Deploy
kamal deploy -d production

# 2 steps, easy to forget step 1
```

### After (Kamal Hooks Approach)
```bash
# Single command - everything automated
kamal deploy -d production

# IP sync happens automatically!
```

## The Hook Implementation

The pre-deploy hook is located at: `.kamal/hooks/pre-deploy`

Key features:

```bash
#!/bin/bash
# 1. Safety check - only run for production
if [ "$DESTINATION" != "production" ]; then
  exit 0  # Skip for staging/dev
fi

# 2. Query AWS for current instances
AWS_PROFILE=vndg aws ec2 describe-instances ...

# 3. Update config file with latest IPs
python3 << 'PYTHON_EOF'
  # Parse instances
  # Update config
  # Show results
PYTHON_EOF
```

## How to Use Kamal Hooks

### Existing Hooks

Standard Kamal hooks (already available):

| Hook | Timing | Purpose |
|------|--------|---------|
| `pre-build` | Before building image | Setup, validation |
| `pre-deploy` | Before deployment | **← IP sync happens here** |
| `post-deploy` | After deployment | Notifications, checks |
| `pre-connect` | Before SSH connection | SSH validation |
| `docker-setup` | When configuring Docker | Docker setup |

### Creating Your Own Hooks

1. **Create the hook file:**
   ```bash
   touch .kamal/hooks/pre-deploy
   chmod +x .kamal/hooks/pre-deploy
   ```

2. **Add a shebang:**
   ```bash
   #!/bin/bash
   ```

3. **Write your logic:**
   ```bash
   #!/bin/bash
   set -e
   echo "Running pre-deploy hook..."
   # Your code here
   ```

4. **Kamal automatically runs it**

### Environment Variables in Hooks

Kamal passes useful variables to hooks:

```bash
# In your hook:
KAMAL_DESTINATION     # staging, production, etc
KAMAL_VERSION         # App version being deployed
KAMAL_ROLE            # web, job, etc
```

Example using them:

```bash
#!/bin/bash
# Only sync IPs for production
if [ "$KAMAL_DESTINATION" != "production" ]; then
  exit 0
fi

echo "Deploying $KAMAL_VERSION to $KAMAL_DESTINATION"
```

## Safety Features

The pre-deploy hook has built-in safety:

### 1. Skips Non-Production
```bash
# Only syncs IPs for production
if [ "$DESTINATION" != "production" ]; then
  echo "⏭️  Skipping IP sync (not production)"
  exit 0
fi
```

### 2. Fails Fast
```bash
set -e  # Exit on any error
```

### 3. Clear Output
```bash
echo "✅ Found $IP_COUNT running instances"
```

### 4. AWS Validation
```bash
if [ -z "$IPS" ]; then
  echo "❌ Error: No instances found"
  exit 1  # Fail the deployment
fi
```

## Monitoring Hook Output

When running `kamal deploy`, you'll see:

```
🔍 Syncing instance IPs from AWS...
Fetching app instances from AWS...
✅ Found 2 running instances
✅ Config updated with 2 instances
   1. 10.0.2.149
   2. 10.0.3.53
✨ Instance IPs synced successfully

Starting deployment to production...
```

## Troubleshooting Hooks

### Hook Not Running?

1. **Check executable bit:**
   ```bash
   ls -la .kamal/hooks/pre-deploy
   # Should show: -rwx------
   ```

2. **Check for errors:**
   ```bash
   bash -x .kamal/hooks/pre-deploy
   # Shows each command as it runs
   ```

3. **Test hook directly:**
   ```bash
   AWS_PROFILE=vndg KAMAL_DESTINATION=production \
     bash .kamal/hooks/pre-deploy
   ```

### Hook Breaks Deployment?

The hook runs BEFORE deployment, so if it fails:
- Deployment won't proceed ✅ (safe)
- Error message shows why
- Fix and retry

Example error:
```
❌ Error: No running app instances found
```

### Debug Hook Output

```bash
# Add debug output
set -x  # Show each command

# Run hook with verbose AWS CLI
AWS_PROFILE=vndg bash .kamal/hooks/pre-deploy
```

## Integration with CI/CD

The hook runs automatically in CI/CD too!

### GitHub Actions Example

No changes needed - the hook just works:

```yaml
deploy:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Deploy with Kamal
      run: kamal deploy -d production
      # Hook automatically syncs IPs! ✅
```

## Files

### Created
- `.kamal/hooks/pre-deploy` - NEW: Automatic IP sync

### No Longer Needed (Optional)
- `scripts/generate-kamal-config.sh` - Can be removed (hook replaces it)

## Benefits of Hook Approach

✅ **Automatic** - Runs every time, no manual step
✅ **Foolproof** - Can't forget to sync IPs
✅ **Clean** - No extra script to maintain
✅ **CI/CD Ready** - Works in any environment
✅ **Safe** - Only runs for production
✅ **Transparent** - Shows what it's doing
✅ **Integrated** - Part of Kamal workflow

## Migration from Script to Hook

### If you were using the script:

Before:
```bash
./scripts/generate-kamal-config.sh  # Manual step
kamal deploy -d production
```

After:
```bash
kamal deploy -d production  # Hook handles IP sync automatically
```

### Keep or Remove Script?

- **Keep it** if you want manual control
- **Remove it** for cleaner setup (hook does everything)

The hook is recommended because:
- Guaranteed to run
- Can't be forgotten
- Works in CI/CD
- Standard Kamal pattern

## Best Practices

1. **Always use hooks for deployment prerequisites**
   - IP syncing ✅
   - Configuration validation
   - Pre-flight checks

2. **Keep hooks idempotent**
   - Safe to run multiple times
   - Same result each time

3. **Add clear output**
   - Users can see what's happening
   - Helps with debugging

4. **Fail fast on errors**
   - Don't let bad deployments proceed
   - `set -e` to exit on error

5. **Test hooks locally**
   ```bash
   AWS_PROFILE=vndg KAMAL_DESTINATION=production \
     bash .kamal/hooks/pre-deploy
   ```

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Deployment command** | 2 steps | 1 step |
| **Manual steps** | IP sync | None |
| **Forgetting to sync** | Possible | Impossible |
| **CI/CD** | Extra command | Automatic |
| **Maintenance** | Separate script | Built into Kamal |

**Kamal hooks are the recommended approach for any deployment prerequisite!**
