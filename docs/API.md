# Dataguard API Documentation

Complete REST API documentation for the Dataguard database monitoring and query auditing platform.

**Base URL:** `https://apidg.runyx.io/api`

---

## Table of Contents

1. [Authentication](#authentication)
2. [API Keys](#api-keys)
3. [Server Management](#server-management)
4. [Database Management](#database-management)
5. [Permission Management](#permission-management)
6. [Service User Management](#service-user-management)
7. [Agent Management](#agent-management)
8. [Query Audit](#query-audit)
9. [User Management](#user-management)
10. [Health & Monitoring](#health--monitoring)
11. [Error Handling](#error-handling)
12. [Rate Limiting](#rate-limiting)

---

## Authentication

The API supports two authentication methods:

### 1. JWT (Bearer Token)

Used for web application and interactive sessions.

```bash
# Login to get tokens
curl -X POST https://apidg.runyx.io/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@company.com",
    "password": "your-password"
  }'

# Response
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "user": {
      "id": "uuid",
      "email": "user@company.com",
      "role": "ADMIN"
    }
  }
}

# Use the token in subsequent requests
curl -X GET https://apidg.runyx.io/api/servers \
  -H "Authorization: Bearer eyJhbG..."
```

### 2. API Keys

Used for programmatic access and automation. API keys provide scope-based access control.

```bash
# Use API Key authentication
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_your_api_key" \
  -H "X-API-Secret: runyx_sk_your_secret_key"
```

---

## Authentication Endpoints

### Login

Authenticate user with email and password.

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@company.com",
  "password": "your-password"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresIn": 21600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@company.com",
      "username": "johndoe",
      "fullName": "John Doe",
      "role": "ADMIN",
      "tenantId": "tenant-uuid"
    }
  }
}
```

### Sign Up (Create Tenant & User)

Create a new tenant with the first admin user.

```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "admin@newcompany.com",
  "password": "SecurePass123!",
  "fullName": "John Doe",
  "companyName": "New Company Inc",
  "planId": "plan-uuid"
}
```

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

### Refresh Token

Refresh an expired access token.

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbG..."
}
```

### Forgot Password

Request a password reset email.

```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "user@company.com"
}
```

### Reset Password

Reset password using the token from email.

```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "token": "reset-token-from-email",
  "password": "NewSecurePass123!"
}
```

### Verify Token

Check if the current token is valid.

```http
GET /api/auth/verify
Authorization: Bearer eyJhbG...
```

### Logout

Invalidate the current session.

```http
POST /api/auth/logout
Authorization: Bearer eyJhbG...
```

---

## API Keys

API keys provide programmatic access with fine-grained permissions.

### List API Keys

```http
GET /api/api-keys
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `userId` | UUID | Filter by user ID |
| `includeRevoked` | boolean | Include revoked keys |
| `includeExpired` | boolean | Include expired keys |

### Create API Key

```http
POST /api/api-keys
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Production Integration",
  "scopes": [
    "servers:read",
    "servers:write",
    "permissions:read",
    "permissions:write"
  ],
  "rateLimit": 1000,
  "ipWhitelist": ["192.168.1.0/24", "10.0.0.1"],
  "expiryDays": 365
}
```

**Available Scopes:**
| Scope | Description |
|-------|-------------|
| `servers:read` | Read server information |
| `servers:write` | Create, update, delete servers |
| `users:read` | Read user information |
| `users:write` | Create, update, delete users |
| `permissions:read` | Read permissions |
| `permissions:write` | Grant permissions |
| `permissions:delete` | Revoke permissions |
| `api_keys:read` | Read API keys |
| `api_keys:write` | Manage API keys |
| `agents:read` | Read agent information |
| `agents:write` | Manage agents |
| `audit:read` | Read audit logs |
| `query_audit:read` | Read query audit logs |
| `service_users:read` | Read service users |
| `service_users:write` | Manage service users |

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "key-uuid",
    "name": "Production Integration",
    "apiKey": "runyx_ak_e9dea10edac7d072...",
    "secretKey": "runyx_sk_56abbdb203712cc9...",
    "scopes": ["servers:read", "servers:write"],
    "expiresAt": "2026-01-01T00:00:00.000Z"
  },
  "message": "API key created. Store the secret key securely - it won't be shown again."
}
```

### Rotate API Key

Generate new credentials for an existing key.

```http
POST /api/api-keys/:id/rotate
Authorization: Bearer eyJhbG...
```

### Revoke API Key

```http
DELETE /api/api-keys/:id
Authorization: Bearer eyJhbG...
```

---

## Server Management

Manage database servers to be monitored.

### List Servers

```http
GET /api/servers
Authorization: Bearer eyJhbG...
```

**Using API Key:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Get Server Details

```http
GET /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Create Server (CLOUD Mode)

Create a server that will be monitored directly from the cloud.

```http
POST /api/servers
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Production PostgreSQL",
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "username": "dataguard_user",
  "password": "secure-password",
  "database": "myapp",
  "environment": "PRODUCTION",
  "useSsl": true,
  "syncEnabled": true
}
```

**Database Types:**
| Type | Description |
|------|-------------|
| `postgres` or `postgresql` | PostgreSQL |
| `mysql` | MySQL |
| `mariadb` | MariaDB |
| `sqlserver` or `mssql` | Microsoft SQL Server |
| `mongodb` | MongoDB |
| `oracle` | Oracle Database |
| `cassandra` | Apache Cassandra |

**Environment Values:**
| Value | Description |
|-------|-------------|
| `DEV` | Development environment |
| `QA` | Quality Assurance / Testing |
| `PRODUCTION` | Production environment |

### Create Server (AGENT Mode)

Create a server that will be monitored via an on-premise agent.

```http
POST /api/servers
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Internal PostgreSQL",
  "host": "192.168.1.100",
  "port": 5432,
  "type": "postgres",
  "username": "dataguard_user",
  "password": "secure-password",
  "database": "internal_app",
  "environment": "PRODUCTION",
  "useSsl": false,
  "syncEnabled": true,
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid-from-agents-table"
}
```

### Create Server v2 (With Auto-Discovery)

Creates a server and automatically discovers databases, schemas, and tables.

```http
POST /api/servers/v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Production DB",
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "password",
  "environment": "PRODUCTION"
}
```

### Update Server

```http
PUT /api/servers/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "port": 5433,
  "syncEnabled": true,
  "sslEnabled": true
}
```

### Delete Server

```http
DELETE /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Test Connection

Test connection to a server before creating it.

```http
POST /api/servers/test-connection
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "password",
  "database": "mydb",
  "management_mode": "CLOUD"
}
```

### Test Existing Server Connection

```http
POST /api/servers/:id/test
Authorization: Bearer eyJhbG...
```

### Sync Server Databases

Trigger database discovery/sync for a server.

```http
POST /api/servers/:id/sync-databases
Authorization: Bearer eyJhbG...
```

### Get Server Metrics

Get real-time metrics from a server.

```http
GET /api/servers/:id/metrics
Authorization: Bearer eyJhbG...
```

---

## Database Management

### List Server Databases

```http
GET /api/servers/:id/databases
Authorization: Bearer eyJhbG...
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "name": "production_db",
      "owner": "postgres",
      "size_mb": 1024,
      "table_count": 45
    },
    {
      "name": "analytics_db",
      "owner": "analytics_user",
      "size_mb": 5120,
      "table_count": 128
    }
  ]
}
```

### List Database Schemas

```http
GET /api/servers/:id/databases/:dbName/schemas
Authorization: Bearer eyJhbG...
```

### List Database Tables

```http
GET /api/servers/:id/databases/:dbName/tables
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `schema` | string | Filter by schema name |

---

## Permission Management

Manage database permissions for users.

### List Permissions

```http
GET /api/permissions
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `userId` | UUID | Filter by user ID |
| `databaseId` | UUID | Filter by database ID |
| `serverId` | UUID | Filter by server ID |
| `permissionType` | string | Filter by permission type |
| `status` | string | Filter by status (active, revoked) |
| `includeExpired` | boolean | Include expired permissions |
| `consolidated` | boolean | Return consolidated view |

### Get Permission Details

```http
GET /api/permissions/:id
Authorization: Bearer eyJhbG...
```

### Grant Permission

```http
POST /api/permissions
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "userId": "user-uuid",
  "serverId": "server-uuid",
  "databaseId": "database-uuid",
  "permissionType": "READ",
  "permissions": {
    "select": true,
    "insert": false,
    "update": false,
    "delete": false
  },
  "expiresAt": "2025-12-31T23:59:59Z",
  "reason": "Quarterly report access"
}
```

**Permission Types:**
| Type | Description |
|------|-------------|
| `READ` | Read-only access |
| `WRITE` | Read and write access |
| `ADMIN` | Full administrative access |
| `CUSTOM` | Custom permission set |

### Grant Bulk Permissions

Grant the same permission to multiple users.

```http
POST /api/permissions/bulk
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "userIds": ["user-uuid-1", "user-uuid-2", "user-uuid-3"],
  "serverId": "server-uuid",
  "databaseId": "database-uuid",
  "permissionType": "READ",
  "permissions": {
    "select": true
  },
  "expiresAt": "2025-06-30T23:59:59Z"
}
```

### Update Permission

```http
PUT /api/permissions/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "permissionType": "WRITE",
  "permissions": {
    "select": true,
    "insert": true,
    "update": true
  },
  "expiresAt": "2025-12-31T23:59:59Z"
}
```

### Revoke Permission

```http
DELETE /api/permissions/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "reason": "Project completed"
}
```

### Check Permission

Check if a user has a specific permission.

```http
POST /api/permissions/check
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "userId": "user-uuid",
  "permissionType": "READ",
  "serverId": "server-uuid",
  "databaseId": "database-uuid"
}
```

### Sync Permissions

Synchronize permissions between Dataguard and the actual database server.

```http
POST /api/permissions/sync
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "serverId": "server-uuid",
  "syncType": "full"
}
```

**Sync Types:**
| Type | Description |
|------|-------------|
| `full` | Complete sync of all permissions |
| `partial` | Sync only changed permissions |

### Get Permission Statistics

```http
GET /api/permissions/stats
Authorization: Bearer eyJhbG...
```

### Get Expiring Permissions

```http
GET /api/permissions/expiring
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `days` | number | 7 | Days until expiration (1-365) |

### Get Permission Discrepancies

Find differences between Dataguard permissions and actual database permissions.

```http
GET /api/permissions/servers/:serverId/discrepancies
Authorization: Bearer eyJhbG...
```

---

## Service User Management

Manage service accounts/users on database servers.

### List Service Users

```http
GET /api/service-users
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `databaseId` | UUID | Filter by database |
| `serverId` | UUID | Filter by server |
| `status` | string | Filter by status |
| `username` | string | Filter by username |
| `needsRotation` | boolean | Filter users needing password rotation |
| `expiringDays` | number | Filter by days until password expires |

### Get Service User Details

```http
GET /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Create Service User

Create a new database user on a server.

```http
POST /api/service-users
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_readonly",
  "password": "SecurePass123!",
  "privileges": ["SELECT", "CONNECT"],
  "description": "Read-only user for reporting application",
  "expiresAt": "2025-12-31T23:59:59Z",
  "rotationIntervalDays": 90
}
```

**Common Privileges:**
| Privilege | Description |
|-----------|-------------|
| `SELECT` | Read data from tables |
| `INSERT` | Insert new rows |
| `UPDATE` | Update existing rows |
| `DELETE` | Delete rows |
| `CREATE` | Create tables/objects |
| `DROP` | Drop tables/objects |
| `CONNECT` | Connect to database |
| `EXECUTE` | Execute functions/procedures |
| `REFERENCES` | Create foreign keys |
| `TRIGGER` | Create triggers |
| `ALL` | All privileges |

### Create Service User v2 (With Propagation)

Creates a service user and propagates it to all relevant databases.

```http
POST /api/service-users-v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_service",
  "privileges": ["SELECT", "INSERT", "UPDATE"],
  "description": "Application service account",
  "rotationIntervalDays": 30
}
```

### Update Service User

```http
PUT /api/service-users/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Updated description",
  "expiresAt": "2026-06-30T23:59:59Z",
  "rotationIntervalDays": 60
}
```

### Delete Service User

Removes the user from the database server.

```http
DELETE /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Rotate Password

