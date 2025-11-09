# Coolify Workflow Examples

Common workflows and real-world usage examples for Coolify management.

## Table of Contents

- [Quick Start Workflows](#quick-start-workflows)
- [Deployment Workflows](#deployment-workflows)
- [Monitoring Workflows](#monitoring-workflows)
- [Maintenance Workflows](#maintenance-workflows)
- [Troubleshooting Workflows](#troubleshooting-workflows)
- [Advanced Workflows](#advanced-workflows)

## Quick Start Workflows

### Check System Health

Quick overview of all applications:

```bash
#!/bin/bash
# See scripts/health-check.sh for full implementation

# List all apps with status
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | "\(.name): \(.status)"' | \
  column -t

# Count by status
echo "\nStatus Summary:"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[].status' | sort | uniq -c
```

### Find Application by Name

```bash
#!/bin/bash
APP_NAME="ask-a-genie"

# Search by partial name match
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg name "$APP_NAME" \
    '.[] | select(.name | contains($name)) |
     "\(.name)\n  UUID: \(.uuid)\n  Status: \(.status)\n  URL: \(.fqdn)"'
```

## Deployment Workflows

### Deploy Single Application

Complete deployment workflow with monitoring:

```bash
#!/bin/bash
# See scripts/deploy.sh for full implementation

APP_NAME="my-app"

echo "🚀 Deploying $APP_NAME..."

# Step 1: Find application
echo "Finding application..."
APP_DATA=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg name "$APP_NAME" '.[] | select(.name | contains($name))')

if [ -z "$APP_DATA" ]; then
  echo "❌ Application not found: $APP_NAME"
  exit 1
fi

APP_UUID=$(echo "$APP_DATA" | jq -r '.uuid')
echo "Found: $APP_UUID"

# Step 2: Trigger deployment
echo "Triggering deployment..."
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d "{\"uuid\": \"$APP_UUID\", \"force\": false}"

# Step 3: Monitor deployment
echo "Monitoring deployment (max 5 minutes)..."
for i in {1..30}; do
  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$APP_UUID" | jq -r '.status')

  echo "[$i/30] Status: $status"

  if [[ "$status" == "running:healthy" ]]; then
    echo "✅ Deployment successful!"
    exit 0
  elif [[ "$status" == "exited"* ]] || [[ "$status" == *"unhealthy"* ]]; then
    echo "❌ Deployment failed!"
    echo "Fetching logs..."
    curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
      "$COOLIFY_API_URL/applications/$APP_UUID/logs" | tail -50
    exit 1
  fi

  sleep 10
done

echo "⚠️  Deployment timeout - check manually"
exit 1
```

### Deploy Multiple Applications

Deploy all apps from specific repository:

```bash
#!/bin/bash
REPO="claimate/cc-ask-a-genie"

echo "Deploying all apps from $REPO..."

# Get all app UUIDs for repo
uuids=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg repo "$REPO" \
    '.[] | select(.git_repository == $repo) | .uuid')

# Deploy each
for uuid in $uuids; do
  app_name=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid" | jq -r '.name')

  echo "\n🚀 Deploying $app_name ($uuid)..."

  curl -s -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    -H "Content-Type: application/json" \
    "$COOLIFY_API_URL/deploy" \
    -d "{\"uuid\": \"$uuid\", \"force\": false}"

  echo "Started deployment for $app_name"
  sleep 2
done

echo "\n✅ All deployments triggered"
echo "Monitor progress with: /coolify status"
```

### Deploy Specific Branch

Deploy all dev/test/prod environments:

```bash
#!/bin/bash
BRANCH="dev"

echo "Deploying all $BRANCH branch applications..."

curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg branch "$BRANCH" \
    '.[] | select(.git_branch == $branch) | .uuid' | \
while read -r uuid; do
  app_name=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid" | jq -r '.name')

  echo "Deploying $app_name..."
  curl -s -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    -H "Content-Type: application/json" \
    "$COOLIFY_API_URL/deploy" \
    -d "{\"uuid\": \"$uuid\", \"force\": false}"

  sleep 2
done
```

## Monitoring Workflows

### Real-Time Status Dashboard

Monitor all applications in real-time:

```bash
#!/bin/bash
# Run with: watch -n 5 ./status-dashboard.sh

clear
echo "=== Coolify Status Dashboard ==="
echo "Updated: $(date)"
echo ""

# Healthy apps
echo "✅ Running Healthy:"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status == "running:healthy") | "  - \(.name)"'

echo ""

# Unhealthy apps
echo "⚠️  Unhealthy:"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status | contains("unhealthy")) | "  - \(.name): \(.status)"'

echo ""

# Deploying
echo "🚀 Deploying:"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status | contains("deploying")) | "  - \(.name)"'

echo ""
echo "Total Apps: $(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | jq 'length')"
```

### Log Monitoring

Tail logs for specific application:

```bash
#!/bin/bash
APP_NAME="ask-a-genie-dev"

# Get UUID
uuid=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg name "$APP_NAME" '.[] | select(.name | contains($name)) | .uuid')

if [ -z "$uuid" ]; then
  echo "App not found: $APP_NAME"
  exit 1
fi

echo "Logs for $APP_NAME ($uuid):"
echo "========================================"

# Poll logs every 5 seconds
while true; do
  curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid/logs" | tail -20
  sleep 5
  clear
done
```

## Maintenance Workflows

### Restart All Unhealthy Applications

Automated recovery:

```bash
#!/bin/bash
# See scripts/restart.sh for full implementation

echo "Finding unhealthy applications..."

unhealthy=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status | contains("unhealthy")) |
    "\(.uuid)|\(.name)|\(.status)"')

if [ -z "$unhealthy" ]; then
  echo "✅ No unhealthy applications found"
  exit 0
fi

echo "Found unhealthy applications:"
echo "$unhealthy" | column -t -s '|'
echo ""

# Confirm before restart
read -p "Restart all? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Restart each
echo "$unhealthy" | while IFS='|' read -r uuid name status; do
  echo "Restarting $name..."

  curl -s -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid/restart"

  sleep 3

  # Check new status
  new_status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid" | jq -r '.status')

  echo "  New status: $new_status"
done

echo "\n✅ Restart complete"
```

### Update Environment Variables

Bulk update env vars across apps:

```bash
#!/bin/bash
APP_UUID="your-app-uuid"

# Add/update multiple env vars
curl -s -X PUT \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/$APP_UUID/envs/bulk" \
  -d '{
    "env_variables": [
      {"key": "NODE_ENV", "value": "production"},
      {"key": "LOG_LEVEL", "value": "info"},
      {"key": "API_VERSION", "value": "v2"}
    ]
  }'

echo "Environment variables updated"
echo "Redeploy to apply changes: /coolify deploy $APP_UUID"
```

### Scheduled Maintenance

Stop → Update → Start workflow:

```bash
#!/bin/bash
APP_UUID="your-app-uuid"

echo "Starting maintenance for $APP_UUID..."

# Step 1: Stop application
echo "Stopping application..."
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$APP_UUID/stop"

sleep 10

# Step 2: Update configuration (example: env vars)
echo "Updating configuration..."
curl -s -X PUT \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/$APP_UUID/envs/bulk" \
  -d '{"env_variables": [{"key": "MAINTENANCE", "value": "false"}]}'

# Step 3: Start application
echo "Starting application..."
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$APP_UUID/start"

echo "Waiting for healthy status..."
for i in {1..12}; do
  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$APP_UUID" | jq -r '.status')

  echo "[$i] Status: $status"

  if [[ "$status" == "running:healthy" ]]; then
    echo "✅ Maintenance complete!"
    exit 0
  fi

  sleep 5
done

echo "⚠️  Application not healthy - check manually"
```

## Troubleshooting Workflows

### Debug Deployment Failure

Complete debugging workflow:

```bash
#!/bin/bash
APP_NAME="failing-app"

echo "Debugging $APP_NAME..."

# Get app details
APP_DATA=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg name "$APP_NAME" '.[] | select(.name | contains($name))')

uuid=$(echo "$APP_DATA" | jq -r '.uuid')

echo "Application: $uuid"
echo "Status: $(echo "$APP_DATA" | jq -r '.status')"
echo "Branch: $(echo "$APP_DATA" | jq -r '.git_branch')"
echo "Last online: $(echo "$APP_DATA" | jq -r '.last_online_at')"
echo ""

# Get recent logs
echo "Recent logs:"
echo "========================================"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$uuid/logs" | tail -50

echo ""
echo "========================================"

# Check environment variables
echo "Environment variables:"
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$uuid/envs" | \
  jq -r '.[] | "  \(.key)=\(.value | tostring | .[0:20])..."'

echo ""

# Try restarting
read -p "Try restarting? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Restarting..."
  curl -s -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid/restart"

  echo "Wait 30s and check logs again"
fi
```

### Check API Connectivity

Verify API access and permissions:

```bash
#!/bin/bash

echo "Testing Coolify API connectivity..."

# Test 1: Health check
echo "1. Health check..."
health=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/health")

if [ "$health" = "OK" ]; then
  echo "✅ API is reachable"
else
  echo "❌ API health check failed: $health"
  exit 1
fi

# Test 2: List applications (read permission)
echo "2. Testing read permission..."
apps=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

http_code=$(echo "$apps" | tail -n1)

if [ "$http_code" -eq 200 ]; then
  count=$(echo "$apps" | sed '$d' | jq 'length')
  echo "✅ Read permission OK ($count applications found)"
else
  echo "❌ Read permission failed (HTTP $http_code)"
  echo "$apps" | sed '$d'
  exit 1
fi

# Test 3: Check SSH tunnel (if using remote)
if [[ "$COOLIFY_API_URL" == *"localhost"* ]]; then
  echo "3. Checking SSH tunnel..."
  tunnel=$(ps aux | grep "ssh.*8000" | grep -v grep)

  if [ -n "$tunnel" ]; then
    echo "✅ SSH tunnel is active"
  else
    echo "❌ SSH tunnel not found"
    echo "Start with: ssh -i ~/.ssh/coolify-vm -f -N -L 8000:localhost:8000 vm-claimate-coolify@172.201.24.5"
  fi
fi

echo "\n✅ All checks passed"
```

## Advanced Workflows

### Blue-Green Deployment

Deploy new version alongside old:

```bash
#!/bin/bash
# Requires two app environments: blue (production) and green (staging)

BLUE_UUID="production-app-uuid"
GREEN_UUID="staging-app-uuid"

echo "🔵 Blue-Green Deployment"

# Step 1: Deploy to green (staging)
echo "Deploying to green environment..."
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d "{\"uuid\": \"$GREEN_UUID\", \"force\": false}"

# Step 2: Wait for green to be healthy
echo "Waiting for green deployment..."
for i in {1..30}; do
  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$GREEN_UUID" | jq -r '.status')

  if [[ "$status" == "running:healthy" ]]; then
    echo "✅ Green is healthy"
    break
  fi

  sleep 10
done

# Step 3: Manual verification
read -p "Verify green environment, then swap? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Deployment cancelled"
  exit 0
fi

# Step 4: Swap (in practice, update DNS/load balancer)
echo "Swapping blue ↔ green..."
echo "Update your load balancer/DNS to point to green"
echo "Blue UUID: $BLUE_UUID"
echo "Green UUID: $GREEN_UUID"
```

### Automated Rollback

Rollback to previous deployment:

```bash
#!/bin/bash
APP_UUID="your-app-uuid"

echo "Initiating rollback for $APP_UUID..."

# Get deployment history
echo "Fetching deployment history..."
deployments=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/deployments/applications/$APP_UUID")

# Show last 5 deployments
echo "$deployments" | jq -r '.[-5:] | .[] |
  "\(.id): \(.created_at) - \(.status)"'

read -p "Enter deployment ID to rollback to: " deploy_id

# Trigger redeploy to that commit
echo "Rolling back..."
# Note: Actual rollback depends on Coolify version
# May need to update git_commit_sha and redeploy

echo "⚠️  Manual rollback: Update git commit SHA to previous version and redeploy"
```

## Tips and Best Practices

### 1. Always Use Scripts for Complex Operations

Store frequently-used workflows as scripts in `scripts/` directory.

### 2. Add Confirmation for Destructive Operations

```bash
read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 0
fi
```

### 3. Log All Operations

```bash
LOG_FILE="/var/log/coolify-operations.log"
echo "[$(date)] Deployed $APP_NAME" >> "$LOG_FILE"
```

### 4. Use Timeouts for Long Operations

```bash
timeout 300 ./deploy-script.sh || echo "Operation timed out"
```

### 5. Validate Before Execute

```bash
# Check app exists
if [ -z "$APP_UUID" ]; then
  echo "Error: App not found"
  exit 1
fi

# Check API is reachable
if ! curl -s "$COOLIFY_API_URL/health" | grep -q "OK"; then
  echo "Error: API not reachable"
  exit 1
fi
```

## Next Steps

- See `API_REFERENCE.md` for complete API documentation
- See `scripts/` directory for ready-to-use utility scripts
- See `SKILL.md` for quick reference
