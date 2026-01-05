# Dataguard API Documentation

Complete REST API documentation for the Dataguard database monitoring and query auditing platform.

**Base URL:** `https://apidg.runyx.io/api`

---

## Table of Contents

1. [Authentication](#authentication)
2. [Server Management](#server-management)
3. [Database Management](#database-management)
4. [Permission Management](#permission-management)
5. [Service User Management](#service-user-management)
6. [Agent Management](#agent-management)
7. [Query Audit](#query-audit)
8. [User Management](#user-management)
9. [Health & Monitoring](#health--monitoring)
10. [Error Handling](#error-handling)
11. [Rate Limiting](#rate-limiting)

---

## Authentication

The API uses API Key authentication for programmatic access.

### API Key Authentication

All requests must include the following headers:

```bash
X-API-Key: runyx_ak_your_api_key
X-API-Secret: runyx_sk_your_secret_key
```

**Example:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_your_api_key" \
  -H "X-API-Secret: runyx_sk_your_secret_key"
```

### Available Scopes

API keys have scope-based permissions:

| Scope | Description |
|-------|-------------|
| `servers:read` | Read server information |
| `servers:write` | Create, update, delete servers |
| `users:read` | Read user information |
| `users:write` | Create, update, delete users |
| `permissions:read` | Read permissions |
| `permissions:write` | Grant permissions |
| `permissions:delete` | Revoke permissions |
| `agents:read` | Read agent information |
| `agents:write` | Manage agents |
| `audit:read` | Read audit logs |
| `query_audit:read` | Read query audit logs |
| `service_users:read` | Read service users |
| `service_users:write` | Manage service users |

---

## Server Management

Manage database servers to be monitored.

### List Servers

```http
GET /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Example:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Production PostgreSQL",
      "host": "db.example.com",
      "port": 5432,
      "type": "postgres",
      "status": "ACTIVE",
      "environment": "PRODUCTION",
      "managementMode": "CLOUD",
      "databaseCount": 5,
      "tableCount": 120
    }
  ]
}
```

### Get Server Details

```http
GET /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Example:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Create Server (CLOUD Mode)

Create a server that will be monitored directly from the cloud. **Auto-discovery of databases, schemas, and tables is performed automatically.**

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
  "syncEnabled": true,
  "credentialSource": "inline"
}
```

**Request Body Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Server display name |
| `host` | string | Yes | Database host/IP |
| `port` | number | Yes | Database port |
| `type` | string | Yes | Database type (see table below) |
| `username` | string | Conditional | Required if `credentialSource` is `inline` |
| `password` | string | Conditional | Required if `credentialSource` is `inline` |
| `database` | string | No | Default database name |
| `environment` | string | No | Environment (DEV, QA, PRODUCTION) |
| `useSsl` | boolean | No | Enable SSL/TLS connection |
| `syncEnabled` | boolean | No | Enable automatic sync |
| `managementMode` | string | No | `CLOUD` (default) or `AGENT` |
| `assignedAgentId` | UUID | Conditional | Required if `managementMode` is `AGENT` |
| `credentialSource` | string | No | `inline` (default) or `secrets_manager` |
| `secretsConfig` | object | Conditional | Required if `credentialSource` is `secrets_manager` |

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

**Example:**
```bash
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production PostgreSQL",
    "host": "db.example.com",
    "port": 5432,
    "type": "postgres",
    "username": "dataguard_user",
    "password": "secure-password",
    "environment": "PRODUCTION",
    "useSsl": true
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "server": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Production PostgreSQL",
      "host": "db.example.com",
      "port": 5432,
      "type": "postgres",
      "status": "active",
      "environment": "PRODUCTION",
      "management_mode": "CLOUD",
      "credential_source": "inline",
      "secrets_config": null
    },
    "discovery": {
      "success": true,
      "mode": "CLOUD",
      "message": "Discovered 5 databases",
      "metadata": {
        "databases": [
          {"name": "myapp", "owner": "postgres", "size_mb": 1024, "table_count": 45}
        ]
      }
    }
  }
}
```

### Create Server (AGENT Mode)

Create a server that will be monitored via an on-premise agent. **Auto-discovery is performed by the agent.**

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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

**Example:**
```bash
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Internal PostgreSQL",
    "host": "192.168.1.100",
    "port": 5432,
    "type": "postgres",
    "username": "dataguard_user",
    "password": "secure-password",
    "environment": "PRODUCTION",
    "managementMode": "AGENT",
    "assignedAgentId": "13f84c6e-5448-47a4-bbdf-bd2110669a55"
  }'
```

**Response (AGENT mode):**
```json
{
  "success": true,
  "data": {
    "server": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Internal PostgreSQL",
      "management_mode": "AGENT",
      "assigned_agent_id": "13f84c6e-5448-47a4-bbdf-bd2110669a55"
    },
    "discovery": {
      "success": true,
      "mode": "AGENT",
      "message": "Discovery task sent to agent. Task ID: task-uuid",
      "taskId": "task-uuid"
    }
  }
}
```

### Create Server with Secrets Manager

Instead of storing credentials directly, you can configure the server to fetch credentials from an external secrets manager (AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault).

#### Using AWS Secrets Manager (AGENT Mode)

When using AGENT mode, the agent uses the IAM role attached to the EC2/ECS instance to access Secrets Manager - no Role ARN needed.

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Production PostgreSQL",
  "host": "192.168.1.100",
  "port": 5432,
  "type": "postgres",
  "database": "myapp",
  "environment": "PRODUCTION",
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid",
  "credentialSource": "secrets_manager",
  "secretsConfig": {
    "provider": "aws",
    "secretName": "prod/database/postgres-credentials",
    "aws": {
      "region": "us-east-1"
    }
  }
}
```

#### Using AWS Secrets Manager (CLOUD Mode)

When using CLOUD mode, provide a Role ARN for cross-account access.

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Production PostgreSQL",
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "database": "myapp",
  "environment": "PRODUCTION",
  "managementMode": "CLOUD",
  "credentialSource": "secrets_manager",
  "secretsConfig": {
    "provider": "aws",
    "secretName": "prod/database/postgres-credentials",
    "aws": {
      "region": "us-east-1",
      "roleArn": "arn:aws:iam::123456789012:role/DataguardSecretsAccess"
    }
  }
}
```

#### Using Azure Key Vault

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Production PostgreSQL",
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "database": "myapp",
  "environment": "PRODUCTION",
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid",
  "credentialSource": "secrets_manager",
  "secretsConfig": {
    "provider": "azure",
    "secretName": "postgres-credentials",
    "azure": {
      "vaultUrl": "https://myvault.vault.azure.net"
    }
  }
}
```

#### Using HashiCorp Vault

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Production PostgreSQL",
  "host": "db.example.com",
  "port": 5432,
  "type": "postgres",
  "database": "myapp",
  "environment": "PRODUCTION",
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid",
  "credentialSource": "secrets_manager",
  "secretsConfig": {
    "provider": "vault",
    "secretName": "database/creds/postgres",
    "vault": {
      "address": "https://vault.example.com:8200",
      "namespace": "admin/production"
    }
  }
}
```

**Credential Source Values:**
| Value | Description |
|-------|-------------|
| `inline` | Username and password stored directly (default) |
| `secrets_manager` | Credentials fetched from external secrets manager |

**Secrets Providers:**
| Provider | Description |
|----------|-------------|
| `aws` | AWS Secrets Manager |
| `azure` | Azure Key Vault |
| `vault` | HashiCorp Vault |

**AWS Regions:**
| Region | Location |
|--------|----------|
| `us-east-1` | US East (N. Virginia) |
| `us-east-2` | US East (Ohio) |
| `us-west-1` | US West (N. California) |
| `us-west-2` | US West (Oregon) |
| `eu-west-1` | Europe (Ireland) |
| `eu-west-2` | Europe (London) |
| `eu-central-1` | Europe (Frankfurt) |
| `ap-southeast-1` | Asia Pacific (Singapore) |
| `ap-southeast-2` | Asia Pacific (Sydney) |
| `ap-northeast-1` | Asia Pacific (Tokyo) |
| `sa-east-1` | South America (São Paulo) |

**Secret Format:**

The secret must contain a JSON object with `username` and `password` keys:

```json
{
  "username": "db_user",
  "password": "secure_password"
}
```

**Authentication by Mode:**

| Mode | Provider | Authentication Method |
|------|----------|----------------------|
| AGENT | AWS | EC2/ECS IAM Instance Role |
| AGENT | Azure | Managed Identity |
| AGENT | Vault | Local token or AppRole |
| CLOUD | AWS | STS AssumeRole (cross-account) |
| CLOUD | Azure | Service Principal |
| CLOUD | Vault | Backend Vault token |

### Update Server

```http
PUT /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "port": 5433,
  "syncEnabled": true,
  "sslEnabled": true
}
```

**Example:**
```bash
curl -X PUT "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{"syncEnabled": true}'
```

### Delete Server

```http
DELETE /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Example:**
```bash
curl -X DELETE "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Test Connection

Test connection to a server before creating it.

```http
POST /api/servers/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Sync Server Databases

