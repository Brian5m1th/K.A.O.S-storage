# Referência de APIs — K.A.O.S

## Autenticação

Todas as requisições (exceto `/health` e `/docs`) requerem API Key no header:

```bash
API_KEY=$(cat data/api_key.txt)

curl -H "x-api-key: $API_KEY" http://localhost:8000/health
# ou
curl -H "Authorization: Bearer $API_KEY" http://localhost:8000/health
```

---

## Health

### GET /health

Verifica se o backend está operacional.

```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "ok",
  "version": "0.1.0",
  "embedder_ready": true
}
```

---

## Chat

### POST /api/chat/message

Envia mensagem para o chat com streaming SSE.

```bash
curl -X POST http://localhost:8000/api/chat/message \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "message": "Ola, quem e voce?",
    "model": "llama3.2:3b",
    "session_id": "abc-123"
  }'
```

**Request:**
```json
{
  "message": "string (obrigatório)",
  "model": "string (opcional, padrão: llama3.2:3b)",
  "session_id": "string (opcional)",
  "stream": "boolean (opcional, padrão: true)",
  "workflow": "string (opcional)"
}
```

**Response (stream):** SSE com tokens.
**Response (no stream):**
```json
{
  "response": "string",
  "model": "string",
  "usage": {"prompt_tokens": 10, "completion_tokens": 20}
}
```

---

## Models

### GET /v1/models

Lista modelos disponíveis.

```bash
curl -X GET http://localhost:8000/v1/models \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "models": [
    {"id": "llama3.2:3b", "provider": "ollama", "capabilities": ["fast_chat", "reasoning"]},
    {"id": "gpt-4o", "provider": "openai", "capabilities": ["fast_chat", "reasoning", "vision"]}
  ]
}
```

---

## Orchestrator

### POST /api/orchestrator/execute

Executa um workflow via orquestrador.

```bash
curl -X POST http://localhost:8000/api/orchestrator/execute \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "workflow": "chat",
    "message": "Ola",
    "session_id": "abc-123"
  }'
```

**Response:**
```json
{
  "execution_id": "uuid",
  "workflow": "chat",
  "status": "completed",
  "response": "string"
}
```

---

## Indexing

### POST /indexing/full

Executa indexação completa do vault.

```bash
curl -X POST http://localhost:8000/indexing/full \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "status": "indexing_started",
  "total_files": 150,
  "qdrant_points": 1200
}
```

### POST /indexing/init-folders

Inicializa estrutura de pastas do vault.

```bash
curl -X POST http://localhost:8000/indexing/init-folders \
  -H "x-api-key: $API_KEY"
```

---

## RAG

### GET /rag/context

Busca contexto no repositório vetorial.

```bash
curl -X GET "http://localhost:8000/rag/context?query=O%20que%20e%20K.A.O.S&limit=5" \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "results": [
    {"content": "texto...", "score": 0.95, "source": "docs/sdd/SDD-KIRL.md"}
  ]
}
```

---

## Setup / Providers

### POST /api/setup/provider

Configura um provider de LLM.

```bash
curl -X POST http://localhost:8000/api/setup/provider \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "provider": "ollama",
    "base_url": "http://localhost:11434",
    "api_key": ""
  }'
```

**Response:**
```json
{"status": "configured", "provider": "ollama"}
```

---

## Users

### GET /api/users/me

Retorna dados do usuário atual.

```bash
curl http://localhost:8000/api/users/me \
  -H "x-api-key: $API_KEY"
```

### GET /api/users/{user_id}/profiles

Lista perfis de modelo do usuário.

```bash
curl http://localhost:8000/api/users/{user_id}/profiles \
  -H "x-api-key: $API_KEY"
```

---

## Webhooks

### POST /api/webhooks/n8n

Recebe webhooks do n8n.

```bash
curl -X POST http://localhost:8000/api/webhooks/n8n \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"event": "workflow.completed", "data": {}}'
```

---

## Audit (KIRL)

### POST /api/audit/run

Executa auditoria documental completa.

```bash
curl -X POST http://localhost:8000/api/audit/run \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "coverage": 87.5,
  "driftLevel": "medium",
  "missingFeatures": ["feature-1", "feature-2"],
  "outdatedDocs": ["SDD-OLD.md"],
  "inconsistentPhases": [],
  "orphanedSDDs": [],
  "undocumentedCode": [],
  "timestamp": "2026-06-22T10:30:00"
}
```

### GET /api/audit/snapshot

Obtém o snapshot atual do DRL.

```bash
curl http://localhost:8000/api/audit/snapshot \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "features": [{"id": "feature-1", "name": "Feature 1", ...}],
  "coverage": 87.5,
  "driftLevel": "medium",
  "lastCommit": "abc123",
  "missingCount": 2,
  "outdatedCount": 1,
  "graphSummary": {"totalNodes": 42, "totalEdges": 68},
  "timestamp": "2026-06-22T10:30:00"
}
```

### GET /api/audit/coverage

Cobertura rápida.

```bash
curl http://localhost:8000/api/audit/coverage \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{"coverage": 87.5, "driftLevel": "medium"}
```

### POST /api/audit/scan-commits

Escaneia commits recentes e mapeia para features.

```bash
curl -X POST "http://localhost:8000/api/audit/scan-commits?limit=50" \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{
  "total": 50,
  "commits": [
    {"hash": "abc123", "message": "feat: ...", "type": "feat", "impact": "high", "features": ["observability"]}
  ]
}
```

### GET /api/audit/commit-map

Commit map existente.

```bash
curl http://localhost:8000/api/audit/commit-map \
  -H "x-api-key: $API_KEY"
```

### POST /api/audit/scan-code

Escaneia código por features.

```bash
curl -X POST http://localhost:8000/api/audit/scan-code \
  -H "x-api-key: $API_KEY"
```

### GET /api/audit/features

Lista features registradas.

```bash
curl http://localhost:8000/api/audit/features \
  -H "x-api-key: $API_KEY"
```

### GET /api/audit/features/{feature_id}

Detalhes de uma feature.

```bash
curl http://localhost:8000/api/audit/features/chat-streaming \
  -H "x-api-key: $API_KEY"
```

---

## Auth

### POST /api/auth/validate

Valida se a API Key é válida.

```bash
curl -X POST http://localhost:8000/api/auth/validate \
  -H "x-api-key: $API_KEY"
```

**Response:**
```json
{"valid": true, "user_id": "uuid"}
```

---

## Feature Flags

### GET /api/feature-flags

Lista feature flags.

```bash
curl http://localhost:8000/api/feature-flags \
  -H "x-api-key: $API_KEY"
```

---

## OpenAI Compatible

### POST /v1/chat/completions

Endpoint compatível com OpenAI.

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "model": "llama3.2:3b",
    "messages": [{"role": "user", "content": "Ola"}],
    "stream": false
  }'
```

---

## Erros Comuns

| Código | Significado | Causa |
|--------|-------------|-------|
| 401 | Unauthorized | API Key ausente ou inválida |
| 422 | Validation Error | Payload mal formatado |
| 500 | Internal Error | Erro no servidor |
| 503 | Service Unavailable | Provider (Ollama/Qdrant) offline |

**Response de erro:**
```json
{
  "detail": "Descrição do erro"
}
```
