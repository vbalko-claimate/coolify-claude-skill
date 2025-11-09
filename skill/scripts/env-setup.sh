#!/usr/bin/env bash
#
# env-setup.sh - Helper for environment variable setup
#
# This function checks and sets up required Coolify credentials.
# Can be sourced by other scripts.

setup_coolify_env() {
  local is_interactive=false

  # Check if running in interactive terminal
  if [ -t 0 ]; then
    is_interactive=true
  fi

  # Check for API token
  if [ -z "${COOLIFY_API_TOKEN:-}" ]; then
    if [ "$is_interactive" = true ]; then
      echo "Coolify API token is not set."
      echo ""
      echo "To get a token:"
      echo "  1. Open Coolify dashboard (http://localhost:8000)"
      echo "  2. Go to Settings → Keys & Tokens → API"
      echo "  3. Click 'Create API Token'"
      echo "  4. Enable permissions: read, write, deploy"
      echo "  5. Copy the token (shown only once!)"
      echo ""
      read -p "Enter your Coolify API token: " COOLIFY_API_TOKEN

      if [ -z "$COOLIFY_API_TOKEN" ]; then
        echo "Error: API token cannot be empty"
        return 1
      fi

      export COOLIFY_API_TOKEN
    else
      echo "Error: COOLIFY_API_TOKEN environment variable is not set"
      echo ""
      echo "Please set it with:"
      echo "  export COOLIFY_API_TOKEN=\"your-token-here\""
      echo ""
      echo "Or run the install script to configure:"
      echo "  bash install.sh"
      return 1
    fi
  fi

  # Check for API URL
  if [ -z "${COOLIFY_API_URL:-}" ]; then
    if [ "$is_interactive" = true ]; then
      read -p "Enter Coolify API URL (default: http://localhost:8000/api/v1): " COOLIFY_API_URL
      COOLIFY_API_URL=${COOLIFY_API_URL:-http://localhost:8000/api/v1}
      export COOLIFY_API_URL
    else
      # Set default for non-interactive
      export COOLIFY_API_URL="http://localhost:8000/api/v1"
    fi
  fi

  return 0
}

# If script is sourced, just define the function
# If executed directly, run setup
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  setup_coolify_env
fi
