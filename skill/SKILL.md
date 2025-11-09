---
name: coolify
description: Manages Coolify deployments, applications, and infrastructure via API. Use when deploying apps, checking status, viewing logs, controlling application lifecycle, or managing Coolify resources.
---

# Coolify Deployment Manager

Manages Coolify applications and infrastructure through the Coolify API.

## Documentation Structure

- **This file** - Quick reference and common operations
- `API_REFERENCE.md` - Complete API documentation with all endpoints
- `EXAMPLES.md` - Real-world workflows and advanced use cases
- `scripts/` - Production-ready utility scripts

## Quick Setup

### Prerequisites

- [ ] Coolify API token (Settings → Keys & Tokens in Coolify dashboard)
- [ ] SSH tunnel active (if remote): `ssh -i ~/.ssh/coolify-vm -f -N -L 8000:localhost:8000 vm-claimate-coolify@172.201.24.5`
- [ ] `curl` and `jq` installed

### Environment Configuration

```bash
# Set required environment variables
export COOLIFY_API_TOKEN="your-token-here"
export COOLIFY_API_URL="http://localhost:8000/api/v1"

# Verify connectivity
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/health"
# Should return: OK
```

## Utility Scripts (Recommended)

Use pre-built scripts for common operations:

### List Applications

```bash
# List all applications
bash scripts/list-apps.sh

# Filter by status
bash scripts/list-apps.sh --filter=unhealthy

# JSON output
bash scripts/list-apps.sh --json
```

### Deploy Application

```bash
# Deploy with monitoring
bash scripts/deploy.sh "app-name"

# Force rebuild
bash scripts/deploy.sh "app-name" --force
```

### Restart Applications

```bash
# Restart single app
bash scripts/restart.sh "app-name"

# Restart all unhealthy apps
bash scripts/restart.sh --all-unhealthy
```

### Health Check

```bash
# Run comprehensive health check
bash scripts/health-check.sh

# Verbose output
bash scripts/health-check.sh --verbose
```

## Direct API Operations

For quick operations without scripts, use curl directly:

### List All Applications

```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | "\(.name): \(.status)"'
```

**Common Status Values:**
- `running:healthy` - Application running normally
- `running:unhealthy` - Running but failing health checks
- `exited:unhealthy` - Stopped
- `deploying` - Deployment in progress

### Get Application UUID

```bash
# Find UUID by name
uuid=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.name | contains("app-name")) | .uuid')

echo $uuid
```

### Start/Stop/Restart Application

```bash
# Start
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/start"

# Stop
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/stop"

# Restart
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/restart"
```

### Trigger Deployment

```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d '{"uuid": "app-uuid", "force": false}'
```

### View Logs

```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/logs" | tail -50
```

### Check Application Status

```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}" | \
  jq '{name, status, fqdn, git_branch}'
```

## Common Workflows

### Quick Deploy

```bash
# 1. Find app UUID
uuid=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.name | contains("my-app")) | .uuid')

# 2. Trigger deployment
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d "{\"uuid\": \"$uuid\", \"force\": false}"

# 3. Monitor status
for i in {1..20}; do
  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid" | jq -r '.status')
  echo "[$i] Status: $status"
  [[ "$status" == "running:healthy" ]] && break
  sleep 10
done
```

**For complex workflows,** see `EXAMPLES.md`:
- Blue-green deployments
- Automated rollbacks
- Batch operations
- Monitoring dashboards

### Restart Unhealthy Apps

```bash
# Find unhealthy
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status | contains("unhealthy")) | .uuid' | \
while read uuid; do
  curl -s -X POST \
    -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid/restart"
  echo "Restarted: $uuid"
done
```

**Or use the script:** `bash scripts/restart.sh --all-unhealthy`

## Error Handling

### Verify API Access

```bash
# 1. Check API health
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/health"

# 2. Test permissions
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | jq 'length'

# 3. Check SSH tunnel (if using localhost)
ps aux | grep "ssh.*8000"
```

**Run full diagnostics:** `bash scripts/health-check.sh`

### Common Errors

| Error | Solution |
|-------|----------|
| `401 Unauthorized` | Check `$COOLIFY_API_TOKEN` is set and valid |
| `403 Forbidden` | Token needs read/write/deploy permissions |
| `404 Not Found` | Verify UUID exists with list applications |
| `Connection refused` | Check SSH tunnel or API URL |

**For detailed troubleshooting,** see `API_REFERENCE.md` → Error Codes section.

## Advanced Operations

### Environment Variables

```bash
# List
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/envs" | jq .

# Update (bulk)
curl -s -X PUT \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/{uuid}/envs/bulk" \
  -d '{"env_variables": [{"key": "VAR", "value": "val"}]}'
```

### Filter Applications

```bash
# By status
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.status == "running:healthy") | .name'

# By branch
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.git_branch == "dev") | .name'

# By repository
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r '.[] | select(.git_repository | contains("myrepo")) | .name'
```

**For complete API documentation,** see `API_REFERENCE.md`:
- All endpoints (applications, databases, deployments)
- Request/response schemas
- Authentication details
- Rate limiting

## Best Practices

### 1. Use Scripts for Complex Operations

Scripts in `scripts/` include:
- Error handling
- Status monitoring
- User confirmation for destructive ops
- Progress indicators

**Prefer scripts over inline commands for production use.**

### 2. Monitor Deployment Progress

Never trigger deployment without monitoring:

```bash
# Bad - fire and forget
curl -X POST "$COOLIFY_API_URL/deploy" -d '{"uuid": "..."}'

# Good - monitor until healthy
bash scripts/deploy.sh "app-name"
```

### 3. Verify Before Destructive Operations

```bash
# Always check current status before stop/restart
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/$uuid" | jq '{name, status}'

# Then confirm operation
```

### 4. Keep API Token Secure

- Store in `.env` file (never commit)
- Use environment variables
- Rotate periodically
- Use minimum required permissions

## Quick Reference

| Task | Script | Direct API |
|------|--------|------------|
| List apps | `scripts/list-apps.sh` | `GET /applications` |
| Deploy | `scripts/deploy.sh APP` | `POST /deploy` |
| Restart | `scripts/restart.sh APP` | `POST /applications/{uuid}/restart` |
| Health check | `scripts/health-check.sh` | `GET /health` |
| View logs | (see API_REFERENCE.md) | `GET /applications/{uuid}/logs` |

## Further Reading

- **Complete API docs:** `API_REFERENCE.md`
- **Advanced workflows:** `EXAMPLES.md`
- **GitHub repository:** https://github.com/vbalko-claimate/coolify-claude-skill
- **Coolify documentation:** https://coolify.io/docs

## Notes

- Application UUIDs are stable - safe to store for repeated use
- Status changes take 5-10 seconds to reflect
- Use `jq` for JSON parsing: `brew install jq`
- SSH tunnel must stay active for localhost API access