Change the password for a service user.

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "NewSecurePass456!",
  "generatePassword": false
}
```

Or generate a random password:

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "generatePassword": true
}
```

### Bulk Password Rotation

Rotate passwords for multiple service users.

```http
POST /api/service-users/bulk-rotate
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "serviceUserIds": ["user-uuid-1", "user-uuid-2"],
  "generatePasswords": true
}
```

### Auto-Rotate Passwords

Automatically rotate passwords for users that have exceeded their rotation interval.

```http
POST /api/service-users/auto-rotate
Authorization: Bearer eyJhbG...
```

### Test Service User Connection

```http
POST /api/service-users/:id/test-connection
Authorization: Bearer eyJhbG...
```

### Clone Service User

Clone an existing service user to another database.

```http
POST /api/service-users/:id/clone
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "targetDatabaseId": "target-database-uuid",
  "newUsername": "app_readonly_clone",
  "copyPrivileges": true
}
```

### Get Service User Statistics

```http
GET /api/service-users/stats
Authorization: Bearer eyJhbG...
```

### Get Users Needing Rotation

```http
GET /api/service-users/needing-rotation
Authorization: Bearer eyJhbG...
```

### Get Users with Expiring Passwords

```http
GET /api/service-users/expiring
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `days` | number | 7 | Days until expiration (1-365) |

---

## Agent Management

Manage on-premise agents for monitoring internal databases.

### List Agents

```http
GET /api/agents
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (online, offline, error) |
| `limit` | number | Results per page |
| `offset` | number | Pagination offset |

