#!/usr/bin/env bash
#
# Coolify Claude Skill - Interactive Uninstaller
#
# This script will remove the Coolify Claude Skill from your system.

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

main() {
  clear
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Coolify Claude Skill - Uninstaller           ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  SKILL_DIR="$HOME/.claude/skills/coolify"

  # Check if skill is installed
  if [ ! -d "$SKILL_DIR" ]; then
    print_error "Coolify skill is not installed at: $SKILL_DIR"
    exit 1
  fi

  print_warning "This will remove the Coolify Claude Skill from your system."
  echo ""
  echo "The following will be removed:"
  echo "  • Skill directory: $SKILL_DIR"
  echo "  • All scripts and documentation"
  echo "  • Configuration file (.env)"
  echo ""
  echo "The following will NOT be removed:"
  echo "  • Environment variables in ~/.zshrc or ~/.bashrc"
  echo "  • SSH tunnels (you'll need to stop them manually)"
  echo "  • Coolify API tokens (manage in Coolify dashboard)"
  echo ""

  if ! ask_yes_no "Are you sure you want to uninstall?"; then
    print_info "Uninstallation cancelled"
    exit 0
  fi

  echo ""
  print_info "Removing Coolify skill..."

  # Backup .env if exists
  if [ -f "$SKILL_DIR/.env" ]; then
    if ask_yes_no "Backup .env file before removal?"; then
      BACKUP_FILE="$HOME/coolify-skill-env-backup-$(date +%Y%m%d-%H%M%S).txt"
      cp "$SKILL_DIR/.env" "$BACKUP_FILE"
      print_success "Configuration backed up to: $BACKUP_FILE"
    fi
  fi

  # Remove skill directory
  rm -rf "$SKILL_DIR"

  if [ ! -d "$SKILL_DIR" ]; then
    print_success "Skill removed successfully"
  else
    print_error "Failed to remove skill directory"
    exit 1
  fi

  echo ""
  print_info "Checking for environment variables..."

  # Check for env vars in shell config
  if grep -q "COOLIFY_API_TOKEN" ~/.zshrc 2>/dev/null || \
     grep -q "COOLIFY_API_TOKEN" ~/.bashrc 2>/dev/null; then
    print_warning "Environment variables found in shell configuration"
    if ask_yes_no "Remove environment variables from ~/.zshrc?"; then
      # Remove Coolify env vars from zshrc
      if [ -f ~/.zshrc ]; then
        sed -i.bak '/# Coolify Claude Skill/d' ~/.zshrc
        sed -i.bak '/COOLIFY_API_TOKEN/d' ~/.zshrc
        sed -i.bak '/COOLIFY_API_URL/d' ~/.zshrc
        rm -f ~/.zshrc.bak
        print_success "Environment variables removed from ~/.zshrc"
        print_info "Run 'source ~/.zshrc' to apply changes"
      fi
    fi
  fi

  # Check for running SSH tunnels
  print_info "Checking for SSH tunnels..."
  if ps aux | grep -v grep | grep "ssh.*8000" >/dev/null; then
    print_warning "SSH tunnel to port 8000 is still running"
    if ask_yes_no "Stop SSH tunnel?"; then
      pkill -f "ssh.*8000" 2>/dev/null || true
      print_success "SSH tunnel stopped"
    else
      print_info "SSH tunnel left running"
      echo "To stop manually: pkill -f 'ssh.*8000'"
    fi
  fi

  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║      Uninstallation Complete                  ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""
  print_success "Coolify Claude Skill has been removed"
  echo ""
  print_info "To reinstall, run:"
  echo "  curl -fsSL https://raw.githubusercontent.com/vbalko-claimate/coolify-claude-skill/master/install.sh | bash"
  echo ""
  print_info "Thank you for using Coolify Claude Skill!"
  echo ""
}

main "$@"
