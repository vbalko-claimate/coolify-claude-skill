# Coolify Claude Skill - Implementation Plan

## Executive Summary

Creating a Claude Code skill for Coolify deployment management using best practices from:
- Official Anthropic Skills documentation
- metaskills/skill-builder patterns
- Coolify MCP server API implementation
- anthropics/skills examples

## Research Findings

### 1. Claude Skills Best Practices

**Core Principles:**
- **Conciseness**: Keep SKILL.md under 500 lines
- **Progressive Disclosure**: SKILL.md is overview, detailed docs go in separate files
- **Multi-Model Testing**: Test with Haiku, Sonnet, and Opus
- **Degrees of Freedom**: Match specificity to task fragility

**YAML Frontmatter Requirements:**
```yaml
---
name: skill-name  # Max 64 chars, lowercase/numbers/hyphens only
description: Third-person description with capabilities and triggers. Max 1024 chars.
---
```

**Naming Conventions:**
- Use gerund form (verb + -ing): `deploying-apps`, `managing-databases`
- Avoid: `helper`, `utils`, vague names

**Description Writing:**
- Third person only
- Include both capabilities AND usage triggers
- Good: "Manages Coolify deployments and infrastructure. Use when deploying apps, managing databases, or controlling services on Coolify."
- Bad: "I can help you with Coolify" or "Coolify helper"

**Content Guidelines:**
- Avoid time-sensitive information
- Consistent terminology throughout
- Provide concrete templates and examples
- Break complex operations into numbered steps with checklists
- Include validation steps for critical operations

**File Structure Pattern:**
```
coolify/
├── SKILL.md              # Metadata + overview (main instructions)
├── API_REFERENCE.md      # Detailed API documentation
├── EXAMPLES.md           # Common workflows and examples
└── scripts/
    ├── deploy.sh         # Deployment automation
    └── validate.sh       # Configuration validation
```

**Anti-Patterns to Avoid:**
- Windows paths (use forward slashes)
- Too many options (provide one default with escape hatches)
- Assumed tools (provide installation instructions)
- Deeply nested references (keep one level from SKILL.md)
- Magic constants (justify all values)

### 2. Coolify API Structure

**Authentication:**
- Type: Bearer token (HTTP)
- Header: `Authorization: Bearer <token>`
- Token source: Coolify Settings > Keys & Tokens > API tokens

**Base URL Structure:**
- Default: `https://app.coolify.io/api/v1`
- Self-hosted: `https://YOUR_COOLIFY_URL/api/v1`

**Key Endpoints:**

**Applications:**
- `GET /applications` - List all applications
- `POST /applications/public` - Deploy public repo
- `POST /applications/dockerfile` - Deploy from Dockerfile
- `POST /applications/dockerimage` - Deploy Docker image
- `POST /applications/dockercompose` - Deploy Docker Compose
- `GET /applications/{uuid}` - Get application details
- `GET /applications/{uuid}/logs` - View application logs
- `POST /applications/{uuid}/start` - Start application
- `POST /applications/{uuid}/stop` - Stop application
- `POST /applications/{uuid}/restart` - Restart application
- `GET /applications/{uuid}/envs` - List environment variables
- `POST /applications/{uuid}/envs/bulk` - Bulk update env vars

**Databases:**
- `GET /databases` - List all databases
- `POST /databases/postgresql` - Create PostgreSQL
- `POST /databases/mysql` - Create MySQL
- `POST /databases/mariadb` - Create MariaDB
- `POST /databases/mongodb` - Create MongoDB
- `POST /databases/redis` - Create Redis
- `POST /databases/keydb` - Create KeyDB
- `POST /databases/clickhouse` - Create ClickHouse
- `POST /databases/dragonfly` - Create Dragonfly
- `GET /databases/{uuid}` - Get database details
- `POST /databases/{uuid}/start` - Start database
- `POST /databases/{uuid}/stop` - Stop database
- `POST /databases/{uuid}/restart` - Restart database

