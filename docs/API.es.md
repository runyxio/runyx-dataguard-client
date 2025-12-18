# Documentacion de la API Dataguard

Documentacion completa de la API REST para la plataforma de monitoreo de bases de datos y auditoria de consultas Dataguard.

**URL Base:** `https://apidg.runyx.io/api`

---

## Indice

1. [Autenticacion](#autenticacion)
2. [Claves de API](#claves-de-api)
3. [Gestion de Servidores](#gestion-de-servidores)
4. [Gestion de Bases de Datos](#gestion-de-bases-de-datos)
5. [Gestion de Permisos](#gestion-de-permisos)
6. [Gestion de Usuarios de Servicio](#gestion-de-usuarios-de-servicio)
7. [Gestion de Agentes](#gestion-de-agentes)
8. [Auditoria de Consultas](#auditoria-de-consultas)
9. [Gestion de Usuarios](#gestion-de-usuarios)
10. [Salud y Monitoreo](#salud-y-monitoreo)
11. [Manejo de Errores](#manejo-de-errores)
12. [Limites de Tasa](#limites-de-tasa)

---

## Autenticacion

La API soporta dos metodos de autenticacion:

### 1. JWT (Bearer Token)

Usado para aplicaciones web y sesiones interactivas.

```bash
# Iniciar sesion para obtener tokens
curl -X POST https://apidg.runyx.io/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@empresa.com",
    "password": "tu-contrasena"
  }'

# Respuesta
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "user": {
      "id": "uuid",
      "email": "usuario@empresa.com",
      "role": "ADMIN"
    }
  }
}

# Usar el token en solicitudes posteriores
curl -X GET https://apidg.runyx.io/api/servers \
  -H "Authorization: Bearer eyJhbG..."
```

### 2. Claves de API

Usado para acceso programatico y automatizacion. Las claves de API proporcionan control de acceso basado en alcances.

```bash
# Usar autenticacion por Clave de API
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_tu_clave_api" \
  -H "X-API-Secret: runyx_sk_tu_clave_secreta"
```

---

## Endpoints de Autenticacion

### Iniciar Sesion

Autenticar usuario con correo electronico y contrasena.

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "usuario@empresa.com",
  "password": "tu-contrasena"
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "expiresIn": 21600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "usuario@empresa.com",
      "username": "juanperez",
      "fullName": "Juan Perez",
      "role": "ADMIN",
      "tenantId": "tenant-uuid"
    }
  }
}
```

### Registro (Crear Tenant y Usuario)

Crear un nuevo tenant con el primer usuario administrador.

```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "admin@nuevaempresa.com",
  "password": "ContrasenaSegura123!",
  "fullName": "Juan Perez",
  "companyName": "Nueva Empresa S.A.",
  "planId": "plan-uuid"
}
```

**Requisitos de Contrasena:**
- Minimo de 8 caracteres
- Al menos una letra mayuscula
- Al menos una letra minuscula
- Al menos un numero
- Al menos un caracter especial

### Actualizar Token

Actualizar un token de acceso expirado.

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbG..."
}
```

### Olvide mi Contrasena

Solicitar correo de restablecimiento de contrasena.

```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "usuario@empresa.com"
}
```

### Restablecer Contrasena

Restablecer contrasena usando el token del correo.

```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "token": "token-de-restablecimiento-del-correo",
  "password": "NuevaContrasenaSegura123!"
}
```

### Verificar Token

Verificar si el token actual es valido.

```http
GET /api/auth/verify
Authorization: Bearer eyJhbG...
```

### Cerrar Sesion

Invalidar la sesion actual.

```http
POST /api/auth/logout
Authorization: Bearer eyJhbG...
```

---

## Claves de API

Las claves de API proporcionan acceso programatico con permisos granulares.

### Listar Claves de API

```http
GET /api/api-keys
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `userId` | UUID | Filtrar por ID del usuario |
| `includeRevoked` | boolean | Incluir claves revocadas |
| `includeExpired` | boolean | Incluir claves expiradas |

### Crear Clave de API

```http
POST /api/api-keys
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Integracion Produccion",
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

**Alcances Disponibles:**
| Alcance | Descripcion |
|---------|-------------|
| `servers:read` | Leer informacion de servidores |
| `servers:write` | Crear, actualizar, eliminar servidores |
| `users:read` | Leer informacion de usuarios |
| `users:write` | Crear, actualizar, eliminar usuarios |
| `permissions:read` | Leer permisos |
| `permissions:write` | Otorgar permisos |
| `permissions:delete` | Revocar permisos |
| `api_keys:read` | Leer claves de API |
| `api_keys:write` | Gestionar claves de API |
| `agents:read` | Leer informacion de agentes |
| `agents:write` | Gestionar agentes |
| `audit:read` | Leer logs de auditoria |
| `query_audit:read` | Leer logs de auditoria de consultas |
| `service_users:read` | Leer usuarios de servicio |
| `service_users:write` | Gestionar usuarios de servicio |

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "id": "key-uuid",
    "name": "Integracion Produccion",
    "apiKey": "runyx_ak_e9dea10edac7d072...",
    "secretKey": "runyx_sk_56abbdb203712cc9...",
    "scopes": ["servers:read", "servers:write"],
    "expiresAt": "2026-01-01T00:00:00.000Z"
  },
  "message": "Clave de API creada. Guarde la clave secreta de forma segura - no se mostrara nuevamente."
}
```

### Rotar Clave de API

Generar nuevas credenciales para una clave existente.

```http
POST /api/api-keys/:id/rotate
Authorization: Bearer eyJhbG...
```

### Revocar Clave de API

```http
DELETE /api/api-keys/:id
Authorization: Bearer eyJhbG...
```

---

## Gestion de Servidores

Gestionar servidores de bases de datos a monitorear.

### Listar Servidores

```http
GET /api/servers
Authorization: Bearer eyJhbG...
```

**Usando Clave de API:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Obtener Detalles del Servidor

```http
GET /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Crear Servidor (Modo CLOUD)

Crear un servidor que sera monitoreado directamente desde la nube.

```http
POST /api/servers
Authorization: Bearer eyJhbG...
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

### Crear Servidor (Modo AGENT)

Crear un servidor que sera monitoreado via agente on-premise.

```http
POST /api/servers
Authorization: Bearer eyJhbG...
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

### Crear Servidor v2 (Con Auto-Discovery)

Crea un servidor y automaticamente descubre bases de datos, esquemas y tablas.

```http
POST /api/servers/v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "DB Produccion",
  "host": "db.ejemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "contrasena",
  "environment": "PRODUCTION"
}
```

### Actualizar Servidor

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

### Eliminar Servidor

```http
DELETE /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Probar Conexion

Probar conexion a un servidor antes de crearlo.

```http
POST /api/servers/test-connection
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Sincronizar Bases de Datos del Servidor

Activar descubrimiento/sincronizacion de bases de datos para un servidor.

```http
POST /api/servers/:id/sync-databases
Authorization: Bearer eyJhbG...
```

### Obtener Metricas del Servidor

Obtener metricas en tiempo real de un servidor.

```http
GET /api/servers/:id/metrics
Authorization: Bearer eyJhbG...
```

---

## Gestion de Bases de Datos

### Listar Bases de Datos del Servidor

```http
GET /api/servers/:id/databases
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Listar Tablas de la Base de Datos

```http
GET /api/servers/:id/databases/:dbName/tables
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
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
| `consolidated` | boolean | Retornar vista consolidada |

### Obtener Detalles del Permiso

```http
GET /api/permissions/:id
Authorization: Bearer eyJhbG...
```

### Otorgar Permiso

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

### Otorgar Permisos Masivos

Otorgar el mismo permiso a multiples usuarios.

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

### Actualizar Permiso

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

### Revocar Permiso

```http
DELETE /api/permissions/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "reason": "Proyecto completado"
}
```

### Verificar Permiso

Verificar si un usuario tiene un permiso especifico.

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

### Sincronizar Permisos

Sincronizar permisos entre Dataguard y el servidor de base de datos real.

```http
POST /api/permissions/sync
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Obtener Permisos por Expirar

```http
GET /api/permissions/expiring
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Por defecto | Descripcion |
|-----------|------|-------------|-------------|
| `days` | number | 7 | Dias hasta la expiracion (1-365) |

### Obtener Discrepancias de Permisos

Encontrar diferencias entre permisos de Dataguard y permisos reales de la base de datos.

```http
GET /api/permissions/servers/:serverId/discrepancies
Authorization: Bearer eyJhbG...
```

---

## Gestion de Usuarios de Servicio

Gestionar cuentas/usuarios de servicio en servidores de bases de datos.

### Listar Usuarios de Servicio

```http
GET /api/service-users
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `databaseId` | UUID | Filtrar por base de datos |
| `serverId` | UUID | Filtrar por servidor |
| `status` | string | Filtrar por estado |
| `username` | string | Filtrar por nombre de usuario |
| `needsRotation` | boolean | Filtrar usuarios que necesitan rotacion de contrasena |
| `expiringDays` | number | Filtrar por dias hasta que expire la contrasena |

### Obtener Detalles del Usuario de Servicio

```http
GET /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Crear Usuario de Servicio

Crear un nuevo usuario de base de datos en un servidor.

```http
POST /api/service-users
Authorization: Bearer eyJhbG...
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
| `REFERENCES` | Crear claves foraneas |
| `TRIGGER` | Crear triggers |
| `ALL` | Todos los privilegios |

### Crear Usuario de Servicio v2 (Con Propagacion)

Crea un usuario de servicio y lo propaga a todas las bases de datos relevantes.

```http
POST /api/service-users-v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_service",
  "privileges": ["SELECT", "INSERT", "UPDATE"],
  "description": "Cuenta de servicio de la aplicacion",
  "rotationIntervalDays": 30
}
```

### Actualizar Usuario de Servicio

```http
PUT /api/service-users/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Descripcion actualizada",
  "expiresAt": "2026-06-30T23:59:59Z",
  "rotationIntervalDays": 60
}
```

### Eliminar Usuario de Servicio

Elimina el usuario del servidor de base de datos.

```http
DELETE /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Rotar Contrasena

Cambiar la contrasena de un usuario de servicio.

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "NuevaContrasenaSegura456!",
  "generatePassword": false
}
```

O generar una contrasena aleatoria:

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "generatePassword": true
}
```

### Rotacion Masiva de Contrasenas

Rotar contrasenas de multiples usuarios de servicio.

```http
POST /api/service-users/bulk-rotate
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "serviceUserIds": ["user-uuid-1", "user-uuid-2"],
  "generatePasswords": true
}
```

### Auto-Rotar Contrasenas

Rotar automaticamente contrasenas de usuarios que han excedido su intervalo de rotacion.

```http
POST /api/service-users/auto-rotate
Authorization: Bearer eyJhbG...
```

### Probar Conexion del Usuario de Servicio

```http
POST /api/service-users/:id/test-connection
Authorization: Bearer eyJhbG...
```

### Clonar Usuario de Servicio

Clonar un usuario de servicio existente a otra base de datos.

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

### Obtener Estadisticas de Usuarios de Servicio

```http
GET /api/service-users/stats
Authorization: Bearer eyJhbG...
```

### Obtener Usuarios que Necesitan Rotacion

```http
GET /api/service-users/needing-rotation
Authorization: Bearer eyJhbG...
```

### Obtener Usuarios con Contrasenas por Expirar

```http
GET /api/service-users/expiring
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Por defecto | Descripcion |
|-----------|------|-------------|-------------|
| `days` | number | 7 | Dias hasta la expiracion (1-365) |

---

## Gestion de Agentes

Gestionar agentes on-premise para monitorear bases de datos internas.

### Listar Agentes

```http
GET /api/agents
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Crear Agente

```http
POST /api/agents
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Agente-DC1",
  "description": "Agente para Datacenter 1",
  "capabilities": ["postgres", "mysql"],
  "config": {
    "maxConnections": 10
  }
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "id": "agent-uuid",
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
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Agente-DC1-Actualizado",
  "description": "Descripcion actualizada"
}
```

### Eliminar Agente

```http
DELETE /api/agents/:agentId
Authorization: Bearer eyJhbG...
```

### Rotar Clave del Agente

```http
POST /api/agents/:agentId/rotate-key
Authorization: Bearer eyJhbG...
```

### Obtener Tareas del Agente

```http
GET /api/agents/:agentId/tasks
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `status` | string | Filtrar por estado |
| `taskType` | string | Filtrar por tipo de tarea |
| `limit` | number | Resultados por pagina |
| `offset` | number | Offset de paginacion |

### Crear Tarea del Agente

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
Authorization: Bearer eyJhbG...
```

### Cancelar Tarea

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
Authorization: Bearer eyJhbG...
```

### Reintentar Tarea Fallida

```http
POST /api/agents/:agentId/tasks/:taskId/retry
Authorization: Bearer eyJhbG...
```

### Obtener Metricas del Agente

```http
GET /api/agents/:agentId/metrics
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `startDate` | ISO8601 | Inicio del rango de fechas |
| `endDate` | ISO8601 | Fin del rango de fechas |

### Obtener Vision General de Estadisticas de Agentes

```http
GET /api/agents/stats/overview
Authorization: Bearer eyJhbG...
```

---

## Auditoria de Consultas

Monitorear y auditar consultas de bases de datos.

### Obtener Logs de Consultas

```http
GET /api/query-audit/servers/:serverId/logs
Authorization: Bearer eyJhbG...
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
GET /api/query-audit/servers/:serverId/export
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `format` | string | Formato de exportacion: `csv` o `json` |
| Filtros adicionales | | Mismos de Obtener Logs de Consultas |

### Recolectar Consultas

Activar recoleccion manual de consultas de un servidor.

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

### Verificar Disponibilidad de Auditoria de Consultas

```http
GET /api/query-audit/servers/:serverId/availability
Authorization: Bearer eyJhbG...
```

### Habilitar Auditoria de Consultas

```http
POST /api/query-audit/servers/:serverId/enable
Authorization: Bearer eyJhbG...
```

### Deshabilitar Auditoria de Consultas

```http
POST /api/query-audit/servers/:serverId/disable
Authorization: Bearer eyJhbG...
```

---

## Gestion de Usuarios

Gestionar usuarios de la plataforma dentro de su tenant.

### Listar Usuarios

```http
GET /api/users
Authorization: Bearer eyJhbG...
```

### Obtener Perfil del Usuario Actual

```http
GET /api/users/profile
Authorization: Bearer eyJhbG...
```

### Obtener Detalles del Usuario

```http
GET /api/users/:id
Authorization: Bearer eyJhbG...
```

### Crear Usuario

```http
POST /api/users
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Cambiar Contrasena

Cambiar su propia contrasena.

```http
POST /api/users/change-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "currentPassword": "ContrasenaAntigua123!",
  "newPassword": "ContrasenaNueva456!"
}
```

### Restablecer Contrasena de Usuario (Admin)

Restablecer la contrasena de otro usuario.

```http
POST /api/users/:id/reset-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "ContrasenaTemporal123!"
}
```

### Obtener Estadisticas de Usuarios

```http
GET /api/users/stats
Authorization: Bearer eyJhbG...
```

### Listar Sesiones Activas

```http
GET /api/users/sessions
Authorization: Bearer eyJhbG...
```

### Revocar Sesion

```http
DELETE /api/users/sessions/:sessionId
Authorization: Bearer eyJhbG...
```

### Revocar Todas las Sesiones

Revocar todas las sesiones excepto la actual.

```http
DELETE /api/users/sessions
Authorization: Bearer eyJhbG...
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

### Salud Detallada (Solo Admin)

```http
GET /health/detailed
Authorization: Bearer eyJhbG...
```

**Respuesta:**
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
| Autenticacion | 10 solicitudes | 1 minuto |
| Verificacion 2FA | 5 intentos | 15 minutos |
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

## Webhooks

Configure webhooks para recibir notificaciones en tiempo real sobre eventos.

### Eventos de Webhook

| Evento | Descripcion |
|--------|-------------|
| `server.created` | Nuevo servidor agregado |
| `server.deleted` | Servidor eliminado |
| `permission.granted` | Permiso otorgado |
| `permission.revoked` | Permiso revocado |
| `permission.expiring` | Permiso por expirar |
| `user.created` | Nuevo usuario creado |
| `service_user.created` | Usuario de servicio creado |
| `service_user.password_rotated` | Contrasena rotada |
| `agent.connected` | Agente se conecto |
| `agent.disconnected` | Agente se desconecto |
| `query_audit.anomaly` | Consulta inusual detectada |

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

### cURL

```bash
# Listar todos los servidores
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."

# Crear un servidor
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "DB Produccion",
    "host": "db.ejemplo.com",
    "port": 5432,
    "type": "postgres",
    "username": "admin",
    "password": "contrasena",
    "environment": "PRODUCTION"
  }'

# Otorgar permiso
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

## Soporte

- **Documentacion:** https://docs.runyx.io
- **Estado de la API:** https://status.runyx.io
- **Correo de Soporte:** support@runyx.io
- **GitHub Issues:** https://github.com/runyxio/dataguard/issues

---

*Ultima actualizacion: Diciembre de 2025*
