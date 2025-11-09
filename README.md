# Coolify Claude Skill

A production-ready Claude Code skill for managing Coolify deployments, applications, and infrastructure via API.

## Features

- 🚀 **Deploy & Monitor** - Deploy applications with automatic status monitoring
- 📊 **Health Checks** - Comprehensive health monitoring for all applications
- 🔄 **Lifecycle Management** - Start, stop, restart applications
- 📝 **Logs** - View application logs for debugging
- 🛠️ **Utility Scripts** - Production-ready bash scripts with error handling
- 📚 **Progressive Disclosure** - Concise overview with detailed docs when needed

## Installation

### One-Line Installer (Recommended)

Interactive installer that guides you through the setup:

```bash
curl -fsSL https://raw.githubusercontent.com/vbalko-claimate/coolify-claude-skill/master/install.sh | bash
```

Or download and run locally:

```bash
git clone https://github.com/vbalko-claimate/coolify-claude-skill.git
cd coolify-claude-skill
bash install.sh
```

The installer will:
- ✅ Check prerequisites (curl, jq, git)
- ✅ Install skill to `~/.claude/skills/coolify`
- ✅ Set up SSH tunnel (if needed)
- ✅ Test Coolify API connectivity
- ✅ Configure API token
- ✅ Run health check to verify installation
- ✅ Optionally add environment variables to shell config

### Manual Installation

If you prefer manual setup:

```bash
# 1. Clone repository
git clone https://github.com/vbalko-claimate/coolify-claude-skill.git ~/.claude/skills/coolify

# 2. Configure environment
cp ~/.claude/skills/coolify/.env.example ~/.claude/skills/coolify/.env
# Edit .env and add your Coolify API token and URL

# 3. Make scripts executable
chmod +x ~/.claude/skills/coolify/scripts/*.sh
```

### Prerequisites

- Claude Pro, Max, Team, or Enterprise subscription
- Access to Coolify instance
- Coolify API token (Settings → Keys & Tokens in Coolify dashboard)
- `curl` and `jq` installed (`brew install jq`)

### Configuration

1. Get Coolify API Token:
   - Open Coolify dashboard
   - Settings → Keys & Tokens → API
   - Create token with `read`, `write`, and `deploy` permissions

2. Set up SSH tunnel (if Coolify is remote):
   ```bash
   ssh -i ~/.ssh/your-key -f -N -L 8000:localhost:8000 user@coolify-server
   ```

3. Configure environment:
   ```bash
   export COOLIFY_API_TOKEN="your-token-here"
   export COOLIFY_API_URL="http://localhost:8000/api/v1"
   ```

## Usage

### With Claude Code

The skill activates automatically when you mention Coolify operations:

```
"List all Coolify applications"
"Deploy ask-a-genie to dev environment"
"Check health of Coolify applications"
"Restart unhealthy apps"
```

### Direct Script Usage

```bash
# List applications
bash ~/.claude/skills/coolify/scripts/list-apps.sh

# Deploy application
bash ~/.claude/skills/coolify/scripts/deploy.sh "app-name"

# Health check
bash ~/.claude/skills/coolify/scripts/health-check.sh

# Restart unhealthy apps
bash ~/.claude/skills/coolify/scripts/restart.sh --all-unhealthy
```

## Documentation

- **[SKILL.md](skill/SKILL.md)** - Quick reference and common operations
- **[API_REFERENCE.md](skill/API_REFERENCE.md)** - Complete API documentation
- **[EXAMPLES.md](skill/EXAMPLES.md)** - Real-world workflows and use cases
- **[PLAN.md](PLAN.md)** - Implementation plan and architecture
- **[QUICK_START.md](QUICK_START.md)** - Rapid development guide

## File Structure

```
coolify/
├── SKILL.md              # Main skill file (overview)
├── API_REFERENCE.md      # Complete API documentation
├── EXAMPLES.md           # Workflow examples
└── scripts/
    ├── list-apps.sh      # List applications
    ├── deploy.sh         # Deploy with monitoring
    ├── restart.sh        # Restart applications
    └── health-check.sh   # Health monitoring
```

## Best Practices

### 1. Use Scripts for Production

Scripts include error handling, status monitoring, and confirmations:

```bash
# ✅ Good - use scripts
bash ~/.claude/skills/coolify/scripts/deploy.sh "my-app"

# ❌ Avoid - raw API calls without monitoring
curl -X POST "$COOLIFY_API_URL/deploy"
```