**Deployments:**
- `GET /deployments` - List deployments
- `POST /deploy` - Trigger deployment
- `GET /deployments/applications/{uuid}` - Get app deployment history

### 3. User's Coolify Instance Details

**VM Information:**
- Public IP: 172.201.24.5
- SSH: `ssh -i ~/.ssh/coolify-vm vm-claimate-coolify@172.201.24.5`
- SSH Config alias: `coolify`

**Access Methods:**
1. Direct API calls via curl (from local machine)
2. SSH to VM + local curl (for internal services)

**Required Configuration:**
- COOLIFY_API_URL: Need to determine (likely http://172.201.24.5 or https://domain)
- COOLIFY_API_TOKEN: Need to obtain from Coolify dashboard

### 4. Existing MCP Server Insights

**Felix Allistar's Coolify MCP:**
- 100% API coverage
- TypeScript implementation
- Dual interface: MCP Tools + CLI
- Auto-generated from OpenAPI spec
- 21 application operations
- 14 service operations
- 13 database operations

**What We Can Learn:**
- API authentication pattern
- Common operation workflows
- Error handling patterns
- Parameter validation
- Response parsing

## Implementation Strategy

### Phase 1: Minimal Viable Skill (MVP)

**Scope:** Core operations for daily use

**Features:**
1. List applications
2. Deploy application (public repo)
3. Start/stop/restart application
4. View application logs
5. Check application status

**Structure:**
```
coolify/
└── SKILL.md              # All-in-one for MVP
```

**SKILL.md Structure:**
```yaml
---
name: coolify
description: Manages Coolify deployments and applications via API. Use when deploying apps, checking status, viewing logs, or controlling application lifecycle on Coolify infrastructure.
---

# Coolify Deployment Manager

[Brief overview]

## Prerequisites

Check before executing:
- [ ] Coolify API token set in environment
- [ ] API URL configured
- [ ] curl available

## Common Operations

### List Applications
[curl example with explanation]

### Deploy Application
[Step-by-step with validation]

### Control Application
[Start/stop/restart patterns]

### View Logs
[Log fetching and formatting]

## Configuration

[How to set up API token and URL]

## Troubleshooting

[Common issues and solutions]
```

### Phase 2: Enhanced Features

**Additional Features:**
1. Database management (create, start, stop)
2. Environment variable management
3. Service deployment
4. Deployment history
5. Multi-app operations

**Progressive Disclosure:**
```
coolify/
├── SKILL.md              # Overview + common operations
├── API_REFERENCE.md      # Complete API documentation
├── EXAMPLES.md           # Advanced workflows
└── scripts/
    ├── deploy-app.sh     # Deployment automation
    ├── setup-db.sh       # Database setup
    └── check-health.sh   # Health monitoring
```

### Phase 3: Production Polish

**Enhancements:**
1. Comprehensive error handling
2. Input validation scripts
3. Multi-model testing (Haiku, Sonnet, Opus)
4. Community examples
5. GitHub Actions for testing
6. Documentation site

## Implementation Details

### API Client Pattern (Bash/cURL)

**Authentication:**
```bash
# Set in environment or config
export COOLIFY_API_URL="https://172.201.24.5/api/v1"
export COOLIFY_API_TOKEN="your-token-here"

# Use in requests
curl -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
     "$COOLIFY_API_URL/applications"
```

**Error Handling:**
```bash
response=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
  echo "Success: $body"
else
  echo "Error ($http_code): $body"
  exit 1
fi
```

**Response Parsing:**
```bash
# List applications with jq
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | jq -r '.[] | "\(.name) (\(.uuid))"'
```

### Common Workflows

**1. Deploy New Application:**
```bash
# Step 1: Validate inputs
# Step 2: Create deployment request
# Step 3: Monitor deployment status
# Step 4: Verify deployment success
```

**2. Manage Application Lifecycle:**
```bash
# Step 1: Get application UUID
# Step 2: Execute control command (start/stop/restart)
# Step 3: Verify new state
```

**3. View Application Logs:**
```bash
# Step 1: Get application UUID
# Step 2: Fetch logs with optional filtering
# Step 3: Format and display
```

## Data from MCP Server (How it Helps)

### 1. API Patterns
- Complete endpoint coverage documentation
- Request/response schemas
- Authentication flow
- Error response formats

### 2. Parameter Validation
- Required vs optional parameters
- Parameter types and constraints
- Default values
- Validation rules

### 3. Common Operations
- Deployment workflows
- Database creation patterns
- Service provisioning steps
- Environment variable management

### 4. Error Handling
- HTTP status code interpretation
- Error message parsing
- Retry strategies
- Validation failures

## Next Steps

### Immediate Actions:

1. **Get Coolify API Token**
   - SSH to Coolify VM: `ssh coolify`
   - Access Coolify dashboard
   - Navigate to Settings > Keys & Tokens > API tokens
   - Create new token with required permissions
   - Save token securely

2. **Determine Coolify API URL**
   - Test: `http://172.201.24.5/api/v1`
   - Test: `https://172.201.24.5/api/v1`
   - Or check Coolify dashboard for API URL

3. **Test API Access**
   ```bash
   curl -H "Authorization: Bearer <token>" \
        "<coolify-url>/api/v1/applications"
   ```

4. **Create MVP SKILL.md**
   - Use template structure above
   - Implement 5 core operations
   - Include prerequisites checklist
   - Add configuration instructions

5. **Test Skill**
   - Install locally: `~/.claude/skills/coolify/`
   - Test with Claude Code
   - Iterate based on usage

6. **Iterate and Expand**
   - Add more operations based on usage
   - Create separate reference files as needed
   - Add utility scripts for complex operations
   - Test with different Claude models

### Success Criteria:

**MVP Success:**
- [ ] Can list applications via skill
- [ ] Can deploy a simple app
- [ ] Can start/stop/restart apps
- [ ] Can view application logs
- [ ] Proper error messages on failures

**Phase 2 Success:**
- [ ] Database management works
- [ ] Environment variables manageable
- [ ] Multiple operations in one session
- [ ] Scripts handle edge cases
- [ ] Works across Haiku/Sonnet/Opus

**Production Success:**
- [ ] Comprehensive documentation
- [ ] Community usage and feedback
- [ ] Automated testing
- [ ] Multiple contributors
- [ ] Listed in awesome-claude-skills

## Questions to Resolve

1. **Coolify API URL format** - Need to confirm actual URL
2. **API Token permissions** - What permissions are required?
3. **SSL/TLS setup** - Is HTTPS configured on the VM?
4. **Rate limiting** - Does Coolify API have rate limits?
5. **Webhook support** - Can we use webhooks for deployment notifications?

## Resources

**Documentation:**
- Coolify API Docs: https://coolify.io/docs/api
- Claude Skills Docs: https://docs.claude.com/en/docs/agents-and-tools/agent-skills
- skill-builder: https://github.com/metaskills/skill-builder

**MCP Server Reference:**
- Coolify MCP: https://github.com/FelixAllistar/coolify-mcp
- OpenAPI Spec: https://github.com/FelixAllistar/coolify-mcp/blob/master/coolify-openapi.json

**Examples:**
- Official Skills: https://github.com/anthropics/skills
- Awesome Skills: https://github.com/travisvn/awesome-claude-skills

## Timeline Estimate

- **Phase 1 (MVP)**: 2-3 hours
  - Research: ✅ Complete
  - API testing: 30 minutes
  - SKILL.md creation: 1 hour
  - Testing & iteration: 30-60 minutes

- **Phase 2 (Enhanced)**: 3-4 hours
  - Additional features: 2 hours
  - Progressive disclosure: 1 hour
  - Scripts creation: 1 hour

- **Phase 3 (Production)**: Ongoing
  - Community feedback: Continuous
  - Testing & refinement: Continuous
  - Documentation: 2-3 hours

**Total to MVP: 2-3 hours**
**Total to Production: 8-10 hours + ongoing maintenance**
