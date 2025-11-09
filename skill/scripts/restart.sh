#!/usr/bin/env bash
#
# restart.sh - Restart Coolify applications
#
# Usage: ./restart.sh APP_NAME
#        ./restart.sh --all-unhealthy
#
# Examples:
#   ./restart.sh "ask-a-genie-dev"
#   ./restart.sh --all-unhealthy

set -euo pipefail

# Source environment setup helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env-setup.sh"

# Setup credentials (will prompt if not set)
setup_coolify_env || exit 1

# Function to restart single application
restart_app() {
  local uuid=$1
  local name=$2

  echo "Restarting: $name ($uuid)"

  response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid/restart")

  http_code=$(echo "$response" | tail -n1)

  if [ "$http_code" -ne 200 ] && [ "$http_code" -ne 201 ]; then
    echo "  ❌ Failed (HTTP $http_code)"
    return 1
  fi

  echo "  ✅ Restart triggered"

  # Wait for status change
  sleep 5

  for i in {1..12}; do
    status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
      "$COOLIFY_API_URL/applications/$uuid" | jq -r '.status')

    echo "  [$i/12] Status: $status"

    if [[ "$status" == "running:healthy" ]]; then
      echo "  ✅ Application healthy"
      return 0
    fi

    sleep 5
  done

  echo "  ⚠️  Timeout waiting for healthy status"
  return 1
}

# Parse arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 APP_NAME"
  echo "       $0 --all-unhealthy"
  exit 1
fi

if [ "$1" = "--all-unhealthy" ]; then
  # Restart all unhealthy applications
  echo "Finding unhealthy applications..."

  apps=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications")

  unhealthy=$(echo "$apps" | jq -r \
    '.[] | select(.status | contains("unhealthy")) | "\(.uuid)|\(.name)"')

  if [ -z "$unhealthy" ]; then
    echo "✅ No unhealthy applications found"
    exit 0
  fi

  echo "Found unhealthy applications:"
  echo "$unhealthy" | while IFS='|' read -r uuid name; do
    echo "  - $name ($uuid)"
  done
  echo ""

  # Confirm
  read -p "Restart all unhealthy apps? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
  fi

  # Restart each
  success=0
  failed=0

  echo "$unhealthy" | while IFS='|' read -r uuid name; do
    if restart_app "$uuid" "$name"; then
      ((success++)) || true
    else
      ((failed++)) || true
    fi
    echo ""
  done

  echo "Summary: $success succeeded, $failed failed"

else
  # Restart single application
  APP_NAME="$1"

  echo "Finding application: $APP_NAME"

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

  echo "Found: $APP_UUID"
  echo "Current status: $CURRENT_STATUS"
  echo ""

  restart_app "$APP_UUID" "$APP_NAME"
fi
