# Coolify Skill - Quick Start Guide

## TL;DR

We're building a Claude Code skill to manage Coolify deployments. Here's what you need to know.

## What We Learned

### ✅ Best Practices
- Keep SKILL.md under 500 lines
- Use gerund naming: `coolify` (or `managing-coolify`)
- Description: third-person, include triggers
- Progressive disclosure: main instructions in SKILL.md, details in separate files
- Provide checklists for multi-step operations

### ✅ Coolify API
- Authentication: `Bearer <token>` in Authorization header
- Base URL: `https://YOUR_COOLIFY_URL/api/v1`
- Main endpoints:
  - `/applications` - List apps
  - `/applications/public` - Deploy public repo
  - `/applications/{uuid}/start|stop|restart` - Control apps
  - `/applications/{uuid}/logs` - View logs
  - `/databases` - Manage databases

### ✅ Your Setup
- VM: 172.201.24.5
- SSH: `ssh coolify` (alias configured)
- Need: API token from Coolify dashboard
- Need: Confirm Coolify URL

## MVP Scope (2-3 hours)

**5 Core Operations:**
1. List applications
2. Deploy application (public repo)
3. Start/stop/restart application
4. View logs
5. Check status

**One File:**
```
coolify/SKILL.md
```

## Implementation Pattern

```bash
# All operations use:
curl -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
     "$COOLIFY_API_URL/endpoint"
```

## Next Actions

1. **Get API Token** (5 min)
   ```bash
   ssh coolify
   # Open Coolify dashboard
   # Settings > Keys & Tokens > Create token
   ```

2. **Test API** (5 min)
   ```bash
   export COOLIFY_API_TOKEN="your-token"
   export COOLIFY_API_URL="http://172.201.24.5/api/v1"
   curl -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
        "$COOLIFY_API_URL/applications"
   ```

3. **Create SKILL.md** (1 hour)
   - Copy template structure
   - Add 5 core operations
   - Include error handling
   - Add configuration instructions

4. **Test** (30 min)
   - Install: `~/.claude/skills/coolify/`
   - Test each operation
   - Fix issues

5. **Iterate** (ongoing)
   - Add features as needed
   - Improve based on usage

## MCP Server - How It Helps

The existing Coolify MCP server (https://github.com/FelixAllistar/coolify-mcp) gives us:
- ✅ Complete API endpoint list
- ✅ Authentication patterns
- ✅ Request/response examples
- ✅ Parameter validation rules
- ✅ Error handling patterns

We DON'T need to:
- ❌ Install the MCP server
- ❌ Use Node.js/TypeScript
- ❌ Run persistent process

We're building a simpler, bash/curl-based skill that:
- ✅ Uses same API endpoints
- ✅ Runs on-demand only
- ✅ Lives in `.claude/skills/`
- ✅ Works with Claude Code directly

## File Structure

**MVP:**
```
coolify/
└── SKILL.md
```

**Phase 2:**
```
coolify/
├── SKILL.md              # Core operations
├── API_REFERENCE.md      # Complete API docs
├── EXAMPLES.md           # Workflows
└── scripts/
    ├── deploy-app.sh
    └── check-health.sh
```

## Key Decisions

### ✅ Decided:
- Skill approach (not MCP server)
- Bash/curl implementation
- Progressive disclosure pattern
- MVP scope

### ❓ Need to Confirm:
- Coolify API URL (http vs https)
- API token permissions needed
- SSL certificate setup

## Success Metrics

**MVP Done When:**
- [ ] Can list apps
- [ ] Can deploy app
- [ ] Can control apps (start/stop/restart)
- [ ] Can view logs
- [ ] Errors are clear

**Ready for Phase 2 When:**
- [ ] MVP tested thoroughly
- [ ] Community feedback positive
- [ ] Need for advanced features confirmed

## Estimated Timeline

- ✅ Research: Complete
- ⏳ API setup: 10 minutes
- ⏳ SKILL.md creation: 60 minutes
- ⏳ Testing: 30 minutes
- ⏳ Polish: 30 minutes

**Total: ~2 hours to working skill**

## Resources

- [Full Plan](./PLAN.md) - Comprehensive implementation plan
- [Coolify MCP](https://github.com/FelixAllistar/coolify-mcp) - API reference
- [Skills Docs](https://docs.claude.com/en/docs/agents-and-tools/agent-skills) - Official docs
- [skill-builder](https://github.com/metaskills/skill-builder) - Best practices