Trigger database discovery/sync for a server.

```http
POST /api/servers/:id/sync-databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Server Metrics

Get real-time metrics from a server.

```http
GET /api/servers/:id/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Database Management

### List Server Databases

```http
GET /api/servers/:id/databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### List Database Tables

```http
GET /api/servers/:id/databases/:dbName/tables
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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

### Get Permission Details

```http
GET /api/permissions/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Grant Permission

```http
POST /api/permissions
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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

**Example:**
```bash
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

### Grant Bulk Permissions

Grant the same permission to multiple users.

```http
POST /api/permissions/bulk
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "reason": "Project completed"
}
```

### Check Permission

Check if a user has a specific permission.

```http
POST /api/permissions/check
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Expiring Permissions

```http
GET /api/permissions/expiring?days=7
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Permission Discrepancies

Find differences between Dataguard permissions and actual database permissions.

```http
GET /api/permissions/servers/:serverId/discrepancies
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Service User Management

Manage service accounts/users on database servers.

### List Service Users

```http
GET /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `databaseId` | UUID | Filter by database |
| `serverId` | UUID | Filter by server |
| `status` | string | Filter by status |
| `username` | string | Filter by username |
| `needsRotation` | boolean | Filter users needing password rotation |

### Get Service User Details

```http
GET /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Create Service User

