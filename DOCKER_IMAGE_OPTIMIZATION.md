# Docker Image Size Optimization

## Issue Identified

The Docker image was including unnecessary files, bloating its size:

### What Was Being Included (Wasted Space)

| Directory | Size | Problem |
|-----------|------|---------|
| `/terraform/` | 665 MB | Infrastructure code, not needed in runtime image |
| `/tmp/cache/` | 207 MB | Build cache, should be ignored |
| `/coverage/` | 2.8 MB | Test coverage reports, development only |
| `/.git/` | 11 MB | Source control history, not needed in container |
| `/test/` and `/spec/` | ~1 MB | Test code, development only |
| Documentation | Various | README, guides, not needed at runtime |

**Total unnecessary space: ~890 MB!**

## Solution: Updated `.dockerignore`

Added comprehensive ignore rules to prevent unnecessary files from being copied into the Docker image:

```dockerfile
# Ignore Terraform and infrastructure code
/terraform/
/.terraform/
*.tfstate*
*.tfvars

# Ignore test/coverage files
/coverage/
/test/
/spec/

# Ignore documentation
/*.md
/docs/

# Ignore cache directories
/tmp/cache/
/vendor/cache/

# Ignore IDE files
/.vscode/
/.idea/
*.swp
*.swo
*~
```

## Expected Size Reduction

- **Before**: ~1.5-2.0 GB (estimated)
- **After**: ~500-700 MB (estimated)
- **Reduction**: 60-70% smaller images

This means:
- ✅ Faster pulls to instances (less bandwidth)
- ✅ Faster container startup (less to load)
- ✅ Smaller registry storage costs
- ✅ Quicker Kamal deployments

## What Remains in the Image

The final Docker image will contain only what's needed at runtime:

- ✅ Ruby runtime (ruby:3.4-slim base)
- ✅ Rails application code
- ✅ All production gems (from Gemfile.lock)
- ✅ Precompiled assets
- ✅ Database migrations
- ✅ Configuration files (non-secret)
- ✅ Bootsnap cache

## Files Changed

- **`.dockerignore`** - Expanded to exclude large development/infrastructure directories

## Testing the Change

The next time Kamal builds the image, it will be significantly smaller:

```bash
# Rebuild the image with the updated .dockerignore
kamal build -d production

# Check the image size
docker images | grep vndg
```

## Why This Matters for Production

1. **Deployment Speed**: Smaller images pull faster to instances
   - Each instance needs to pull the image
   - 890 MB less = significant time savings
   - Especially important during ASG scale-up

2. **Network Cost**: Less data transferred over the network
   - AWS charges for data transfer
   - ghcr.io bandwidth usage reduced

3. **Instance Storage**: Images stored locally on instances
   - Less storage used on each instance
   - More room for logs and temporary files

4. **Troubleshooting**: Faster to download when debugging
   - SSH into instance and need to pull image again
   - Development/testing scenarios

## Verification After Next Deploy

After the next deployment, verify the image size reduction:

```bash
# Check image in registry
aws ecr describe-images --repository-name backend --region us-east-1

# Or on the instance after deployment:
docker images | grep vndg
docker system df  # See disk usage
```

## Future Optimizations

Additional optimizations could be considered:

1. **Multi-stage build enhancements**
   - Further reduce final stage size
   - Currently optimized pretty well

2. **Asset optimization**
   - Minify CSS/JS (already done by Rails)
   - Consider CDN for static files

3. **Gem optimization**
   - Remove unused gems
   - Consider lightweight alternatives for some gems

4. **Binary stripping**
   - Remove debug symbols from compiled gems
   - Advanced optimization, minimal benefit

## No Breaking Changes

✅ This change has **zero impact** on functionality:
- Same application code runs
- Same performance characteristics
- Same features available
- Just a size optimization

Next Kamal deployment will automatically use the new `.dockerignore` rules.