### Get Agent Details

```http
GET /api/agents/:agentId
Authorization: Bearer eyJhbG...
```

### Create Agent

```http
POST /api/agents
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "DC1-Agent",
  "description": "Agent for Datacenter 1",
  "capabilities": ["postgres", "mysql"],
  "config": {
    "maxConnections": 10
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "agent-uuid",
    "agentId": "0ad06bb9-1f87-4398-9810-f1293974df23",
    "name": "DC1-Agent",
    "apiKey": "agent-api-key",
    "secretKey": "agent-secret-key",
    "status": "offline"
  },
  "message": "Agent created. Configure the agent with these credentials."
}
```

### Update Agent

```http
PATCH /api/agents/:agentId
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "DC1-Agent-Updated",
  "description": "Updated description"
}
```

### Delete Agent

```http
DELETE /api/agents/:agentId
Authorization: Bearer eyJhbG...
```

### Rotate Agent Key

```http
POST /api/agents/:agentId/rotate-key
Authorization: Bearer eyJhbG...
```

### Get Agent Tasks

```http
GET /api/agents/:agentId/tasks
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status |
| `taskType` | string | Filter by task type |
| `limit` | number | Results per page |
| `offset` | number | Pagination offset |

### Create Agent Task

```http
POST /api/agents/:agentId/tasks
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "taskType": "TEST_CONNECTION_REQUEST",
  "payload": {
    "server_id": "server-uuid"
  },
  "priority": 5,
  "timeoutSeconds": 60
}
```

**Task Types:**
| Type | Description |
|------|-------------|
| `SYNC_REQUEST` | Sync server metadata |
| `TEST_CONNECTION_REQUEST` | Test server connection |
| `CREATE_USER_REQUEST` | Create database user |
| `GRANT_PERMISSIONS_REQUEST` | Grant permissions |
| `REVOKE_PERMISSIONS_REQUEST` | Revoke permissions |
| `REMOVE_USER_REQUEST` | Remove database user |
| `COLLECT_METRICS_REQUEST` | Collect server metrics |
| `DISCOVER_SERVER_METADATA_REQUEST` | Discover databases/schemas |

### Get Task Result

```http
GET /api/agents/tasks/:taskId
Authorization: Bearer eyJhbG...
```

### Cancel Task

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
Authorization: Bearer eyJhbG...
```