### 2. Monitor Deployments

Never deploy without monitoring:

```bash
bash ~/.claude/skills/coolify/scripts/deploy.sh "app-name"
# Script automatically monitors until healthy or fails
```

### 3. Run Health Checks Regularly

```bash
# Run health check
bash ~/.claude/skills/coolify/scripts/health-check.sh

# Verbose output
bash ~/.claude/skills/coolify/scripts/health-check.sh --verbose
```

### 4. Keep API Token Secure

- Store in `.env` file (never commit)
- Use environment variables
- Rotate periodically
- Use minimum required permissions

## Examples

### Deploy Application

```bash
bash ~/.claude/skills/coolify/scripts/deploy.sh "ask-a-genie-dev"
```

Output:
```
🚀 Deploying application: ask-a-genie-dev
Force rebuild: false

[1/4] Finding application...
   Found: q88wc80gswgwg80o4swo004g
   Current status: running:healthy

[2/4] Triggering deployment...
   Deployment triggered successfully

[3/4] Monitoring deployment (max 5 minutes)...
   [10 s] Status: deploying (3%)
   [20 s] Status: deploying (6%)
   ...
   [120 s] Status: running:healthy (40%)

✅ Deployment successful!

[4/4] Verifying deployment...
   Application: claimate/cc-ask-a-genie:dev
   Status: running:healthy
   URL: https://ask-a-genie-dev.app.claimate.tech
   Branch: dev

🎉 Deployment complete!
```

### List Applications

```bash
bash ~/.claude/skills/coolify/scripts/list-apps.sh
```

Output:
```
All Coolify Applications:
========================================
NAME                          STATUS             UUID                      URL
claimate/cc-ask-a-genie:dev   running:healthy    q88wc80gswgwg80o4swo004g  https://ask-a-genie-dev.app.claimate.tech
claimate/cc-ask-a-genie:test  running:healthy    vkkswcwks8wc44000o40s888  https://ask-a-genie-test.app.claimate.tech

Summary: 2 healthy, 0 unhealthy, 2 total
```

### Health Check

```bash
bash ~/.claude/skills/coolify/scripts/health-check.sh
```

Output:
```
=== Coolify Health Check ===
Time: 2025-11-09 08:57:29

[1/4] Testing API health...
      ✅ API is healthy
[2/4] Testing API permissions...
      ✅ Read permission OK
[3/4] Checking SSH tunnel...
      ✅ SSH tunnel is active
[4/4] Checking application health...
      Total applications: 5
      ✅ Healthy: 2
      ⚠️  Unhealthy: 3

✅ All systems operational
```

## Uninstall

To remove the Coolify Claude Skill:

```bash
# Interactive uninstaller
curl -fsSL https://raw.githubusercontent.com/vbalko-claimate/coolify-claude-skill/master/uninstall.sh | bash

# Or manually
rm -rf ~/.claude/skills/coolify
# Remove environment variables from ~/.zshrc or ~/.bashrc
# Stop SSH tunnel: pkill -f 'ssh.*8000'
```

The uninstaller will:
- Remove skill directory
- Optionally backup .env file
- Optionally remove environment variables
- Optionally stop SSH tunnels

## Troubleshooting

### API Connection Issues

```bash
# Test API health
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/health"
# Should return: OK
```

### SSH Tunnel Not Active

```bash
# Check if tunnel is running
ps aux | grep "ssh.*8000"

# Start tunnel
ssh -i ~/.ssh/coolify-vm -f -N -L 8000:localhost:8000 user@coolify-server
```

### Permission Errors

Ensure your API token has required permissions:
- ✅ read - List and view resources
- ✅ write - Create and update resources
- ✅ deploy - Trigger deployments

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## Development

See [PLAN.md](PLAN.md) for:
- Implementation strategy
- Best practices research
- API structure
- Future enhancements

## License

MIT

## Resources

- **Coolify Documentation**: https://coolify.io/docs
- **Coolify API Reference**: https://app.coolify.io/api/documentation
- **Claude Skills Guide**: https://docs.claude.com/en/docs/agents-and-tools/agent-skills
- **GitHub Issues**: https://github.com/vbalko-claimate/coolify-claude-skill/issues

## Acknowledgments

- Built using Coolify API
- Follows Anthropic's Claude Skills best practices
- Inspired by the Coolify MCP server

---

**Made with ❤️ for the Coolify and Claude community**
