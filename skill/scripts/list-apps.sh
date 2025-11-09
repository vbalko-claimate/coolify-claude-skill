#!/usr/bin/env bash
#
# list-apps.sh - List all Coolify applications
#
# Usage: ./list-apps.sh [--filter=STATUS]
#
# Examples:
#   ./list-apps.sh                    # List all apps
#   ./list-apps.sh --filter=unhealthy # List only unhealthy apps
#   ./list-apps.sh --json             # Output raw JSON

set -euo pipefail

# Source environment setup helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env-setup.sh"

# Setup credentials (will prompt if not set)
setup_coolify_env || exit 1

# Parse arguments
FILTER=""
JSON_OUTPUT=false

for arg in "$@"; do
  case $arg in
    --filter=*)
      FILTER="${arg#*=}"
      ;;
    --json)
      JSON_OUTPUT=true
      ;;
    --help)
      echo "Usage: $0 [--filter=STATUS] [--json]"
      echo ""
      echo "Options:"
      echo "  --filter=STATUS   Filter by status (e.g., unhealthy, healthy, running)"
      echo "  --json            Output raw JSON"
      echo "  --help            Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# Fetch applications
response=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error: API request failed (HTTP $http_code)"
  echo "$body"
  exit 1
fi

# Output JSON if requested
if [ "$JSON_OUTPUT" = true ]; then
  echo "$body"
  exit 0
fi

# Filter if requested
if [ -n "$FILTER" ]; then
  filtered=$(echo "$body" | jq -r --arg filter "$FILTER" \
    '.[] | select(.status | contains($filter)) |
     "\(.name)|\(.status)|\(.uuid)|\(.fqdn // "N/A")"')

  if [ -z "$filtered" ]; then
    echo "No applications found with filter: $FILTER"
    exit 0
  fi

  echo "Applications (filter: $FILTER):"
  echo "========================================"
  echo "NAME|STATUS|UUID|URL" | column -t -s '|'
  echo "$filtered" | column -t -s '|'
else
  # Show all
  echo "All Coolify Applications:"
  echo "========================================"
  echo "$body" | jq -r \
    '"NAME|STATUS|UUID|URL",
     (.[] | "\(.name)|\(.status)|\(.uuid)|\(.fqdn // "N/A")")' | \
    column -t -s '|'

  # Summary
  total=$(echo "$body" | jq 'length')
  healthy=$(echo "$body" | jq '[.[] | select(.status == "running:healthy")] | length')
  unhealthy=$(echo "$body" | jq '[.[] | select(.status | contains("unhealthy"))] | length')

  echo ""
  echo "Summary: $healthy healthy, $unhealthy unhealthy, $total total"
fi
