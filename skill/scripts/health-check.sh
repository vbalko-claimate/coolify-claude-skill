#!/usr/bin/env bash
#
# health-check.sh - Comprehensive health check for Coolify
#
# Usage: ./health-check.sh [--verbose]

set -euo pipefail

VERBOSE=false

if [ "${1:-}" = "--verbose" ]; then
  VERBOSE=true
fi

# Source environment setup helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env-setup.sh"

# Setup credentials (will prompt if not set)
setup_coolify_env || exit 1

echo "=== Coolify Health Check ==="
echo "Time: $(date)"
echo "API: $COOLIFY_API_URL"
echo ""

# Test 1: API Health
echo "[1/4] Testing API health..."
health=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/health")

health_code=$(echo "$health" | tail -n1)
health_body=$(echo "$health" | sed '$d')

if [ "$health_code" -eq 200 ] && [ "$health_body" = "OK" ]; then
  echo "      ✅ API is healthy"
else
  echo "      ❌ API health check failed (HTTP $health_code)"
  exit 1
fi

# Test 2: API Permissions
echo "[2/4] Testing API permissions..."
apps=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

apps_code=$(echo "$apps" | tail -n1)

if [ "$apps_code" -eq 200 ]; then
  echo "      ✅ Read permission OK"
else
  echo "      ❌ Read permission failed (HTTP $apps_code)"
  exit 1
fi

# Test 3: SSH Tunnel (if using localhost)
if [[ "$COOLIFY_API_URL" == *"localhost"* ]]; then
  echo "[3/4] Checking SSH tunnel..."
  tunnel=$(ps aux | grep "ssh.*8000" | grep -v grep || true)

  if [ -n "$tunnel" ]; then
    echo "      ✅ SSH tunnel is active"
  else
    echo "      ⚠️  SSH tunnel not found"
    echo "      Run: ssh -i ~/.ssh/coolify-vm -f -N -L 8000:localhost:8000 vm-claimate-coolify@172.201.24.5"
  fi
else
  echo "[3/4] Skipping SSH tunnel check (not using localhost)"
fi

# Test 4: Application Status
echo "[4/4] Checking application health..."

apps_body=$(echo "$apps" | sed '$d')

if [ -z "$apps_body" ] || [ "$apps_body" = "[]" ]; then
  echo "      ⚠️  No applications found"
else
  total=$(echo "$apps_body" | jq 'length')
  healthy=$(echo "$apps_body" | jq '[.[] | select(.status == "running:healthy")] | length')
  unhealthy=$(echo "$apps_body" | jq '[.[] | select(.status | contains("unhealthy"))] | length')
  exited=$(echo "$apps_body" | jq '[.[] | select(.status | startswith("exited"))] | length')

  echo "      Total applications: $total"
  echo "      ✅ Healthy: $healthy"

  if [ "$unhealthy" -gt 0 ]; then
    echo "      ⚠️  Unhealthy: $unhealthy"
  fi

  if [ "$exited" -gt 0 ]; then
    echo "      ❌ Exited: $exited"
  fi

  # Show details if verbose
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "Application Details:"
    echo "===================="
    echo "$apps_body" | jq -r \
      '"NAME|STATUS|BRANCH|URL",
       (.[] | "\(.name)|\(.status)|\(.git_branch)|\(.fqdn // "N/A")")' | \
      column -t -s '|'
  fi

  # List unhealthy if any
  if [ "$unhealthy" -gt 0 ] || [ "$exited" -gt 0 ]; then
    echo ""
    echo "⚠️  Unhealthy/Exited Applications:"
    echo "$apps_body" | jq -r \
      '.[] | select(.status | (contains("unhealthy") or startswith("exited"))) |
       "  - \(.name): \(.status)"'
  fi
fi

echo ""
echo "=== Health Check Complete ==="

# Exit code based on unhealthy apps
if [ "${unhealthy:-0}" -gt 0 ] || [ "${exited:-0}" -gt 0 ]; then
  echo "⚠️  Some applications are not healthy"
  exit 1
else
  echo "✅ All systems healthy"
  exit 0
fi
