# Automated Production Secrets Setup

This setup automatically fetches production secrets from AWS Secrets Manager and populates them into Kamal's secrets file before deployment.

## How It Works

### Automatic Flow
```
User runs deployment command
         ↓
Ruby script fetches secrets from AWS Secrets Manager
         ↓
Populates .kamal/secrets.production with actual values
         ↓
Kamal reads the populated secrets file
         ↓
Deployment proceeds with credentials
```

## Usage

### Option 1: Using Makefile (Recommended)
```bash
make deploy-production
```
This automatically:
1. Fetches secrets from AWS Secrets Manager
2. Populates `.kamal/secrets.production`
3. Runs `kamal deploy -d production`

### Option 2: Manual Steps
```bash
# Step 1: Fetch secrets from AWS
./scripts/populate-production-secrets.rb

# Step 2: Deploy with Kamal
kamal deploy -d production
```

### Option 3: Just fetch secrets
```bash
make deploy-production-secrets
# or
./scripts/populate-production-secrets.rb
```

## Files

### Scripts
- **`scripts/populate-production-secrets.rb`** - Ruby script that:
  - Connects to AWS Secrets Manager
  - Fetches production secrets
  - Writes them to `.kamal/secrets.production`
  - Requires: AWS CLI, IAM permissions, `jq`

- **`scripts/deploy-production.sh`** - Optional wrapper script (not used by Makefile)

### Secrets Files
- **`.kamal/secrets.production`** - Production secrets (auto-populated, do not edit)
- **`.kamal/secrets`** - Development secrets (sources from `.env`)
- **`.kamal/secrets.staging`** - Staging secrets (sources from `.env.staging`)

## Secrets Sources

Production secrets are fetched from AWS Secrets Manager:

| Secret | AWS Secrets Manager ID |
|--------|------------------------|
| `KAMAL_REGISTRY_PASSWORD` | `vending-system/production/github-container-registry-token` |
| `POSTGRES_USER` | `vending-system/production/db/credentials` (username) |
| `POSTGRES_PASSWORD` | `vending-system/production/db/credentials` (password) |
| `RAILS_MASTER_KEY` | `vending-system/production/app/secrets` (rails_master_key) |

These secrets are created and managed by Terraform in `terraform/environments/production/secrets.tf`.

## Requirements

Before deployment, ensure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws configure
   # or
   aws configure --profile vndg
   ```

2. **IAM Permissions** to read from Secrets Manager
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "secretsmanager:GetSecretValue"
     ],
     "Resource": "arn:aws:secretsmanager:me-central-1:*:secret:vending-system/production/*"
   }
   ```

3. **jq** installed (for JSON parsing)
   ```bash
   brew install jq  # macOS
   apt-get install jq  # Linux
   ```

4. **Ruby** (usually pre-installed on macOS/Linux)
   ```bash
   ruby --version  # Should be 3.0+
   ```

## Verification

Test that secrets can be fetched:
```bash
./scripts/populate-production-secrets.rb
```

Then verify the file is populated:
```bash
cat .kamal/secrets.production
```

You should see actual secret values (not empty fields).

## Troubleshooting

### Error: "AWS credentials not found"
```bash
aws configure
# Enter your AWS Access Key ID and Secret Access Key
```

### Error: "Secret not found"
- Verify secrets exist in AWS Secrets Manager:
  ```bash
  aws secretsmanager list-secrets --region me-central-1 --query 'SecretList[].Name'
  ```
- Check Terraform has been applied: `terraform apply -c terraform/environments/production/`

### Error: "jq not found"
```bash
brew install jq  # macOS
apt-get install jq  # Ubuntu/Debian
```

## Security Notes

✅ **Secrets are NOT hardcoded** in the repository
✅ **`.kamal/secrets.production` is dynamically generated** - do not commit actual values
✅ **`.env.production` is not needed** - secrets fetched directly from AWS
✅ **Requires AWS credentials** - cannot deploy without proper IAM permissions
✅ **Secrets are fetched at deployment time** - always fresh from AWS

## Development & Staging

For development and staging environments:
- Secrets source from `.env` and `.env.staging` files (local development)
- See `.kamal/secrets` and `.kamal/secrets.staging` for setup

## CI/CD Integration

For automated deployments in CI/CD:

1. Ensure CI/CD environment has AWS credentials (via IAM role or environment variables)
2. Run: `./scripts/populate-production-secrets.rb`
3. Run: `kamal deploy -d production`

Example GitHub Actions:
```yaml
- name: Deploy Production
  env:
    AWS_REGION: me-central-1
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: |
    ./scripts/populate-production-secrets.rb
    kamal deploy -d production
```