Create a new database user on a server.

```http
POST /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
| `ALL` | All privileges |

**Example:**
```bash
curl -X POST "https://apidg.runyx.io/api/service-users" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "databaseId": "database-uuid",
    "username": "app_service",
    "privileges": ["SELECT", "INSERT", "UPDATE"],
    "description": "Application service account",
    "rotationIntervalDays": 30
  }'
```

### Update Service User

```http
PUT /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Updated description",
  "rotationIntervalDays": 60
}
```

### Delete Service User

Removes the user from the database server.

```http
DELETE /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotate Password

Change the password for a service user.

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "generatePassword": true
}
```

Or specify a new password:

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "NewSecurePass456!"
}
```

### Bulk Password Rotation

Rotate passwords for multiple service users.

```http
POST /api/service-users/bulk-rotate
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "serviceUserIds": ["user-uuid-1", "user-uuid-2"],
  "generatePasswords": true
}
```

### Test Service User Connection

```http
POST /api/service-users/:id/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Clone Service User

Clone an existing service user to another database.

```http
POST /api/service-users/:id/clone
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Users Needing Rotation

```http
GET /api/service-users/needing-rotation
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Agent Management

Manage on-premise agents for monitoring internal databases.

### List Agents

```http
GET /api/agents
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Create Agent

```http
POST /api/agents
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "DC1-Agent",
  "description": "Agent for Datacenter 1",
  "capabilities": ["postgres", "mysql"]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "13f84c6e-5448-47a4-bbdf-bd2110669a55",
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "DC1-Agent-Updated",
  "description": "Updated description"
}
```

### Delete Agent

```http
DELETE /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotate Agent Key

```http
POST /api/agents/:agentId/rotate-key
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Agent Tasks

```http
GET /api/agents/:agentId/tasks
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Create Agent Task

```http
POST /api/agents/:agentId/tasks
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Cancel Task

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Agent Metrics

```http
GET /api/agents/:agentId/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get Agent Statistics Overview

```http
GET /api/agents/stats/overview
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Query Audit

Monitor and audit database queries.

### Get Query Logs

```http
GET /api/query-audit/servers/:serverId/logs
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
GET /api/query-audit/servers/:serverId/export?format=csv
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | string | Export format: `csv` or `json` |

### Collect Queries

Trigger manual query collection from a server.

```http
POST /api/query-audit/servers/:serverId/collect
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Enable Query Audit

```http
POST /api/query-audit/servers/:serverId/enable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Disable Query Audit

```http
POST /api/query-audit/servers/:serverId/disable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## User Management

Manage platform users within your tenant.

### List Users

```http
GET /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Get User Details

```http
GET /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Create User

```http
POST /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Reset User Password

```http
POST /api/users/:id/reset-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "TempPass123!"
}
```

### Get User Statistics

```http
GET /api/users/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
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

---

## Support

- **Documentation:** https://docs.runyx.io
- **API Status:** https://status.runyx.io
- **Support Email:** support@runyx.io

---

*Last updated: January 2026*
