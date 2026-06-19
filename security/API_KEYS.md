---
type: security
domain: authentication
status: implemented
created_by: OpenCode
related_pr: 48
---

# Autenticação via API Key

> Autenticação simples e eficaz para a API K.A.O.S usando header `X-API-Key`.

---

## Visão Geral

A autenticação da API K.A.O.S é baseada em **API Key** (chave de API) transmitida via header HTTP `X-API-Key`. É a única forma de autenticação suportada atualmente.

Não há suporte para JWT, OAuth2, ou sessões. A simplicidade é intencional para um assistente pessoal offline.

---

## Como Funciona

### Geração da Chave

Na primeira inicialização do backend, uma chave aleatória é gerada e persistida:

```text
assistant/data/api_key.txt
```

A chave também é logada no startup:

```log
2026-06-19 16:42:58 - [INFO] [auth] API key: a1b2c3d4e5f6...
```

### Uso

Inclua o header `X-API-Key` em todas as requisições:

```bash
curl -H "X-API-Key: a1b2c3d4e5f6..." http://localhost:8000/api/chat/message
```

### Endpoints de Gerenciamento

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/auth/key` | Retorna chave atual + versão mascarada |
| POST | `/auth/regenerate` | Gera nova chave (invalida a anterior) |

Exemplo:
```bash
# Obter chave
curl -H "X-API-Key: a1b2c3d4e5f6..." http://localhost:8000/auth/key

# Regenerar chave
curl -X POST -H "X-API-Key: a1b2c3d4e5f6..." http://localhost:8000/auth/regenerate
```

---

## Rotas Públicas (Sem Autenticação)

As seguintes rotas **não requerem** `X-API-Key`:

| Rota | Descrição |
|------|-----------|
| `/health` | Healthcheck |
| `/health/readiness` | Readiness check |
| `/docs` | Swagger UI |
| `/openapi.json` | OpenAPI spec |
| `/auth/*` | Endpoints de autenticação |
| `/api/setup/*` | Configuração inicial de provedores |
| `/` | Informações da API |

> **Razão**: `/api/setup/*` precisa ser acessível antes da primeira configuração. `/auth/*` permite obter a chave inicial.

---

## Integração Desktop (Tauri)

O aplicativo desktop armazena a chave localmente usando `tauri-plugin-store`:

1. Usuário configura provedores via UI
2. App chama `GET /auth/key` após setup
3. Chave salva no store local (`%APPDATA%/kaos/`)
4. Todas as chamadas subsequentes incluem `X-API-Key`

```typescript
// Exemplo conceitual
const apiKey = await invoke('get_api_key'); // do store
const response = await fetch('/api/chat/message', {
  headers: { 'X-API-Key': apiKey, 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: 'Olá' })
});
```

---

## Segurança

### Considerações

| Aspecto | Detalhe |
|---------|---------|
| Transporte | **Sempre use HTTPS em produção** (TLS termina no reverse proxy) |
| Rotação | Use `POST /auth/regenerate` se chave comprometida |
| Armazenamento | Chave em `data/api_key.txt` (apenas leitura pelo processo) |
| Logs | Chave completa logada **apenas no startup** (não em requests) |

### Boas Práticas

1. **Nunca commite** a chave no Git (`.gitignore` já inclui `data/api_key.txt`)
2. **Roteie** a chave via variável de ambiente em produção se necessário
3. **Monitore** logs de rejeição (`[auth] rejected request from ...`)
4. **Regere** periodicamente via `POST /auth/regenerate`

---

## Troubleshooting

| Erro | Causa | Solução |
|------|-------|---------|
| `401 Invalid API key` | Header ausente ou incorreto | Verifique `X-API-Key` |
| `503 Service not ready` | Chave não inicializada | Aguarde startup completo |
| Chave não funciona após restart | Arquivo `data/api_key.txt` perdido | Verifique volume persistente |

---

## Referência de Código

| Arquivo | Função |
|---------|--------|
| `assistant/app/middleware/auth.py` | Middleware de validação |
| `assistant/app/api/auth.py` | Endpoints `/auth/key`, `/auth/regenerate` |
| `assistant/app/main.py` | Registro do middleware + geração chave |
| `desktop/src-tauri/src/store.rs` | Armazenamento local (plugin-store) |

---

## Referências

- PR #48: feat(auth): API Key authentication via X-API-Key header
- `docs/vault/setup/SETUP.md` — Configuração inicial
- `docs/vault/architecture/DESKTOP_ARCHITECTURE.md` — Integração desktop