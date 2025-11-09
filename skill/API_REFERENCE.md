# Coolify API Reference

Complete API documentation for Coolify operations. This is a detailed reference - for quick operations, see SKILL.md.

## Table of Contents

- [Authentication](#authentication)
- [Applications API](#applications-api)
- [Databases API](#databases-api)
- [Deployments API](#deployments-api)
- [Environment Variables](#environment-variables)
- [Response Formats](#response-formats)
- [Error Codes](#error-codes)

## Authentication

All API requests require Bearer token authentication.

**Header:**
```
Authorization: Bearer YOUR_API_TOKEN
```

**Token Permissions:**
- `read` - List and view resources
- `write` - Create and update resources
- `deploy` - Trigger deployments

**Get Token:**
1. Open Coolify dashboard
2. Settings → Keys & Tokens → API
3. Create new token with required permissions

## Applications API

### List All Applications

**Endpoint:** `GET /applications`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications"
```

**Response Fields:**
- `uuid` - Unique application identifier
- `name` - Application name (format: `repo:branch`)
- `status` - Current status (running:healthy, exited:unhealthy, deploying)
- `git_repository` - Git repository name
- `git_branch` - Git branch
- `fqdn` - Fully qualified domain name
- `build_pack` - Build method (dockerfile, dockercompose, etc.)
- `destination` - Server and network details

**Example Response:**
```json
[
  {
    "uuid": "q88wc80gswgwg80o4swo004g",
    "name": "claimate/cc-ask-a-genie:dev",
    "status": "running:healthy",
    "git_repository": "claimate/cc-ask-a-genie",
    "git_branch": "dev",
    "fqdn": "https://ask-a-genie-dev.app.claimate.tech",
    "build_pack": "dockerfile"
  }
]
```

### Get Application Details

**Endpoint:** `GET /applications/{uuid}`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}"
```

**Response:** Full application object with all fields

### Create Application (Public Repo)

**Endpoint:** `POST /applications/public`

**Required Parameters:**
- `project_uuid` - Project UUID
- `server_uuid` - Server UUID
- `environment_name` - Environment name
- `git_repository` - Repository (format: `owner/repo`)
- `git_branch` - Branch name
- `build_pack` - Build method (dockerfile, dockercompose, nixpacks, static)
- `ports_exposes` - Exposed port (e.g., "3000")

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/public" \
  -d '{
    "project_uuid": "...",
    "server_uuid": "...",
    "environment_name": "production",
    "git_repository": "owner/repo",
    "git_branch": "main",
    "build_pack": "dockerfile",
    "ports_exposes": "3000"
  }'
```

**Response:**
```json
{
  "uuid": "newly-created-app-uuid"
}
```

### Start Application

**Endpoint:** `POST /applications/{uuid}/start`

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/start"
```

**Response:** Success message or error

### Stop Application

**Endpoint:** `POST /applications/{uuid}/stop`

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/stop"
```

**Response:** Success message or error

### Restart Application

**Endpoint:** `POST /applications/{uuid}/restart`

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/restart"
```

**Response:** Success message or error

### Get Application Logs

**Endpoint:** `GET /applications/{uuid}/logs`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/logs"
```

**Response:** Log output (format varies)

### Delete Application

**Endpoint:** `DELETE /applications/{uuid}`

**Request:**
```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}"
```

**Warning:** This permanently deletes the application and its data.

## Environment Variables

### List Environment Variables

**Endpoint:** `GET /applications/{uuid}/envs`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/envs"
```

**Response:**
```json
[
  {
    "uuid": "env-var-uuid",
    "key": "DATABASE_URL",
    "value": "postgresql://...",
    "is_build_time": false,
    "is_preview": false
  }
]
```

### Update Environment Variables (Bulk)

**Endpoint:** `PUT /applications/{uuid}/envs/bulk`

**Request:**
```bash
curl -s -X PUT \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/{uuid}/envs/bulk" \
  -d '{
    "env_variables": [
      {"key": "API_KEY", "value": "new-value"},
      {"key": "DEBUG", "value": "true"}
    ]
  }'
```

### Create Environment Variable

**Endpoint:** `POST /applications/{uuid}/envs`

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/applications/{uuid}/envs" \
  -d '{
    "key": "NEW_VAR",
    "value": "value",
    "is_build_time": false,
    "is_preview": false
  }'
```

### Delete Environment Variable

**Endpoint:** `DELETE /applications/{uuid}/envs/{env_uuid}`

**Request:**
```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications/{uuid}/envs/{env_uuid}"
```

## Deployments API

### Trigger Deployment

**Endpoint:** `POST /deploy`

**Parameters:**
- `uuid` - Application UUID
- `force` - Force rebuild (optional, default: false)

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/deploy" \
  -d '{
    "uuid": "app-uuid",
    "force": false
  }'
```

**Response:** Deployment started message

### List Deployments

**Endpoint:** `GET /deployments`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/deployments"
```

**Response:** Array of deployment objects

### Get Application Deployment History

**Endpoint:** `GET /deployments/applications/{uuid}`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/deployments/applications/{uuid}"
```

**Response:** Deployment history for specific application

## Databases API

### List Databases

**Endpoint:** `GET /databases`

**Request:**
```bash
curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/databases"
```

**Response:** Array of database objects

### Create PostgreSQL Database

**Endpoint:** `POST /databases/postgresql`

**Required Parameters:**
- `project_uuid`
- `server_uuid`
- `environment_name`
- `database_name`
- `database_user`
- `database_password`

**Request:**
```bash
curl -s -X POST \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$COOLIFY_API_URL/databases/postgresql" \
  -d '{
    "project_uuid": "...",
    "server_uuid": "...",
    "environment_name": "production",
    "database_name": "mydb",
    "database_user": "myuser",
    "database_password": "securepass"
  }'
```

### Create MySQL Database

**Endpoint:** `POST /databases/mysql`

Same parameters as PostgreSQL.

### Create MongoDB Database

**Endpoint:** `POST /databases/mongodb`

Same parameters as PostgreSQL.

### Create Redis Database

**Endpoint:** `POST /databases/redis`

**Required Parameters:**
- `project_uuid`
- `server_uuid`
- `environment_name`
- `redis_password`

### Database Operations

**Start:** `POST /databases/{uuid}/start`
**Stop:** `POST /databases/{uuid}/stop`
**Restart:** `POST /databases/{uuid}/restart`

Same request format as application operations.

## Response Formats

### Success Response

Most successful operations return:

```json
{
  "message": "Operation successful"
}
```

Or for create operations:

```json
{
  "uuid": "newly-created-resource-uuid"
}
```

### Error Response

```json
{
  "message": "Error description",
  "errors": {
    "field": ["Error detail"]
  }
}
```

## Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Check API token is valid |
| 403 | Forbidden | Token lacks required permission |
| 404 | Not Found | Resource UUID doesn't exist |
| 422 | Validation Error | Check required parameters |
| 500 | Server Error | Check Coolify logs, contact support |

## Rate Limiting

Coolify doesn't enforce strict rate limits, but:

- Avoid rapid-fire requests (use delays between operations)
- Batch operations when possible
- Use polling intervals of 5+ seconds for status checks

## Best Practices

### Status Polling

When waiting for status changes (deploy, start, stop):

```bash
# Poll every 5 seconds, max 20 attempts
for i in {1..20}; do
  status=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
    "$COOLIFY_API_URL/applications/$uuid" | jq -r '.status')

  echo "Check $i: $status"

  if [[ "$status" == "running:healthy" ]]; then
    break
  fi

  sleep 5
done
```

### Error Handling

Always check HTTP status codes:

```bash
response=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
  echo "$body" | jq .
else
  echo "Error ($http_code): $body"
  exit 1
fi
```

### UUID Validation

Before operations, verify UUID exists:

```bash
uuid="q88wc80gswgwg80o4swo004g"

exists=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" \
  "$COOLIFY_API_URL/applications" | \
  jq -r --arg uuid "$uuid" '.[] | select(.uuid == $uuid) | .uuid')

if [ -z "$exists" ]; then
  echo "Error: Application $uuid not found"
  exit 1
fi
```

## API Versioning

Current API version: **v1**

Base URL structure: `{COOLIFY_URL}/api/v1`

Coolify maintains backward compatibility within major versions.

## Additional Resources

- Coolify Official Docs: https://coolify.io/docs
- API Documentation: https://app.coolify.io/api/documentation
- OpenAPI Specification: Available in Coolify dashboard
