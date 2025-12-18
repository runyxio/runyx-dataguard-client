# Documentacao da API Dataguard

Documentacao completa da API REST para a plataforma de monitoramento de banco de dados e auditoria de queries Dataguard.

**URL Base:** `https://apidg.runyx.io/api`

---

## Indice

1. [Autenticacao](#autenticacao)
2. [Chaves de API](#chaves-de-api)
3. [Gerenciamento de Servidores](#gerenciamento-de-servidores)
4. [Gerenciamento de Bancos de Dados](#gerenciamento-de-bancos-de-dados)
5. [Gerenciamento de Permissoes](#gerenciamento-de-permissoes)
6. [Gerenciamento de Usuarios de Servico](#gerenciamento-de-usuarios-de-servico)
7. [Gerenciamento de Agentes](#gerenciamento-de-agentes)
8. [Auditoria de Queries](#auditoria-de-queries)
9. [Gerenciamento de Usuarios](#gerenciamento-de-usuarios)
10. [Saude e Monitoramento](#saude-e-monitoramento)
11. [Tratamento de Erros](#tratamento-de-erros)
12. [Limites de Taxa](#limites-de-taxa)

---

## Autenticacao

A API suporta dois metodos de autenticacao:

### 1. JWT (Bearer Token)

Usado para aplicacoes web e sessoes interativas.

```bash
# Login para obter tokens
curl -X POST https://apidg.runyx.io/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@empresa.com",
    "password": "sua-senha"
  }'

# Resposta
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

# Use o token nas requisicoes subsequentes
curl -X GET https://apidg.runyx.io/api/servers \
  -H "Authorization: Bearer eyJhbG..."
```

### 2. Chaves de API

Usado para acesso programatico e automacao. As chaves de API fornecem controle de acesso baseado em escopos.

```bash
# Usar autenticacao por Chave de API
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_sua_chave_api" \
  -H "X-API-Secret: runyx_sk_sua_chave_secreta"
```

---

## Endpoints de Autenticacao

### Login

Autenticar usuario com email e senha.

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "usuario@empresa.com",
  "password": "sua-senha"
}
```

**Resposta:**
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
      "username": "joaosilva",
      "fullName": "Joao Silva",
      "role": "ADMIN",
      "tenantId": "tenant-uuid"
    }
  }
}
```

### Cadastro (Criar Tenant e Usuario)

Criar um novo tenant com o primeiro usuario administrador.

```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "admin@novaempresa.com",
  "password": "SenhaSegura123!",
  "fullName": "Joao Silva",
  "companyName": "Nova Empresa Ltda",
  "planId": "plan-uuid"
}
```

**Requisitos de Senha:**
- Minimo de 8 caracteres
- Pelo menos uma letra maiuscula
- Pelo menos uma letra minuscula
- Pelo menos um numero
- Pelo menos um caractere especial

### Atualizar Token

Atualizar um token de acesso expirado.

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbG..."
}
```

### Esqueci a Senha

Solicitar email de redefinicao de senha.

```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "usuario@empresa.com"
}
```

### Redefinir Senha

Redefinir senha usando o token do email.

```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "token": "token-de-redefinicao-do-email",
  "password": "NovaSenhaSegura123!"
}
```

### Verificar Token

Verificar se o token atual e valido.

```http
GET /api/auth/verify
Authorization: Bearer eyJhbG...
```

### Logout

Invalidar a sessao atual.

```http
POST /api/auth/logout
Authorization: Bearer eyJhbG...
```

---

## Chaves de API

Chaves de API fornecem acesso programatico com permissoes granulares.

### Listar Chaves de API

```http
GET /api/api-keys
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `userId` | UUID | Filtrar por ID do usuario |
| `includeRevoked` | boolean | Incluir chaves revogadas |
| `includeExpired` | boolean | Incluir chaves expiradas |

### Criar Chave de API

```http
POST /api/api-keys
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Integracao Producao",
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

**Escopos Disponiveis:**
| Escopo | Descricao |
|--------|-----------|
| `servers:read` | Ler informacoes de servidores |
| `servers:write` | Criar, atualizar, excluir servidores |
| `users:read` | Ler informacoes de usuarios |
| `users:write` | Criar, atualizar, excluir usuarios |
| `permissions:read` | Ler permissoes |
| `permissions:write` | Conceder permissoes |
| `permissions:delete` | Revogar permissoes |
| `api_keys:read` | Ler chaves de API |
| `api_keys:write` | Gerenciar chaves de API |
| `agents:read` | Ler informacoes de agentes |
| `agents:write` | Gerenciar agentes |
| `audit:read` | Ler logs de auditoria |
| `query_audit:read` | Ler logs de auditoria de queries |
| `service_users:read` | Ler usuarios de servico |
| `service_users:write` | Gerenciar usuarios de servico |

**Resposta:**
```json
{
  "success": true,
  "data": {
    "id": "key-uuid",
    "name": "Integracao Producao",
    "apiKey": "runyx_ak_e9dea10edac7d072...",
    "secretKey": "runyx_sk_56abbdb203712cc9...",
    "scopes": ["servers:read", "servers:write"],
    "expiresAt": "2026-01-01T00:00:00.000Z"
  },
  "message": "Chave de API criada. Guarde a chave secreta com seguranca - ela nao sera exibida novamente."
}
```

### Rotacionar Chave de API

Gerar novas credenciais para uma chave existente.

```http
POST /api/api-keys/:id/rotate
Authorization: Bearer eyJhbG...
```

### Revogar Chave de API

```http
DELETE /api/api-keys/:id
Authorization: Bearer eyJhbG...
```

---

## Gerenciamento de Servidores

Gerenciar servidores de banco de dados a serem monitorados.

### Listar Servidores

```http
GET /api/servers
Authorization: Bearer eyJhbG...
```

**Usando Chave de API:**
```bash
curl -X GET https://apidg.runyx.io/api/servers \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."
```

### Obter Detalhes do Servidor

```http
GET /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Criar Servidor (Modo CLOUD)

Criar um servidor que sera monitorado diretamente da nuvem.

```http
POST /api/servers
Authorization: Bearer eyJhbG...
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

### Criar Servidor (Modo AGENT)

Criar um servidor que sera monitorado via agente on-premise.

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
  "password": "senha-segura",
  "database": "app_interno",
  "environment": "PRODUCTION",
  "useSsl": false,
  "syncEnabled": true,
  "managementMode": "AGENT",
  "assignedAgentId": "agent-uuid-da-tabela-agents"
}
```

### Criar Servidor v2 (Com Auto-Discovery)

Cria um servidor e automaticamente descobre bancos de dados, schemas e tabelas.

```http
POST /api/servers/v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "DB Producao",
  "host": "db.exemplo.com",
  "port": 5432,
  "type": "postgres",
  "username": "admin",
  "password": "senha",
  "environment": "PRODUCTION"
}
```

### Atualizar Servidor

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

### Excluir Servidor

```http
DELETE /api/servers/:id
Authorization: Bearer eyJhbG...
```

### Testar Conexao

Testar conexao com um servidor antes de cria-lo.

```http
POST /api/servers/test-connection
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Sincronizar Bancos de Dados do Servidor

Disparar descoberta/sincronizacao de bancos de dados para um servidor.

```http
POST /api/servers/:id/sync-databases
Authorization: Bearer eyJhbG...
```

### Obter Metricas do Servidor

Obter metricas em tempo real de um servidor.

```http
GET /api/servers/:id/metrics
Authorization: Bearer eyJhbG...
```

---

## Gerenciamento de Bancos de Dados

### Listar Bancos de Dados do Servidor

```http
GET /api/servers/:id/databases
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Listar Tabelas do Banco de Dados

```http
GET /api/servers/:id/databases/:dbName/tables
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
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
| `consolidated` | boolean | Retornar visao consolidada |

### Obter Detalhes da Permissao

```http
GET /api/permissions/:id
Authorization: Bearer eyJhbG...
```

### Conceder Permissao

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

### Conceder Permissoes em Massa

Conceder a mesma permissao para multiplos usuarios.

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

### Atualizar Permissao

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

### Revogar Permissao

```http
DELETE /api/permissions/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "reason": "Projeto concluido"
}
```

### Verificar Permissao

Verificar se um usuario tem uma permissao especifica.

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

### Sincronizar Permissoes

Sincronizar permissoes entre o Dataguard e o servidor de banco de dados real.

```http
POST /api/permissions/sync
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Obter Permissoes Expirando

```http
GET /api/permissions/expiring
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Padrao | Descricao |
|-----------|------|--------|-----------|
| `days` | number | 7 | Dias ate a expiracao (1-365) |

### Obter Discrepancias de Permissoes

Encontrar diferencas entre permissoes do Dataguard e permissoes reais do banco de dados.

```http
GET /api/permissions/servers/:serverId/discrepancies
Authorization: Bearer eyJhbG...
```

---

## Gerenciamento de Usuarios de Servico

Gerenciar contas/usuarios de servico em servidores de banco de dados.

### Listar Usuarios de Servico

```http
GET /api/service-users
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `databaseId` | UUID | Filtrar por banco de dados |
| `serverId` | UUID | Filtrar por servidor |
| `status` | string | Filtrar por status |
| `username` | string | Filtrar por nome de usuario |
| `needsRotation` | boolean | Filtrar usuarios que precisam de rotacao de senha |
| `expiringDays` | number | Filtrar por dias ate a senha expirar |

### Obter Detalhes do Usuario de Servico

```http
GET /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Criar Usuario de Servico

Criar um novo usuario de banco de dados em um servidor.

```http
POST /api/service-users
Authorization: Bearer eyJhbG...
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
| `REFERENCES` | Criar chaves estrangeiras |
| `TRIGGER` | Criar triggers |
| `ALL` | Todos os privilegios |

### Criar Usuario de Servico v2 (Com Propagacao)

Cria um usuario de servico e propaga para todos os bancos de dados relevantes.

```http
POST /api/service-users-v2
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "databaseId": "database-uuid",
  "username": "app_service",
  "privileges": ["SELECT", "INSERT", "UPDATE"],
  "description": "Conta de servico da aplicacao",
  "rotationIntervalDays": 30
}
```

### Atualizar Usuario de Servico

```http
PUT /api/service-users/:id
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "privileges": ["SELECT", "INSERT", "UPDATE", "DELETE"],
  "description": "Descricao atualizada",
  "expiresAt": "2026-06-30T23:59:59Z",
  "rotationIntervalDays": 60
}
```

### Excluir Usuario de Servico

Remove o usuario do servidor de banco de dados.

```http
DELETE /api/service-users/:id
Authorization: Bearer eyJhbG...
```

### Rotacionar Senha

Alterar a senha de um usuario de servico.

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "NovaSenhaSegura456!",
  "generatePassword": false
}
```

Ou gerar uma senha aleatoria:

```http
POST /api/service-users/:id/rotate-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "generatePassword": true
}
```

### Rotacao de Senha em Massa

Rotacionar senhas de multiplos usuarios de servico.

```http
POST /api/service-users/bulk-rotate
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "serviceUserIds": ["user-uuid-1", "user-uuid-2"],
  "generatePasswords": true
}
```

### Auto-Rotacionar Senhas

Rotacionar automaticamente senhas de usuarios que excederam seu intervalo de rotacao.

```http
POST /api/service-users/auto-rotate
Authorization: Bearer eyJhbG...
```

### Testar Conexao do Usuario de Servico

```http
POST /api/service-users/:id/test-connection
Authorization: Bearer eyJhbG...
```

### Clonar Usuario de Servico

Clonar um usuario de servico existente para outro banco de dados.

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

### Obter Estatisticas de Usuarios de Servico

```http
GET /api/service-users/stats
Authorization: Bearer eyJhbG...
```

### Obter Usuarios que Precisam de Rotacao

```http
GET /api/service-users/needing-rotation
Authorization: Bearer eyJhbG...
```

### Obter Usuarios com Senhas Expirando

```http
GET /api/service-users/expiring
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Padrao | Descricao |
|-----------|------|--------|-----------|
| `days` | number | 7 | Dias ate a expiracao (1-365) |

---

## Gerenciamento de Agentes

Gerenciar agentes on-premise para monitorar bancos de dados internos.

### Listar Agentes

```http
GET /api/agents
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Criar Agente

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

**Resposta:**
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
  "message": "Agente criado. Configure o agente com essas credenciais."
}
```

### Atualizar Agente

```http
PATCH /api/agents/:agentId
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "name": "Agente-DC1-Atualizado",
  "description": "Descricao atualizada"
}
```

### Excluir Agente

```http
DELETE /api/agents/:agentId
Authorization: Bearer eyJhbG...
```

### Rotacionar Chave do Agente

```http
POST /api/agents/:agentId/rotate-key
Authorization: Bearer eyJhbG...
```

### Obter Tarefas do Agente

```http
GET /api/agents/:agentId/tasks
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `status` | string | Filtrar por status |
| `taskType` | string | Filtrar por tipo de tarefa |
| `limit` | number | Resultados por pagina |
| `offset` | number | Offset de paginacao |

### Criar Tarefa do Agente

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
Authorization: Bearer eyJhbG...
```

### Cancelar Tarefa

```http
POST /api/agents/:agentId/tasks/:taskId/cancel
Authorization: Bearer eyJhbG...
```

### Retentar Tarefa com Falha

```http
POST /api/agents/:agentId/tasks/:taskId/retry
Authorization: Bearer eyJhbG...
```

### Obter Metricas do Agente

```http
GET /api/agents/:agentId/metrics
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `startDate` | ISO8601 | Inicio do intervalo de datas |
| `endDate` | ISO8601 | Fim do intervalo de datas |

### Obter Visao Geral de Estatisticas dos Agentes

```http
GET /api/agents/stats/overview
Authorization: Bearer eyJhbG...
```

---

## Auditoria de Queries

Monitorar e auditar queries de banco de dados.

### Obter Logs de Queries

```http
GET /api/query-audit/servers/:serverId/logs
Authorization: Bearer eyJhbG...
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
GET /api/query-audit/servers/:serverId/export
Authorization: Bearer eyJhbG...
```

**Parametros de Query:**
| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `format` | string | Formato de exportacao: `csv` ou `json` |
| Filtros adicionais | | Mesmos do Obter Logs de Queries |

### Coletar Queries

Disparar coleta manual de queries de um servidor.

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

### Verificar Disponibilidade de Auditoria de Queries

```http
GET /api/query-audit/servers/:serverId/availability
Authorization: Bearer eyJhbG...
```

### Habilitar Auditoria de Queries

```http
POST /api/query-audit/servers/:serverId/enable
Authorization: Bearer eyJhbG...
```

### Desabilitar Auditoria de Queries

```http
POST /api/query-audit/servers/:serverId/disable
Authorization: Bearer eyJhbG...
```

---

## Gerenciamento de Usuarios

Gerenciar usuarios da plataforma dentro do seu tenant.

### Listar Usuarios

```http
GET /api/users
Authorization: Bearer eyJhbG...
```

### Obter Perfil do Usuario Atual

```http
GET /api/users/profile
Authorization: Bearer eyJhbG...
```

### Obter Detalhes do Usuario

```http
GET /api/users/:id
Authorization: Bearer eyJhbG...
```

### Criar Usuario

```http
POST /api/users
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
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
Authorization: Bearer eyJhbG...
```

### Alterar Senha

Alterar sua propria senha.

```http
POST /api/users/change-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "currentPassword": "SenhaAntiga123!",
  "newPassword": "SenhaNova456!"
}
```

### Redefinir Senha de Usuario (Admin)

Redefinir a senha de outro usuario.

```http
POST /api/users/:id/reset-password
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "newPassword": "SenhaTemporaria123!"
}
```

### Obter Estatisticas de Usuarios

```http
GET /api/users/stats
Authorization: Bearer eyJhbG...
```

### Listar Sessoes Ativas

```http
GET /api/users/sessions
Authorization: Bearer eyJhbG...
```

### Revogar Sessao

```http
DELETE /api/users/sessions/:sessionId
Authorization: Bearer eyJhbG...
```

### Revogar Todas as Sessoes

Revogar todas as sessoes exceto a atual.

```http
DELETE /api/users/sessions
Authorization: Bearer eyJhbG...
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

### Saude Detalhada (Apenas Admin)

```http
GET /health/detailed
Authorization: Bearer eyJhbG...
```

**Resposta:**
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
| Autenticacao | 10 requisicoes | 1 minuto |
| Verificacao 2FA | 5 tentativas | 15 minutos |
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

## Webhooks

Configure webhooks para receber notificacoes em tempo real sobre eventos.

### Eventos de Webhook

| Evento | Descricao |
|--------|-----------|
| `server.created` | Novo servidor adicionado |
| `server.deleted` | Servidor removido |
| `permission.granted` | Permissao concedida |
| `permission.revoked` | Permissao revogada |
| `permission.expiring` | Permissao prestes a expirar |
| `user.created` | Novo usuario criado |
| `service_user.created` | Usuario de servico criado |
| `service_user.password_rotated` | Senha rotacionada |
| `agent.connected` | Agente ficou online |
| `agent.disconnected` | Agente ficou offline |
| `query_audit.anomaly` | Query incomum detectada |

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

### cURL

```bash
# Listar todos os servidores
curl -X GET "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..."

# Criar um servidor
curl -X POST "https://apidg.runyx.io/api/servers" \
  -H "X-API-Key: runyx_ak_..." \
  -H "X-API-Secret: runyx_sk_..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "DB Producao",
    "host": "db.exemplo.com",
    "port": 5432,
    "type": "postgres",
    "username": "admin",
    "password": "senha",
    "environment": "PRODUCTION"
  }'

# Conceder permissao
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

## Suporte

- **Documentacao:** https://docs.runyx.io
- **Status da API:** https://status.runyx.io
- **Email de Suporte:** support@runyx.io
- **GitHub Issues:** https://github.com/runyxio/dataguard/issues

---

*Ultima atualizacao: Dezembro de 2025*
