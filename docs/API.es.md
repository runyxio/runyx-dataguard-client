# Documentacion de la API Dataguard

Documentacion completa de la API REST para la plataforma de monitoreo de bases de datos y auditoria de consultas Dataguard.

**URL Base:** `https://apidg.runyx.io/api`

---

## Indice

1. [Autenticacion](#autenticacion)
2. [Gestion de Servidores](#gestion-de-servidores)
3. [Gestion de Bases de Datos](#gestion-de-bases-de-datos)
4. [Gestion de Permisos](#gestion-de-permisos)
5. [Gestion de Usuarios de Servicio](#gestion-de-usuarios-de-servicio)
6. [Gestion de Agentes](#gestion-de-agentes)
7. [Auditoria de Consultas](#auditoria-de-consultas)
8. [Gestion de Usuarios](#gestion-de-usuarios)
9. [Salud y Monitoreo](#salud-y-monitoreo)
10. [Manejo de Errores](#manejo-de-errores)
11. [Limites de Tasa](#limites-de-tasa)

---

## Autenticacion

La API utiliza autenticacion por Clave de API para acceso programatico.

### Autenticacion por Clave de API

Todas las solicitudes deben incluir los siguientes headers:

```bash
X-API-Key: runyx_ak_tu_clave_api
X-API-Secret: runyx_sk_tu_clave_secreta
```

**Ejemplo:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_tu_clave_api" \
  -H "X-API-Secret: runyx_sk_tu_clave_secreta"
```

### Alcances Disponibles

Las claves de API tienen permisos basados en alcances:

| Alcance | Descripcion |
|---------|-------------|
| `servers:read` | Leer informacion de servidores |
| `servers:write` | Crear, actualizar, eliminar servidores |
| `users:read` | Leer informacion de usuarios |
| `users:write` | Crear, actualizar, eliminar usuarios |
| `permissions:read` | Leer permisos |
| `permissions:write` | Otorgar permisos |
| `permissions:delete` | Revocar permisos |
| `agents:read` | Leer informacion de agentes |
| `agents:write` | Gestionar agentes |
| `audit:read` | Leer logs de auditoria |
| `query_audit:read` | Leer logs de auditoria de consultas |
| `service_users:read` | Leer usuarios de servicio |
| `service_users:write` | Gestionar usuarios de servicio |

---

## Gestion de Servidores

Gestionar servidores de bases de datos a monitorear.

### Listar Servidores

```http
GET /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Ejemplo:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

**Respuesta:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PostgreSQL Produccion",
      "host": "db.ejemplo.com",
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

### Obtener Detalles del Servidor

```http
GET /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Ejemplo:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Crear Servidor (Modo CLOUD)

Crear un servidor que sera monitoreado directamente desde la nube. **El descubrimiento automatico de bases de datos, esquemas y tablas se realiza automaticamente.**

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "PostgreSQL Produccion",
  "host": "db.ejemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "usuario_dataguard",
  "password": "contrasena-segura",
  "database": "miapp",
  "environment": "PRODUCTION",
  "useSsl": true,
  "syncEnabled": true
}
```

**Tipos de Base de Datos:**
| Tipo | Descripcion |
|------|-------------|
| `postgres` o `postgresql` | PostgreSQL |
| `mysql` | MySQL |
| `mariadb` | MariaDB |
| `sqlserver` o `mssql` | Microsoft SQL Server |
| `mongodb` | MongoDB |
| `oracle` | Oracle Database |
| `cassandra` | Apache Cassandra |

**Valores de Ambiente:**
| Valor | Descripcion |
|-------|-------------|
| `DEV` | Ambiente de desarrollo |
| `QA` | Calidad / Pruebas |
| `PRODUCTION` | Ambiente de produccion |

**Ejemplo:**
```bash
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "PostgreSQL Produccion",
    "host": "db.ejemplo.com",
    "port": 5432,
    "type": "postgres",
    "username": "usuario_dataguard",
    "password": "contrasena-segura",
    "environment": "PRODUCTION",
    "useSsl": true
  }'
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "server": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PostgreSQL Produccion",
      "host": "db.ejemplo.com",
      "port": 5432,
      "type": "postgres",
      "status": "active",
      "environment": "PRODUCTION",
      "management_mode": "CLOUD"
    },
    "discovery": {
      "success": true,
      "mode": "CLOUD",
      "message": "Discovered 5 databases",
      "metadata": {
        "databases": [
          {"name": "miapp", "owner": "postgres", "size_mb": 1024, "table_count": 45}
        ]
      }
    }
  }
}
```

### Crear Servidor (Modo AGENT)

Crear un servidor que sera monitoreado via agente on-premise. **El descubrimiento automatico es realizado por el agente.**

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "PostgreSQL Interno",
  "host": "192.168.1.100",
  "port": 5432,
  "type": "postgres",
  "username": "usuario_dataguard",
  "password": "contrasena-segura",
  "database": "app_interno",
  "environment": "PRODUCTION",
  "useSsl": false,
  "syncEnabled": true,
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid-de-tabla-agents"
}
```

**Ejemplo:**
```bash
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "PostgreSQL Interno",
    "host": "192.168.1.100",
    "port": 5432,
    "type": "postgres",
    "username": "usuario_dataguard",
    "password": "contrasena-segura",
    "environment": "PRODUCTION",
    "managementMode": "AGENT",
    "assignedAgentId": "13f84c6e-5448-47a4-bbdf-bd2110669a55"
  }'
```

**Respuesta (modo AGENT):**
```json
{
  "success": true,
  "data": {
    "server": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PostgreSQL Interno",
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

### Actualizar Servidor

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

**Ejemplo:**
```bash
curl -X PUT "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{"syncEnabled": true}'
```

### Eliminar Servidor

```http
DELETE /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Ejemplo:**
```bash
curl -X DELETE "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Probar Conexion

Probar conexion a un servidor antes de crearlo.

```http
POST /api/servers/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "host": "db.ejemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "contrasena",
  "database": "mibase",
  "management_mode": "CLOUD"
}
```

### Probar Conexion de Servidor Existente

```http
POST /api/servers/:id/test
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Sincronizar Bases de Datos del Servidor

Activar descubrimiento/sincronizacion de bases de datos para un servidor.

```http
POST /api/servers/:id/sync-databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Metricas del Servidor

Obtener metricas en tiempo real de un servidor.

```http
GET /api/servers/:id/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gestion de Bases de Datos

### Listar Bases de Datos del Servidor

```http
GET /api/servers/:id/databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Respuesta:**
```json
{
  "success": true,
  "data": [
    {
      "name": "produccion_db",
      "owner": "postgres",
      "size_mb": 1024,
      "table_count": 45
    },
    {
      "name": "analytics_db",
      "owner": "usuario_analytics",
      "size_mb": 5120,
      "table_count": 128
    }
  ]
}
```

### Listar Esquemas de la Base de Datos

```http
GET /api/servers/:id/databases/:dbName/schemas
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Listar Tablas de la Base de Datos

```http
GET /api/servers/:id/databases/:dbName/tables
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `schema` | string | Filtrar por nombre del esquema |

---

## Gestion de Permisos

Gestionar permisos de base de datos para usuarios.

### Listar Permisos

```http
GET /api/permissions
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `userId` | UUID | Filtrar por ID del usuario |
| `databaseId` | UUID | Filtrar por ID de la base de datos |
| `serverId` | UUID | Filtrar por ID del servidor |
| `permissionType` | string | Filtrar por tipo de permiso |
| `status` | string | Filtrar por estado (active, revoked) |
| `includeExpired` | boolean | Incluir permisos expirados |

### Obtener Detalles del Permiso

```http
GET /api/permissions/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Otorgar Permiso

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
  "reason": "Acceso para informe trimestral"
}
```

**Tipos de Permiso:**
| Tipo | Descripcion |
|------|-------------|
| `READ` | Acceso de solo lectura |
| `WRITE` | Acceso de lectura y escritura |
| `ADMIN` | Acceso administrativo completo |
| `CUSTOM` | Conjunto de permisos personalizado |

**Ejemplo:**
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

### Otorgar Permisos Masivos

Otorgar el mismo permiso a multiples usuarios.

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

### Actualizar Permiso

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

### Revocar Permiso

```http
DELETE /api/permissions/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "reason": "Proyecto completado"
}
```

### Verificar Permiso

Verificar si un usuario tiene un permiso especifico.

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

### Sincronizar Permisos

Sincronizar permisos entre Dataguard y el servidor de base de datos real.

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

**Tipos de Sincronizacion:**
| Tipo | Descripcion |
|------|-------------|
| `full` | Sincronizacion completa de todos los permisos |
| `partial` | Sincronizar solo permisos modificados |

### Obtener Estadisticas de Permisos

```http
GET /api/permissions/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Permisos por Expirar

```http
GET /api/permissions/expiring?days=7
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Discrepancias de Permisos

Encontrar diferencias entre permisos de Dataguard y permisos reales de la base de datos.

```http
GET /api/permissions/servers/:serverId/discrepancies
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gestion de Usuarios de Servicio

Gestionar cuentas/usuarios de servicio en servidores de bases de datos.

### Listar Usuarios de Servicio

```http
GET /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `databaseId` | UUID | Filtrar por base de datos |
| `serverId` | UUID | Filtrar por servidor |
| `status` | string | Filtrar por estado |
| `username` | string | Filtrar por nombre de usuario |
| `needsRotation` | boolean | Filtrar usuarios que necesitan rotacion de contrasena |

### Obtener Detalles del Usuario de Servicio

```http
GET /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Crear Usuario de Servicio

Crear un nuevo usuario de base de datos en un servidor.

```http
POST /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_readonly",
  "password": "ContrasenaSegura123!",
  "privileges": ["SELECT", "CONNECT"],
  "description": "Usuario de solo lectura para aplicacion de informes",
  "expiresAt": "2025-12-31T23:59:59Z",
  "rotationIntervalDays": 90
}
```

**Privilegios Comunes:**
| Privilegio | Descripcion |
|------------|-------------|
| `SELECT` | Leer datos de las tablas |
| `INSERT` | Insertar nuevas filas |
| `UPDATE` | Actualizar filas existentes |
| `DELETE` | Eliminar filas |
| `CREATE` | Crear tablas/objetos |
| `DROP` | Eliminar tablas/objetos |
| `CONNECT` | Conectar a la base de datos |
| `EXECUTE` | Ejecutar funciones/procedimientos |
| `ALL` | Todos los privilegios |

**Ejemplo:**
```bash
curl -X POST "https://apidg.runyx.io/api/service-users" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "databaseId": "database-uuid",
    "username": "app_service",
    "privileges": ["SELECT", "INSERT", "UPDATE"],
    "description": "Cuenta de servicio de la aplicacion",
    "rotationIntervalDays": 30
  }'
```

### Actualizar Usuario de Servicio

```http
PUT /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Descripcion actualizada",
  "rotationIntervalDays": 60
}
```

### Eliminar Usuario de Servicio

Elimina el usuario del servidor de base de datos.

```http
DELETE /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotar Contrasena

Cambiar la contrasena de un usuario de servicio.

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "generatePassword": true
}
```

O especificar una nueva contrasena:

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "NuevaContrasenaSegura456!"
}
```

### Rotacion Masiva de Contrasenas

Rotar contrasenas de multiples usuarios de servicio.

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

### Probar Conexion del Usuario de Servicio

```http
POST /api/service-users/:id/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Clonar Usuario de Servicio

Clonar un usuario de servicio existente a otra base de datos.

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

### Obtener Estadisticas de Usuarios de Servicio

```http
GET /api/service-users/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Usuarios que Necesitan Rotacion

```http
GET /api/service-users/needing-rotation
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gestion de Agentes

Gestionar agentes on-premise para monitorear bases de datos internas.

### Listar Agentes

```http
GET /api/agents
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `status` | string | Filtrar por estado (online, offline, error) |
| `limit` | number | Resultados por pagina |
| `offset` | number | Offset de paginacion |

### Obtener Detalles del Agente

```http
GET /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Crear Agente

```http
POST /api/agents
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Agente-DC1",
  "description": "Agente para Datacenter 1",
  "capabilities": ["postgres", "mysql"]
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "id": "13f84c6e-5448-47a4-bbdf-bd2110669a55",
    "agentId": "0ad06bb9-1f87-4398-9810-f1293974df23",
    "name": "Agente-DC1",
    "apiKey": "agent-api-key",
    "secretKey": "agent-secret-key",
    "status": "offline"
  },
  "message": "Agente creado. Configure el agente con estas credenciales."
}
```

### Actualizar Agente

```http
PATCH /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Agente-DC1-Actualizado",
  "description": "Descripcion actualizada"
}
```

### Eliminar Agente

```http
DELETE /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotar Clave del Agente

```http
POST /api/agents/:agentId/rotate-key
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Tareas del Agente

```http
GET /api/agents/:agentId/tasks
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Crear Tarea del Agente

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

**Tipos de Tarea:**
| Tipo | Descripcion |
|------|-------------|
| `SYNC_REQUEST` | Sincronizar metadatos del servidor |
| `TEST_CONNECTION_REQUEST` | Probar conexion del servidor |
| `CREATE_USER_REQUEST` | Crear usuario de base de datos |
| `GRANT_PERMISSIONS_REQUEST` | Otorgar permisos |
| `REVOKE_PERMISSIONS_REQUEST` | Revocar permisos |
| `REMOVE_USER_REQUEST` | Eliminar usuario de base de datos |
| `COLLECT_METRICS_REQUEST` | Recolectar metricas del servidor |
| `DISCOVER_SERVER_METADATA_REQUEST` | Descubrir bases de datos/esquemas |

### Obtener Resultado de la Tarea

```http
GET /api/agents/tasks/:taskId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Cancelar Tarea

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Metricas del Agente

```http
GET /api/agents/:agentId/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Vision General de Estadisticas de Agentes

```http
GET /api/agents/stats/overview
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Auditoria de Consultas

Monitorear y auditar consultas de bases de datos.

### Obtener Logs de Consultas

```http
GET /api/query-audit/servers/:serverId/logs
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `queryType` | string | Filtrar por tipo de consulta (SELECT, INSERT, UPDATE, DELETE) |
| `username` | string | Filtrar por nombre de usuario de la base de datos |
| `database` | string | Filtrar por nombre de la base de datos |
| `startDate` | ISO8601 | Inicio del rango de fechas |
| `endDate` | ISO8601 | Fin del rango de fechas |
| `success` | boolean | Filtrar por estado de exito |
| `page` | number | Numero de pagina |
| `limit` | number | Resultados por pagina |

### Exportar Logs de Consultas

```http
GET /api/query-audit/servers/:serverId/export?format=csv
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `format` | string | Formato de exportacion: `csv` o `json` |

### Recolectar Consultas

Activar recoleccion manual de consultas de un servidor.

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

### Verificar Disponibilidad de Auditoria de Consultas

```http
GET /api/query-audit/servers/:serverId/availability
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Habilitar Auditoria de Consultas

```http
POST /api/query-audit/servers/:serverId/enable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Deshabilitar Auditoria de Consultas

```http
POST /api/query-audit/servers/:serverId/disable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gestion de Usuarios

Gestionar usuarios de la plataforma dentro de su tenant.

### Listar Usuarios

```http
GET /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obtener Detalles del Usuario

```http
GET /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Crear Usuario

```http
POST /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "email": "nuevousuario@empresa.com",
  "username": "nuevousuario",
  "password": "ContrasenaSegura123!",
  "fullName": "Nuevo Usuario",
  "role": "USER"
}
```

**Roles de Usuario:**
| Rol | Descripcion |
|-----|-------------|
| `ADMIN` | Administracion completa del tenant |
| `USER` | Acceso de usuario estandar |
| `VIEWER` | Acceso de solo lectura |
| `APPROVER` | Puede aprobar solicitudes de acceso |

### Actualizar Usuario

```http
PUT /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "email": "actualizado@empresa.com",
  "username": "usuarioactualizado",
  "role": "ADMIN"
}
```

### Eliminar Usuario

```http
DELETE /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Restablecer Contrasena de Usuario

```http
POST /api/users/:id/reset-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "ContrasenaTemporal123!"
}
```

### Obtener Estadisticas de Usuarios

```http
GET /api/users/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Salud y Monitoreo

### Verificacion Basica de Salud

```http
GET /health
```

**Respuesta:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00.000Z"
}
```

### Probe de Liveness (Kubernetes)

```http
GET /health/live
```

### Probe de Readiness

```http
GET /health/ready
```

---

## Manejo de Errores

Todos los errores de la API siguen un formato consistente:

```json
{
  "success": false,
  "message": "Descripcion del error",
  "errors": [
    {
      "field": "email",
      "message": "Formato de correo electronico invalido"
    }
  ],
  "code": "VALIDATION_ERROR"
}
```

### Codigos de Estado HTTP

| Codigo | Descripcion |
|--------|-------------|
| `200` | Exito |
| `201` | Creado |
| `400` | Solicitud Invalida - Entrada invalida |
| `401` | No Autorizado - Autenticacion invalida o ausente |
| `403` | Prohibido - Permisos insuficientes |
| `404` | No Encontrado - El recurso no existe |
| `409` | Conflicto - El recurso ya existe |
| `422` | Entidad No Procesable - Validacion fallida |
| `429` | Demasiadas Solicitudes - Limite de tasa excedido |
| `500` | Error Interno del Servidor |

### Codigos de Error Comunes

| Codigo | Descripcion |
|--------|-------------|
| `VALIDATION_ERROR` | Validacion de entrada fallida |
| `AUTHENTICATION_ERROR` | Autenticacion fallida |
| `AUTHORIZATION_ERROR` | Permiso denegado |
| `NOT_FOUND` | Recurso no encontrado |
| `DUPLICATE_ENTRY` | El recurso ya existe |
| `RATE_LIMIT_EXCEEDED` | Demasiadas solicitudes |
| `CONNECTION_ERROR` | Conexion a base de datos fallida |

---

## Limites de Tasa

La API implementa limites de tasa para garantizar uso justo:

| Tipo de Endpoint | Limite | Ventana |
|------------------|--------|---------|
| API General | 300 solicitudes | 15 minutos |
| Clave de API (Personalizada) | Configurable | 15 minutos |

Cuando se excede el limite de tasa, la API retorna:

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705315800

{
  "success": false,
  "message": "Demasiadas solicitudes, por favor intente de nuevo mas tarde",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

---

## Paginacion

Los endpoints de listado soportan paginacion:

```http
GET /api/servers?limit=20&offset=40
```

**Respuesta:**
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

## Ejemplos de SDK

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

    def listar_servidores(self):
        response = requests.get(f"{self.base_url}/servers", headers=self.headers)
        return response.json()

    def crear_servidor(self, datos_servidor):
        response = requests.post(
            f"{self.base_url}/servers",
            headers=self.headers,
            json=datos_servidor
        )
        return response.json()

    def otorgar_permiso(self, datos_permiso):
        response = requests.post(
            f"{self.base_url}/permissions",
            headers=self.headers,
            json=datos_permiso
        )
        return response.json()

# Uso
client = DataguardClient(
    api_key="runyx_ak_...",
    secret_key="runyx_sk_..."
)

servidores = client.listar_servidores()
print(servidores)
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

  async listarServidores() {
    const response = await this.client.get('/servers');
    return response.data;
  }

  async crearServidor(datosServidor) {
    const response = await this.client.post('/servers', datosServidor);
    return response.data;
  }

  async otorgarPermiso(datosPermiso) {
    const response = await this.client.post('/permissions', datosPermiso);
    return response.data;
  }
}

// Uso
const client = new DataguardClient(
  'runyx_ak_...',
  'runyx_sk_...'
);

client.listarServidores().then(servidores => console.log(servidores));
```

---

## Soporte

- **Documentacion:** https://docs.runyx.io
- **Estado de la API:** https://status.runyx.io
- **Correo de Soporte:** support@runyx.io

---

*Ultima actualizacion: Diciembre de 2025*