### Retry Failed Task

```http
POST /api/agents/:agentId/tasks/:taskId/retry
Authorization: Bearer eyJhbG...
```

### Get Agent Metrics

```http
GET /api/agents/:agentId/metrics
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `startDate` | ISO8601 | Start of date range |
| `endDate` | ISO8601 | End of date range |

### Get Agent Statistics Overview

```http
GET /api/agents/stats/overview
Authorization: Bearer eyJhbG...
```

---

## Query Audit

Monitor and audit database queries.

### Get Query Logs

```http
GET /api/query-audit/servers/:serverId/logs
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `queryType` | string | Filter by query type (SELECT, INSERT, UPDATE, DELETE) |
| `username` | string | Filter by database username |
| `database` | string | Filter by database name |
| `startDate` | ISO8601 | Start of date range |
| `endDate` | ISO8601 | End of date range |
| `success` | boolean | Filter by success status |
| `page` | number | Page number |
| `limit` | number | Results per page |

### Export Query Logs

```http
GET /api/query-audit/servers/:serverId/export
Authorization: Bearer eyJhbG...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | string | Export format: `csv` or `json` |
| Additional filters | | Same as Get Query Logs |

### Collect Queries

Trigger manual query collection from a server.

```http
POST /api/query-audit/servers/:serverId/collect
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "options": {
    "sinceLast": true
  }
}
```

### Check Query Audit Availability

```http
GET /api/query-audit/servers/:serverId/availability
Authorization: Bearer eyJhbG...
```

### Enable Query Audit

```http
POST /api/query-audit/servers/:serverId/enable
Authorization: Bearer eyJhbG...
```

### Disable Query Audit

```http
POST /api/query-audit/servers/:serverId/disable
Authorization: Bearer eyJhbG...
```

---

## User Management

Manage platform users within your tenant.

### List Users

```http
GET /api/users
Authorization: Bearer eyJhbG...
```

### Get Current User Profile

```http
GET /api/users/profile
Authorization: Bearer eyJhbG...
```

### Get User Details

```http
GET /api/users/:id
Authorization: Bearer eyJhbG...
```

### Create User

```http
POST /api/users
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "email": "newuser@company.com",
  "username": "newuser",
  "password": "SecurePass123!",
  "fullName": "New User",
  "role": "USER"
}
```

**User Roles:**
| Role | Description |
|------|-------------|
| `ADMIN` | Full tenant administration |
| `USER` | Standard user access |
| `VIEWER` | Read-only access |
| `APPROVER` | Can approve access requests |

### Update User

```http
PUT /api/users/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "email": "updated@company.com",
  "username": "updateduser",
  "role": "ADMIN"
}
```

### Delete User

```http
DELETE /api/users/:id
Authorization: Bearer eyJhbG...
```

### Change Password

Change your own password.

```http
POST /api/users/change-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "currentPassword": "OldPass123!",
  "newPassword": "NewPass456!"
}
```

### Reset User Password (Admin)

Reset another user's password.

```http
POST /api/users/:id/reset-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "TempPass123!"
}
```

### Get User Statistics

```http
GET /api/users/stats
Authorization: Bearer eyJhbG...
```

### List Active Sessions

```http
GET /api/users/sessions
Authorization: Bearer eyJhbG...
```

### Revoke Session

```http
DELETE /api/users/sessions/:sessionId
Authorization: Bearer eyJhbG...
```

### Revoke All Sessions

Revoke all sessions except the current one.

```http
DELETE /api/users/sessions
Authorization: Bearer eyJhbG...
```

---

## Health & Monitoring

### Basic Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00.000Z"
}
```

