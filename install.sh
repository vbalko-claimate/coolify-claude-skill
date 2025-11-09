#!/usr/bin/env bash
#
# Coolify Claude Skill - Interactive Installer
#
# This script will guide you through the installation and configuration
# of the Coolify Claude Skill.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "\n${BLUE}==>${NC} $1"; }

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Ask yes/no question
ask_yes_no() {
  while true; do
    read -p "$1 (y/n): " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes (y) or no (n).";;
    esac
  done
}

# Main installation
main() {
  clear
  echo "╔════════════════════════════════════════════════╗"
  echo "║   Coolify Claude Skill - Interactive Setup    ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""
  print_info "This installer will help you set up the Coolify Claude Skill."
  echo ""

  # Step 1: Check prerequisites
  print_step "[1/6] Checking prerequisites..."

  # Check curl
  if command_exists curl; then
    print_success "curl is installed"
  else
    print_error "curl is not installed"
    echo "Please install curl first: brew install curl"
    exit 1
  fi

  # Check jq
  if command_exists jq; then
    print_success "jq is installed"
  else
    print_warning "jq is not installed (recommended for JSON parsing)"
    if ask_yes_no "Install jq now?"; then
      if command_exists brew; then
        brew install jq
        print_success "jq installed"
      else
        print_error "Homebrew not found. Please install jq manually."
        exit 1
      fi
    else
      print_warning "Continuing without jq (some features may not work)"
    fi
  fi

  # Check git
  if ! command_exists git; then
    print_error "git is not installed"
    echo "Please install git first: brew install git"
    exit 1
  fi
  print_success "git is installed"

  # Step 2: Determine installation directory
  print_step "[2/6] Setting up installation directory..."

  SKILL_DIR="$HOME/.claude/skills/coolify"

  if [ -d "$SKILL_DIR" ]; then
    print_warning "Coolify skill is already installed at: $SKILL_DIR"
    if ask_yes_no "Reinstall (this will overwrite existing files)?"; then
      rm -rf "$SKILL_DIR"
      print_info "Removed existing installation"
    else
      print_info "Keeping existing installation"
      SKILL_DIR="$SKILL_DIR"
    fi
  fi

  mkdir -p "$HOME/.claude/skills"
  print_success "Skills directory ready: $HOME/.claude/skills"

  # Step 3: Clone or copy skill
  print_step "[3/6] Installing skill files..."

  if [ -f "$(dirname "$0")/skill/SKILL.md" ]; then
    # Running from repo directory
    print_info "Installing from local repository..."
    cp -R "$(dirname "$0")/skill" "$SKILL_DIR"
    print_success "Skill files copied to $SKILL_DIR"
  else
    # Clone from GitHub
    print_info "Cloning from GitHub..."
    TEMP_DIR=$(mktemp -d)
    git clone https://github.com/vbalko-claimate/coolify-claude-skill.git "$TEMP_DIR"
    mkdir -p "$SKILL_DIR"
    cp -R "$TEMP_DIR/skill/"* "$SKILL_DIR/"
    rm -rf "$TEMP_DIR"
    print_success "Skill cloned from GitHub"
  fi

  # Make scripts executable
  chmod +x "$SKILL_DIR/scripts/"*.sh
  print_success "Scripts are executable"

  # Step 4: Configure Coolify connection
  print_step "[4/6] Configuring Coolify connection..."

  echo ""
  print_info "Do you need to connect to a remote Coolify instance via SSH tunnel?"
  if ask_yes_no "Set up SSH tunnel?"; then
    echo ""
    read -p "Enter SSH host (e.g., user@server.com): " SSH_HOST
    read -p "Enter SSH key path (default: ~/.ssh/id_rsa): " SSH_KEY
    SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
    read -p "Enter local port for tunnel (default: 8000): " LOCAL_PORT
    LOCAL_PORT=${LOCAL_PORT:-8000}

    print_info "Starting SSH tunnel..."
    ssh -i "$SSH_KEY" -f -N -L "$LOCAL_PORT:localhost:8000" "$SSH_HOST" 2>/dev/null || {
      print_warning "SSH tunnel may already be running or failed to start"
    }

    # Check if tunnel is running
    if ps aux | grep -v grep | grep "ssh.*$LOCAL_PORT.*$SSH_HOST" >/dev/null; then
      print_success "SSH tunnel is active"
      API_URL="http://localhost:$LOCAL_PORT/api/v1"
    else
      print_error "SSH tunnel failed to start"
      echo "Please start it manually:"
      echo "  ssh -i $SSH_KEY -f -N -L $LOCAL_PORT:localhost:8000 $SSH_HOST"
      exit 1
    fi
  else
    echo ""
    read -p "Enter Coolify API URL (e.g., http://localhost:8000/api/v1): " API_URL
  fi

  # Test API connectivity
  print_info "Testing API connectivity..."
  if curl -s -m 5 "$API_URL/health" >/dev/null 2>&1; then
    print_success "API is reachable"
  else
    print_error "Cannot reach API at $API_URL"
    echo "Please check your Coolify instance and try again."
    exit 1
  fi

  # Step 5: Configure API token
  print_step "[5/6] Configuring API token..."

  echo ""
  print_info "You need a Coolify API token with read, write, and deploy permissions."
  echo ""
  echo "To get a token:"
  echo "  1. Open Coolify dashboard in your browser"
  echo "  2. Go to Settings → Keys & Tokens → API"
  echo "  3. Click 'Create API Token'"
  echo "  4. Enable permissions: read, write, deploy"
  echo "  5. Copy the token (shown only once!)"
  echo ""

  read -p "Enter your Coolify API token: " API_TOKEN

  if [ -z "$API_TOKEN" ]; then
    print_error "API token cannot be empty"
    exit 1
  fi

  # Test API token
  print_info "Testing API token..."
  response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $API_TOKEN" \
    "$API_URL/applications" 2>/dev/null)

  http_code=$(echo "$response" | tail -n1)

  if [ "$http_code" -eq 200 ]; then
    app_count=$(echo "$response" | sed '$d' | jq 'length' 2>/dev/null || echo "?")
    print_success "API token is valid ($app_count applications found)"
  elif [ "$http_code" -eq 401 ]; then
    print_error "API token is invalid (401 Unauthorized)"
    exit 1
  elif [ "$http_code" -eq 403 ]; then
    print_error "API token lacks required permissions (403 Forbidden)"
    echo "Please ensure your token has read, write, and deploy permissions"
    exit 1
  else
    print_warning "Unexpected response (HTTP $http_code)"
    if ! ask_yes_no "Continue anyway?"; then
      exit 1
    fi
  fi

  # Create .env file
  print_info "Creating configuration file..."
  cat > "$SKILL_DIR/.env" <<EOF
# Coolify API Configuration
# Generated by install.sh on $(date)

# API Token from Coolify Settings > Keys & Tokens
COOLIFY_API_TOKEN=$API_TOKEN

# API URL - accessed via SSH tunnel or direct connection
COOLIFY_API_URL=$API_URL

# SSH Configuration (if applicable)
${SSH_HOST:+COOLIFY_SSH_HOST=$SSH_HOST}
${SSH_KEY:+COOLIFY_SSH_KEY=$SSH_KEY}
EOF

  chmod 600 "$SKILL_DIR/.env"
  print_success "Configuration saved to $SKILL_DIR/.env"

  # Step 6: Verify installation
  print_step "[6/6] Verifying installation..."

  # Export environment variables
  export COOLIFY_API_TOKEN="$API_TOKEN"
  export COOLIFY_API_URL="$API_URL"

  # Run health check
  print_info "Running health check..."
  if bash "$SKILL_DIR/scripts/health-check.sh" 2>&1 | grep -q "API is healthy"; then
    print_success "Health check passed"
  else
    print_warning "Health check reported issues (this may be normal if some apps are unhealthy)"
  fi

  # Installation complete
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║         Installation Complete! 🎉             ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""
  print_success "Coolify Claude Skill is ready to use!"
  echo ""
  echo "Quick Start:"
  echo "  • List applications:  bash $SKILL_DIR/scripts/list-apps.sh"
  echo "  • Health check:       bash $SKILL_DIR/scripts/health-check.sh"
  echo "  • Deploy app:         bash $SKILL_DIR/scripts/deploy.sh \"app-name\""
  echo ""
  echo "Environment Variables:"
  echo "  Add these to your ~/.zshrc or ~/.bashrc:"
  echo "    export COOLIFY_API_TOKEN=\"$API_TOKEN\""
  echo "    export COOLIFY_API_URL=\"$API_URL\""
  echo ""
  if ask_yes_no "Add environment variables to ~/.zshrc now?"; then
    echo "" >> ~/.zshrc
    echo "# Coolify Claude Skill Configuration" >> ~/.zshrc
    echo "export COOLIFY_API_TOKEN=\"$API_TOKEN\"" >> ~/.zshrc
    echo "export COOLIFY_API_URL=\"$API_URL\"" >> ~/.zshrc
    source ~/.zshrc 2>/dev/null || true
    print_success "Environment variables added to ~/.zshrc"
  fi

  echo ""
  echo "Documentation:"
  echo "  • Skill overview:     $SKILL_DIR/SKILL.md"
  echo "  • API reference:      $SKILL_DIR/API_REFERENCE.md"
  echo "  • Examples:           $SKILL_DIR/EXAMPLES.md"
  echo ""
  echo "For help, visit: https://github.com/vbalko-claimate/coolify-claude-skill"
  echo ""
}

# Run main installation
main "$@"
