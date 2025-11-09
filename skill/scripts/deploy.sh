#!/usr/bin/env bash
#
# deploy.sh - Deploy Coolify application with monitoring
#
# Usage: ./deploy.sh APP_NAME [--force]
#
# Examples:
#   ./deploy.sh "ask-a-genie-dev"
#   ./deploy.sh "claistat" --force

set -euo pipefail

# Check arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 APP_NAME [--force]"
  echo ""
  echo "Examples:"
  echo "  $0 \"ask-a-genie-dev\""
  echo "  $0 \"claistat\" --force"
  exit 1
fi

APP_NAME="$1"
FORCE=false

if [ "${2:-}" = "--force" ]; then
  FORCE=true
fi

# Check required environment variables
if [ -z "${COOLIFY_API_TOKEN:-}" ]; then
  echo "Error: COOLIFY_API_TOKEN not set"
  exit 1
fi

if [ -z "${COOLIFY_API_URL:-}" ]; then
  echo "Error: COOLIFY_API_URL not set"
  exit 1
fi

echo "🚀 Deploying application: $APP_NAME"
echo "Force rebuild: $FORCE"
echo ""

# Step 1: Find application
echo "[1/4] Finding application..."
apps=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

app_data=$(echo "$apps" | jq -r --arg name "$APP_NAME" \
  '.[] | select(.name | contains($name))')

if [ -z "$app_data" ]; then
  echo "❌ Application not found: $APP_NAME"
  echo ""
  echo "Available applications:"
  echo "$apps" | jq -r '.[].name'
  exit 1
fi

APP_UUID=$(echo "$app_data" | jq -r '.uuid')
CURRENT_STATUS=$(echo "$app_data" | jq -r '.status')

echo "   Found: $APP_UUID"
echo "   Current status: $CURRENT_STATUS"
echo ""

# Step 2: Trigger deployment
echo "[2/4] Triggering deployment..."
deploy_response=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d "{\"uuid\": \"$APP_UUID\", \"force\": $FORCE}")

deploy_code=$(echo "$deploy_response" | tail -n1)

if [ "$deploy_code" -ne 200 ] && [ "$deploy_code" -ne 201 ]; then
  echo "❌ Deployment trigger failed (HTTP $deploy_code)"
  echo "$deploy_response" | sed '$d'
  exit 1
fi

echo "   Deployment triggered successfully"
echo ""

# Step 3: Monitor deployment
echo "[3/4] Monitoring deployment (max 5 minutes)..."
START_TIME=$(date +%s)
MAX_WAIT=300  # 5 minutes
CHECK_INTERVAL=10

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))

  if [ $ELAPSED -gt $MAX_WAIT ]; then
    echo ""
    echo "⚠️  Deployment timeout after 5 minutes"
    echo "   Check status manually with: ./list-apps.sh"
    exit 1
  fi

  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$APP_UUID" | jq -r '.status')

  progress=$((ELAPSED * 100 / MAX_WAIT))
  echo "   [$ELAPSED s] Status: $status (${progress}%)"

  # Check for success
  if [[ "$status" == "running:healthy" ]]; then
    echo ""
    echo "✅ Deployment successful!"
    break
  fi

  # Check for failure
  if [[ "$status" == "exited"* ]] || [[ "$status" == *"unhealthy"* && $ELAPSED -gt 60 ]]; then
    echo ""
    echo "❌ Deployment failed with status: $status"
    echo ""
    echo "Fetching recent logs..."
    curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
      "$COOLIFY_API_URL/applications/$APP_UUID/logs" | tail -50
    exit 1
  fi

  sleep $CHECK_INTERVAL
done

# Step 4: Verify final status
echo ""
echo "[4/4] Verifying deployment..."
final_data=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$APP_UUID")

echo "   Application: $(echo "$final_data" | jq -r '.name')"
echo "   Status: $(echo "$final_data" | jq -r '.status')"
echo "   URL: $(echo "$final_data" | jq -r '.fqdn')"
echo "   Branch: $(echo "$final_data" | jq -r '.git_branch')"
echo ""
echo "🎉 Deployment complete!"