### Liveness Probe (Kubernetes)

```http
GET /health/live
```

### Readiness Probe

```http
GET /health/ready
```

### Detailed Health (Admin Only)

```http
GET /health/detailed
Authorization: Bearer eyJhbG...
```

**Response:**
```json
{
  "status": "healthy",
  "uptime": 86400,
  "database": {
    "status": "connected",
    "latency": 5
  },
  "redis": {
    "status": "connected"
  },
  "memory": {
    "used": 512,
    "total": 2048
  }
}
```

---

## Error Handling

All API errors follow a consistent format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ],
  "code": "VALIDATION_ERROR"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request - Invalid input |
| `401` | Unauthorized - Invalid or missing authentication |
| `403` | Forbidden - Insufficient permissions |
| `404` | Not Found - Resource doesn't exist |
| `409` | Conflict - Resource already exists |
| `422` | Unprocessable Entity - Validation failed |
| `429` | Too Many Requests - Rate limit exceeded |
| `500` | Internal Server Error |

### Common Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `AUTHENTICATION_ERROR` | Authentication failed |
| `AUTHORIZATION_ERROR` | Permission denied |
| `NOT_FOUND` | Resource not found |
| `DUPLICATE_ENTRY` | Resource already exists |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `CONNECTION_ERROR` | Database connection failed |

