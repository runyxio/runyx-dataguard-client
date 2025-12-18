# Documentacao da API Dataguard

Documentacao completa da API REST para a plataforma de monitoramento de banco de dados e auditoria de queries Dataguard.

**URL Base:** `https://apidg.runyx.io/api`

---

## Indice

1. [Autenticacao](#autenticacao)
2. [Gerenciamento de Servidores](#gerenciamento-de-servidores)
3. [Gerenciamento de Bancos de Dados](#gerenciamento-de-bancos-de-dados)
4. [Gerenciamento de Permissoes](#gerenciamento-de-permissoes)
5. [Gerenciamento de Usuarios de Servico](#gerenciamento-de-usuarios-de-servico)
6. [Gerenciamento de Agentes](#gerenciamento-de-agentes)
7. [Auditoria de Queries](#auditoria-de-queries)
8. [Gerenciamento de Usuarios](#gerenciamento-de-usuarios)
9. [Saude e Monitoramento](#saude-e-monitoramento)
10. [Tratamento de Erros](#tratamento-de-erros)
11. [Limites de Taxa](#limites-de-taxa)

---

## Autenticacao

A API utiliza autenticacao por Chave de API para acesso programatico.

### Autenticacao por Chave de API

Todas as requisicoes devem incluir os seguintes headers:

```bash
X-API-Key: runyx_ak_sua_chave_api
X-API-Secret: runyx_sk_sua_chave_secreta
```

**Exemplo:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_sua_chave_api" \
  -H "X-API-Secret: runyx_sk_sua_chave_secreta"
```

### Escopos Disponiveis

As chaves de API possuem permissoes baseadas em escopos:

| Escopo | Descricao |
|--------|-----------|
| `servers:read` | Ler informacoes de servidores |
| `servers:write` | Criar, atualizar, excluir servidores |
| `users:read` | Ler informacoes de usuarios |
| `users:write` | Criar, atualizar, excluir usuarios |
| `permissions:read` | Ler permissoes |
| `permissions:write` | Conceder permissoes |
| `permissions:delete` | Revogar permissoes |
| `agents:read` | Ler informacoes de agentes |
| `agents:write` | Gerenciar agentes |
| `audit:read` | Ler logs de auditoria |
| `query_audit:read` | Ler logs de auditoria de queries |
| `service_users:read` | Ler usuarios de servico |
| `service_users:write` | Gerenciar usuarios de servico |

---

## Gerenciamento de Servidores

Gerenciar servidores de banco de dados a serem monitorados.

### Listar Servidores

```http
GET /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Exemplo:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PostgreSQL Producao",
      "host": "db.exemplo.com",
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

### Obter Detalhes do Servidor

```http
GET /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Exemplo:**
```bash
curl -X GET "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Criar Servidor (Modo CLOUD)

Criar um servidor que sera monitorado diretamente da nuvem. **A descoberta automatica de bancos de dados, schemas e tabelas e realizada automaticamente.**

```http
POST /api/servers
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "PostgreSQL Producao",
  "host": "db.exemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "usuario_dataguard",
  "password": "senha-segura",
  "database": "meuapp",
  "environment": "PRODUCTION",
  "useSsl": true,
  "syncEnabled": true
}
```

**Tipos de Banco de Dados:**
| Tipo | Descricao |
|------|-----------|
| `postgres` ou `postgresql` | PostgreSQL |
| `mysql` | MySQL |
| `mariadb` | MariaDB |
| `sqlserver` ou `mssql` | Microsoft SQL Server |
| `mongodb` | MongoDB |
| `oracle` | Oracle Database |
| `cassandra` | Apache Cassandra |

**Valores de Ambiente:**
| Valor | Descricao |
|-------|-----------|
| `DEV` | Ambiente de desenvolvimento |
| `QA` | Qualidade / Testes |
| `PRODUCTION` | Ambiente de producao |

**Exemplo:**
```bash
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "PostgreSQL Producao",
    "host": "db.exemplo.com",
    "port": 5432,
    "type": "postgres",
    "username": "usuario_dataguard",
    "password": "senha-segura",
    "environment": "PRODUCTION",
    "useSsl": true
  }'
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "server": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "PostgreSQL Producao",
      "host": "db.exemplo.com",
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
          {"name": "meuapp", "owner": "postgres", "size_mb": 1024, "table_count": 45}
        ]
      }
    }
  }
}
```

### Criar Servidor (Modo AGENT)

Criar um servidor que sera monitorado via agente on-premise. **A descoberta automatica e realizada pelo agente.**

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
  "password": "senha-segura",
  "database": "app_interno",
  "environment": "PRODUCTION",
  "useSsl": false,
  "syncEnabled": true,
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid-da-tabela-agents"
}
```

**Exemplo:**
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
    "password": "senha-segura",
    "environment": "PRODUCTION",
    "managementMode": "AGENT",
    "assignedAgentId": "13f84c6e-5448-47a4-bbdf-bd2110669a55"
  }'
```

**Resposta (modo AGENT):**
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

### Atualizar Servidor

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

**Exemplo:**
```bash
curl -X PUT "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{"syncEnabled": true}'
```

### Excluir Servidor

```http
DELETE /api/servers/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Exemplo:**
```bash
curl -X DELETE "https://apidg.runyx.io/api/servers/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Testar Conexao

Testar conexao com um servidor antes de cria-lo.

```http
POST /api/servers/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "host": "db.exemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "senha",
  "database": "meubanco",
  "management_mode": "CLOUD"
}
```

### Testar Conexao de Servidor Existente

```http
POST /api/servers/:id/test
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Sincronizar Bancos de Dados do Servidor

Disparar descoberta/sincronizacao de bancos de dados para um servidor.

```http
POST /api/servers/:id/sync-databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Metricas do Servidor

Obter metricas em tempo real de um servidor.

```http
GET /api/servers/:id/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gerenciamento de Bancos de Dados

### Listar Bancos de Dados do Servidor

```http
GET /api/servers/:id/databases
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "name": "producao_db",
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

### Listar Schemas do Banco de Dados

```http
GET /api/servers/:id/databases/:dbName/schemas
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Listar Tabelas do Banco de Dados

```http
GET /api/servers/:id/databases/:dbName/tables
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `schema` | string | Filtrar por nome do schema |

---

## Gerenciamento de Permissoes

Gerenciar permissoes de banco de dados para usuarios.

### Listar Permissoes

```http
GET /api/permissions
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `userId` | UUID | Filtrar por ID do usuario |
| `databaseId` | UUID | Filtrar por ID do banco de dados |
| `serverId` | UUID | Filtrar por ID do servidor |
| `permissionType` | string | Filtrar por tipo de permissao |
| `status` | string | Filtrar por status (active, revoked) |
| `includeExpired` | boolean | Incluir permissoes expiradas |

### Obter Detalhes da Permissao

```http
GET /api/permissions/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Conceder Permissao

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
  "reason": "Acesso para relatorio trimestral"
}
```

**Tipos de Permissao:**
| Tipo | Descricao |
|------|-----------|
| `READ` | Acesso somente leitura |
| `WRITE` | Acesso de leitura e escrita |
| `ADMIN` | Acesso administrativo completo |
| `CUSTOM` | Conjunto de permissoes customizado |

**Exemplo:**
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

### Conceder Permissoes em Massa

Conceder a mesma permissao para multiplos usuarios.

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

### Atualizar Permissao

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

### Revogar Permissao

```http
DELETE /api/permissions/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "reason": "Projeto concluido"
}
```

### Verificar Permissao

Verificar se um usuario tem uma permissao especifica.

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

### Sincronizar Permissoes

Sincronizar permissoes entre o Dataguard e o servidor de banco de dados real.

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

**Tipos de Sincronizacao:**
| Tipo | Descricao |
|------|-----------|
| `full` | Sincronizacao completa de todas as permissoes |
| `partial` | Sincronizar apenas permissoes alteradas |

### Obter Estatisticas de Permissoes

```http
GET /api/permissions/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Permissoes Expirando

```http
GET /api/permissions/expiring?days=7
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Discrepancias de Permissoes

Encontrar diferencas entre permissoes do Dataguard e permissoes reais do banco de dados.

```http
GET /api/permissions/servers/:serverId/discrepancies
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gerenciamento de Usuarios de Servico

Gerenciar contas/usuarios de servico em servidores de banco de dados.

### Listar Usuarios de Servico

```http
GET /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `databaseId` | UUID | Filtrar por banco de dados |
| `serverId` | UUID | Filtrar por servidor |
| `status` | string | Filtrar por status |
| `username` | string | Filtrar por nome de usuario |
| `needsRotation` | boolean | Filtrar usuarios que precisam de rotacao de senha |

### Obter Detalhes do Usuario de Servico

```http
GET /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Criar Usuario de Servico

Criar um novo usuario de banco de dados em um servidor.

```http
POST /api/service-users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_readonly",
  "password": "SenhaSegura123!",
  "privileges": ["SELECT", "CONNECT"],
  "description": "Usuario somente leitura para aplicacao de relatorios",
  "expiresAt": "2025-12-31T23:59:59Z",
  "rotationIntervalDays": 90
}
```

**Privilegios Comuns:**
| Privilegio | Descricao |
|------------|-----------|
| `SELECT` | Ler dados das tabelas |
| `INSERT` | Inserir novas linhas |
| `UPDATE` | Atualizar linhas existentes |
| `DELETE` | Excluir linhas |
| `CREATE` | Criar tabelas/objetos |
| `DROP` | Excluir tabelas/objetos |
| `CONNECT` | Conectar ao banco de dados |
| `EXECUTE` | Executar funcoes/procedures |
| `ALL` | Todos os privilegios |

**Exemplo:**
```bash
curl -X POST "https://apidg.runyx.io/api/service-users" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "databaseId": "database-uuid",
    "username": "app_service",
    "privileges": ["SELECT", "INSERT", "UPDATE"],
    "description": "Conta de servico da aplicacao",
    "rotationIntervalDays": 30
  }'
```

### Atualizar Usuario de Servico

```http
PUT /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Descricao atualizada",
  "rotationIntervalDays": 60
}
```

### Excluir Usuario de Servico

Remove o usuario do servidor de banco de dados.

```http
DELETE /api/service-users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotacionar Senha

Alterar a senha de um usuario de servico.

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "generatePassword": true
}
```

Ou especificar uma nova senha:

```http
POST /api/service-users/:id/rotate-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "NovaSenhaSegura456!"
}
```

### Rotacao de Senha em Massa

Rotacionar senhas de multiplos usuarios de servico.

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

### Testar Conexao do Usuario de Servico

```http
POST /api/service-users/:id/test-connection
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Clonar Usuario de Servico

Clonar um usuario de servico existente para outro banco de dados.

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

### Obter Estatisticas de Usuarios de Servico

```http
GET /api/service-users/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Usuarios que Precisam de Rotacao

```http
GET /api/service-users/needing-rotation
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gerenciamento de Agentes

Gerenciar agentes on-premise para monitorar bancos de dados internos.

### Listar Agentes

```http
GET /api/agents
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `status` | string | Filtrar por status (online, offline, error) |
| `limit` | number | Resultados por pagina |
| `offset` | number | Offset de paginacao |

### Obter Detalhes do Agente

```http
GET /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Criar Agente

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

**Resposta:**
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
  "message": "Agente criado. Configure o agente com essas credenciais."
}
```

### Atualizar Agente

```http
PATCH /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "name": "Agente-DC1-Atualizado",
  "description": "Descricao atualizada"
}
```

### Excluir Agente

```http
DELETE /api/agents/:agentId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Rotacionar Chave do Agente

```http
POST /api/agents/:agentId/rotate-key
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Tarefas do Agente

```http
GET /api/agents/:agentId/tasks
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Criar Tarefa do Agente

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

**Tipos de Tarefa:**
| Tipo | Descricao |
|------|-----------|
| `SYNC_REQUEST` | Sincronizar metadados do servidor |
| `TEST_CONNECTION_REQUEST` | Testar conexao do servidor |
| `CREATE_USER_REQUEST` | Criar usuario de banco de dados |
| `GRANT_PERMISSIONS_REQUEST` | Conceder permissoes |
| `REVOKE_PERMISSIONS_REQUEST` | Revogar permissoes |
| `REMOVE_USER_REQUEST` | Remover usuario de banco de dados |
| `COLLECT_METRICS_REQUEST` | Coletar metricas do servidor |
| `DISCOVER_SERVER_METADATA_REQUEST` | Descobrir bancos de dados/schemas |

### Obter Resultado da Tarefa

```http
GET /api/agents/tasks/:taskId
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Cancelar Tarefa

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Metricas do Agente

```http
GET /api/agents/:agentId/metrics
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Visao Geral de Estatisticas dos Agentes

```http
GET /api/agents/stats/overview
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Auditoria de Queries

Monitorar e auditar queries de banco de dados.

### Obter Logs de Queries

```http
GET /api/query-audit/servers/:serverId/logs
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `queryType` | string | Filtrar por tipo de query (SELECT, INSERT, UPDATE, DELETE) |
| `username` | string | Filtrar por nome de usuario do banco de dados |
| `database` | string | Filtrar por nome do banco de dados |
| `startDate` | ISO8601 | Inicio do intervalo de datas |
| `endDate` | ISO8601 | Fim do intervalo de datas |
| `success` | boolean | Filtrar por status de sucesso |
| `page` | number | Numero da pagina |
| `limit` | number | Resultados por pagina |

### Exportar Logs de Queries

```http
GET /api/query-audit/servers/:serverId/export?format=csv
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `format` | string | Formato de exportacao: `csv` ou `json` |

### Coletar Queries

Disparar coleta manual de queries de um servidor.

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

### Verificar Disponibilidade de Auditoria de Queries

```http
GET /api/query-audit/servers/:serverId/availability
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Habilitar Auditoria de Queries

```http
POST /api/query-audit/servers/:serverId/enable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Desabilitar Auditoria de Queries

```http
POST /api/query-audit/servers/:serverId/disable
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Gerenciamento de Usuarios

Gerenciar usuarios da plataforma dentro do seu tenant.

### Listar Usuarios

```http
GET /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Obter Detalhes do Usuario

```http
GET /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Criar Usuario

```http
POST /api/users
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "email": "novousuario@empresa.com",
  "username": "novousuario",
  "password": "SenhaSegura123!",
  "fullName": "Novo Usuario",
  "role": "USER"
}
```

**Papeis de Usuario:**
| Papel | Descricao |
|-------|-----------|
| `ADMIN` | Administracao completa do tenant |
| `USER` | Acesso de usuario padrao |
| `VIEWER` | Acesso somente leitura |
| `APPROVER` | Pode aprovar solicitacoes de acesso |

### Atualizar Usuario

```http
PUT /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "email": "atualizado@empresa.com",
  "username": "usuarioatualizado",
  "role": "ADMIN"
}
```

### Excluir Usuario

```http
DELETE /api/users/:id
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

### Redefinir Senha de Usuario

```http
POST /api/users/:id/reset-password
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
Content-Type: application/json

{
  "newPassword": "SenhaTemporaria123!"
}
```

### Obter Estatisticas de Usuarios

```http
GET /api/users/stats
X-API-Key: runyx_ak_...
X-API-Secret: runyx_sk_...
```

---

## Saude e Monitoramento

### Verificacao Basica de Saude

```http
GET /health
```

**Resposta:**
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

## Tratamento de Erros

Todos os erros da API seguem um formato consistente:

```json
{
  "success": false,
  "message": "Descricao do erro",
  "errors": [
    {
      "field": "email",
      "message": "Formato de email invalido"
    }
  ],
  "code": "VALIDATION_ERROR"
}
```

### Codigos de Status HTTP

| Codigo | Descricao |
|--------|-----------|
| `200` | Sucesso |
| `201` | Criado |
| `400` | Requisicao Invalida - Entrada invalida |
| `401` | Nao Autorizado - Autenticacao invalida ou ausente |
| `403` | Proibido - Permissoes insuficientes |
| `404` | Nao Encontrado - Recurso nao existe |
| `409` | Conflito - Recurso ja existe |
| `422` | Entidade Nao Processavel - Validacao falhou |
| `429` | Muitas Requisicoes - Limite de taxa excedido |
| `500` | Erro Interno do Servidor |

### Codigos de Erro Comuns

| Codigo | Descricao |
|--------|-----------|
| `VALIDATION_ERROR` | Validacao de entrada falhou |
| `AUTHENTICATION_ERROR` | Autenticacao falhou |
| `AUTHORIZATION_ERROR` | Permissao negada |
| `NOT_FOUND` | Recurso nao encontrado |
| `DUPLICATE_ENTRY` | Recurso ja existe |
| `RATE_LIMIT_EXCEEDED` | Muitas requisicoes |
| `CONNECTION_ERROR` | Conexao com banco de dados falhou |

---

## Limites de Taxa

A API implementa limites de taxa para garantir uso justo:

| Tipo de Endpoint | Limite | Janela |
|------------------|--------|--------|
| API Geral | 300 requisicoes | 15 minutos |
| Chave de API (Customizada) | Configuravel | 15 minutos |

Quando limitado pela taxa, a API retorna:

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705315800

{
  "success": false,
  "message": "Muitas requisicoes, por favor tente novamente mais tarde",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

---

## Paginacao

Endpoints de listagem suportam paginacao:

```http
GET /api/servers?limit=20&offset=40
```

**Resposta:**
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

## Exemplos de SDK

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

    def criar_servidor(self, dados_servidor):
        response = requests.post(
            f"{self.base_url}/servers",
            headers=self.headers,
            json=dados_servidor
        )
        return response.json()

    def conceder_permissao(self, dados_permissao):
        response = requests.post(
            f"{self.base_url}/permissions",
            headers=self.headers,
            json=dados_permissao
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

  async criarServidor(dadosServidor) {
    const response = await this.client.post('/servers', dadosServidor);
    return response.data;
  }

  async concederPermissao(dadosPermissao) {
    const response = await this.client.post('/permissions', dadosPermissao);
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

## Suporte

- **Documentacao:** https://docs.runyx.io
- **Status da API:** https://status.runyx.io
- **Email de Suporte:** support@runyx.io

---

*Ultima atualizacao: Dezembro de 2025*