---

## Rate Limiting

The API implements rate limiting to ensure fair usage:

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| General API | 300 requests | 15 minutes |
| Authentication | 10 requests | 1 minute |
| 2FA Verification | 5 attempts | 15 minutes |
| API Key (Custom) | Configurable | 15 minutes |

When rate limited, the API returns:

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705315800

{
  "success": false,
  "message": "Too many requests, please try again later",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

---

## Pagination

List endpoints support pagination:

```http
GET /api/servers?limit=20&offset=40
```

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "limit": 20,
    "offset": 40,
    "total": 150,
    "hasMore": true
  }
}
```

---

## Webhooks

Configure webhooks to receive real-time notifications about events.

### Webhook Events

| Event | Description |
|-------|-------------|
| `server.created` | New server added |
| `server.deleted` | Server removed |
| `permission.granted` | Permission granted |
| `permission.revoked` | Permission revoked |
| `permission.expiring` | Permission about to expire |
| `user.created` | New user created |
| `service_user.created` | Service user created |
| `service_user.password_rotated` | Password rotated |
| `agent.connected` | Agent came online |
| `agent.disconnected` | Agent went offline |
| `query_audit.anomaly` | Unusual query detected |

---

## SDK Examples

### Python

```python
import requests

class DataguardClient:
    def __init__(self, api_key, secret_key, base_url="https://apidg.runyx.io/api"):
        self.base_url = base_url
        self.headers = {
            "X-API-Key": api_key,
            "X-API-Secret": secret_key,
            "Content-Type": "application/json"
        }

    def list_servers(self):
        response = requests.get(f"{self.base_url}/servers", headers=self.headers)
        return response.json()

    def create_server(self, server_data):
        response = requests.post(
            f"{self.base_url}/servers",
            headers=self.headers,
            json=server_data
        )
        return response.json()

    def grant_permission(self, permission_data):
        response = requests.post(
            f"{self.base_url}/permissions",
            headers=self.headers,
            json=permission_data
        )
        return response.json()

# Usage
client = DataguardClient(
    api_key="runyx_ak_...",
    secret_key="runyx_sk_..."
)

servers = client.list_servers()
print(servers)
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

class DataguardClient {
  constructor(apiKey, secretKey, baseUrl = 'https://apidg.runyx.io/api') {
    this.client = axios.create({
      baseURL: baseUrl,
      headers: {
        'X-API-Key': apiKey,
        'X-API-Secret': secretKey,
        'Content-Type': 'application/json'
      }
    });
  }

  async listServers() {
    const response = await this.client.get('/servers');
    return response.data;
  }

  async createServer(serverData) {
    const response = await this.client.post('/servers', serverData);
    return response.data;
  }

  async grantPermission(permissionData) {
    const response = await this.client.post('/permissions', permissionData);
    return response.data;
  }
}

// Usage
const client = new DataguardClient(
  'runyx_ak_...',
  'runyx_sk_...'
);

client.listServers().then(servers => console.log(servers));
```

### cURL

```bash
# List all servers
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."

# Create a server
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production DB",
    "host": "db.example.com",
    "port": 5432,
    "type": "postgres",
    "username": "admin",
    "password": "password",
    "environment": "PRODUCTION"
  }'

# Grant permission
curl -X POST "https://apidg.runyx.io/api/permissions" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-uuid",
    "serverId": "server-uuid",
    "permissionType": "READ",
    "permissions": {"select": true}
  }'
```

---

## Support

- **Documentation:** https://docs.runyx.io
- **API Status:** https://status.runyx.io
- **Support Email:** support@runyx.io
- **GitHub Issues:** https://github.com/runyxio/dataguard/issues

---

*Last updated: December 2025*
