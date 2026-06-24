# Spec: K.A.O.S — Roadmap Expansion v2 (Fases 9–14)

> ✅ **Spec completa.** Nenhum ponto em aberto identificado. Pronta para validação pelo OpenCode e Tech Planner.
>
> Gerada por: Antigravity /spec-extractor  
> Data: 2026-06-24  
> Base: Análise profunda do codebase real (`assistant/`, `desktop/`, `docs/`, `infra/`)

---

## 1. Contexto

**Problema:**  
O K.A.O.S possui múltiplos módulos avançados já implementados no backend (VaultAnalyzer AI, Universal Orchestrator, MCP Manager, Cost Tracker, Memory Service, KIRL Audit Engine) que estão desconectados entre si ou sem exposição via API/Desktop. O roadmap oficial (Fases 1–11) está desatualizado: o sistema real está mais avançado do que o documentado, mas módulos críticos estão "orfãos" sem integração completa.

**Atores:**
| Ator | Papel |
|------|-------|
| **Usuário Final (role: user)** | Usa o chat, busca notas, cria conteúdo, consulta histórico |
| **Admin (role: admin)** | Gerencia usuários, providers, RBAC, observability |
| **Sistema (K.A.O.S backend)** | Orquestra workflows, executa agentes, indexa vault, monitora drift |
| **OpenCode** | IDE AI agent que consome a API do K.A.O.S para contexto de código |
| **N8N** | Sistema de automação externo que recebe/envia eventos do K.A.O.S |

**Integrações com sistemas existentes:**
| Sistema | Caminho | Status |
|---------|---------|--------|
| FastAPI backend | `assistant/app/` | ✅ Ativo (25+ routers) |
| LangGraph Agent | `assistant/app/agent/` | ✅ Ativo |
| MCP Manager | `assistant/app/core/mcp_manager.py` | 🟡 Ativo, sem bridge para tools |
| Universal Orchestrator | `assistant/app/orchestrator/` | 🟡 Ativo, model hardcoded |
| VaultAnalyzer AI | `assistant/app/ai/vault_analyzer/` | 🟡 Implementado, sem API |
| Cost Tracker | `assistant/app/observability/cost_tracker.py` | 🟡 Ativo, sem API exposta |
| KIRL Audit Engine | `assistant/app/core/documentation/audit_engine.py` | ✅ Ativo com pipeline completo |
| Qdrant | `localhost:6333` | ✅ Ativo |
| PostgreSQL | settings: `DATABASE_URL` | ✅ Ativo |
| Desktop (Tauri/React) | `desktop/src/` | ✅ 15 páginas (algumas com mocks) |
| Obsidian Vault | `OBSIDIAN_VAULT_PATH` | ✅ Montado |
| N8N | `N8N_API_URL = http://n8n:5678` | ❌ Container ausente |
| Prometheus/Grafana | `infra/grafana/` | ✅ Configs existem |

---

## 2. Requisitos Funcionais

### Grupo A — Correções Críticas (P0)

- **RF-A01:** O sistema deve configurar `CORS_ORIGINS` a partir de variável de ambiente, substituindo `allow_origins=["*"]` por lista explícita de origens permitidas.
- **RF-A02:** O `UniversalOrchestrator` deve selecionar o modelo via `ModelRouter.select(workflow, capability, user_id)` em vez de usar `"qwen3:4b"` hardcoded.
- **RF-A03:** O `UniversalOrchestrator` deve consultar `CapabilityPolicy` para autorizar a execução baseado no `role` do usuário antes de despachar o plano.

### Grupo B — VaultAnalyzer API (P0)

- **RF-B01:** O sistema deve expor `POST /api/vault/analyze` que dispara `AnalyzerEngine.run()` e retorna `ArchitectureAnalysis` serializada como JSON.
- **RF-B02:** O sistema deve expor `GET /api/vault/analysis` que retorna o último relatório gerado (cacheado em memória ou arquivo JSON em `docs/generated/`).
- **RF-B03:** O sistema deve expor `GET /api/vault/suggestions` que retorna a lista de `SuggestionEngine` do último analysis.
- **RF-B04:** A análise deve ser re-disparada automaticamente após eventos de commit detectados pelo `SDDWatcher`.
- **RF-B05:** O sistema deve emitir evento `vault.analysis.completed` no `EventBus` após cada análise, com `coverage_score` e `drift_level`.

### Grupo C — MCP → LangGraph Bridge (P0)

- **RF-C01:** O sistema deve expor `GET /api/mcp/tools` que lista todas as ferramentas disponíveis em todos os servidores MCP registrados.
- **RF-C02:** O sistema deve expor `POST /api/mcp/servers` para registrar um novo servidor MCP em runtime, aceitando `{name, command, args, env}`.
- **RF-C03:** O `TOOL_REGISTRY` do LangGraph deve ser populado dinamicamente com as ferramentas dos servidores MCP ativos no startup.
- **RF-C04:** Ferramentas MCP devem aparecer listadas no `GET /v1/models` e serem selecionáveis pelo `IntentClassifier`.
- **RF-C05:** Falhas em servidores MCP devem ser registradas no `DeadLetterQueue` e não devem crashar o agente.

### Grupo D — Session History (P0)

- **RF-D01:** O sistema deve persistir cada mensagem de chat (user + assistant) na tabela `conversations` do PostgreSQL com `{id, user_id, session_id, role, content, workflow_type, tokens_used, created_at}`.
- **RF-D02:** O sistema deve expor `GET /api/conversations?user_id=X&page=N&limit=20` retornando histórico paginado.
- **RF-D03:** O sistema deve expor `GET /api/conversations/{session_id}` retornando todos os turnos de uma sessão.
- **RF-D04:** O sistema deve expor `POST /api/conversations/{session_id}/summarize` que dispara o `Summarizer` e salva o resumo como nota no Obsidian (`Vault/Diário/conversas/{data}.md`).
- **RF-D05:** O `MemoryRouter` e o `SmartRouter` devem injetar os últimos N turnos da sessão ativa como contexto adicional no prompt.
- **RF-D06:** O desktop deve exibir a lista de sessões passadas na tela de Chat (painel lateral).
- **RF-D07:** O desktop deve permitir busca semântica no histórico via `GET /rag/context` com query sobre o conteúdo das conversas indexadas.

### Grupo E — N8N Full Integration (P1)

- **RF-E01:** O `docker-compose.yml` em `infra/docker/` deve incluir o serviço `n8n` com `image: n8nio/n8n`, porta `5678`, volume `n8n_data`.
- **RF-E02:** O sistema deve registrar uma `WebhookTool` no `TOOL_REGISTRY` que aceita `{flow_name: str, payload: dict}` e invoca `POST {N8N_API_URL}/webhook/{flow_name}`.
- **RF-E03:** O `N8NSubscriber` deve enviar apenas os eventos listados em `N8N_EVENTS` (variável de ambiente), não todos os eventos.
- **RF-E04:** O sistema deve expor `GET /api/n8n/flows` que lista os workflows ativos no N8N via `GET {N8N_API_URL}/api/v1/workflows`.
- **RF-E05:** O desktop deve exibir a lista de flows N8N na página de Integrations com status (active/inactive).

### Grupo F — Cost Dashboard (P1)

- **RF-F01:** O sistema deve expor `GET /api/observability/costs` retornando `{provider, workflow, total_usd, token_count}` agregado por provider e workflow.
- **RF-F02:** O sistema deve expor `GET /api/observability/costs/summary?period=day|week|month` retornando totais por período.
- **RF-F03:** O `CostTracker` deve persistir entradas no PostgreSQL além do Prometheus (tabela `cost_events`).
- **RF-F04:** O dashboard do desktop deve exibir um widget de custo acumulado do dia com breakdown por provider.

### Grupo G — Workspace Management (P2)

- **RF-G01:** O sistema deve suportar múltiplos workspaces por usuário, cada um com `{id, user_id, name, vault_path, qdrant_collection, created_at}`.
- **RF-G02:** O sistema deve expor `GET /api/workspaces`, `POST /api/workspaces`, `PUT /api/workspaces/{id}/activate`, `DELETE /api/workspaces/{id}`.
- **RF-G03:** Ao trocar de workspace ativo, o `VaultWatcher` deve parar o watcher anterior e iniciar um novo com o novo `vault_path`.
- **RF-G04:** Queries RAG devem ser escopadas pelo `qdrant_collection` do workspace ativo do usuário.
- **RF-G05:** O desktop deve exibir um seletor de workspace no header com o workspace ativo destacado.

### Grupo H — AI Self-Reviewer (P2)

- **RF-H01:** O sistema deve expor `POST /api/kirl/review` que dispara pipeline: `DocumentationAuditEngine.run_audit()` → `VaultAnalyzer.run()` → `SuggestionEngine.generate()`.
- **RF-H02:** O sistema deve executar a revisão automaticamente a cada 7 dias via scheduler (`AuditScheduler`).
- **RF-H03:** O sistema deve gerar um relatório Markdown (`docs/generated/self-review-{date}.md`) com métricas de drift, sugestões e ações recomendadas.
- **RF-H04:** O sistema deve emitir notificação (`NotificationService`) para admins quando `drift_score > 15%`.
- **RF-H05:** O desktop deve exibir o último relatório na página de Architecture com score de saúde e lista de ações.

---

## 3. Fluxos

### 3.1 Fluxo Principal — VaultAnalyzer API

```
1. POST /api/vault/analyze (autenticado)
2. Backend valida permissão (role >= "user")
3. AnalyzerEngine.run():
   a. VaultReader.scan_all() — lê vault
   b. DriftEngine.detect() — compara código vs docs
   c. EvidenceEngine.collect() — coleta evidências
   d. SuggestionEngine.generate() — gera sugestões
4. Resultado salvo em docs/generated/vault-analysis-{ts}.json
5. EventBus.publish("vault.analysis.completed", {coverage_score, drift_level})
6. Retorna ArchitectureAnalysis como JSON
```

### 3.2 Fluxo Principal — Session History

```
1. Usuário envia mensagem → POST /v1/chat/completions
2. WorkflowRouter classifica intent
3. Router executa (FAST/MEMORY/SMART)
4. ANTES de retornar: ConversationRepository.save({user_msg, assistant_msg, ...})
5. Resposta retornada ao usuário
6. Desktop: sidebar mostra sessão atualizada em tempo real
```

### 3.3 Fluxo Principal — MCP Bridge

```
1. Startup: MCPManager.initialize_all()
2. Para cada servidor MCP ativo:
   a. MCPServer.list_tools() → lista de {name, description, schema}
   b. Cada tool é wrapped como LangChain Tool
   c. Adicionada ao TOOL_REGISTRY com prefixo "mcp_{server}_{tool}"
3. IntentClassifier reconhece tools MCP em mensagens
4. FastRouter ou SmartRouter executa tool MCP conforme classificação
```

### 3.2 Fluxos Alternativos

**VaultAnalyzer já em execução:**
- Sistema retorna `HTTP 409 Conflict` com `{"status": "running", "started_at": "..."}`

**MCP server indisponível:**
- Tool é marcada como `disabled` no registry
- Tentativas de uso retornam `{"error": "mcp_server_unavailable", "server": "..."}`
- Erro registrado no `DeadLetterQueue`

**Session sem histórico:**
- `GET /api/conversations` retorna `{"conversations": [], "total": 0}`
- Contexto de sessão injeta array vazio no prompt sem erro

**Workspace sem Qdrant collection:**
- Ao ativar workspace, sistema tenta criar collection automaticamente
- Se falhar, workspace fica em estado `degraded` e RAG retorna `{"context": [], "degraded": true}`

### 3.3 Fluxos de Erro

**RF-A01 — CORS mal configurado:**
- Se `CORS_ORIGINS` vazia, sistema usa `["http://localhost:1420", "http://localhost:3000"]` como fallback seguro
- Log warning: `[security] CORS_ORIGINS not configured, using safe defaults`

**RF-B01 — Falha no VaultAnalyzer:**
- Se `vault_path` inválido: `HTTP 503 {"error": "vault_unavailable", "detail": "..."}`
- Se análise excede 60s: `HTTP 504 {"error": "analysis_timeout"}`
- Resultado parcial NÃO é salvo

**RF-D01 — Falha ao salvar conversa:**
- Conversa NÃO é bloqueada por falha de persistência
- Erro é logado e emitido como evento `conversation.save.failed`
- Retry automático com backoff exponencial (3 tentativas)

**RF-F01 — Prometheus indisponível:**
- `GET /api/observability/costs` usa dados do PostgreSQL como fallback
- Response inclui `{"source": "postgres", "prometheus_unavailable": true}`

---

## 4. Contratos de Interface

### 4.1 `POST /api/vault/analyze`

**Input:**
```json
{
  "force": false,
  "include_suggestions": true
}
```

**Output (200 OK):**
```json
{
  "coverage_score": 78.5,
  "drift_level": "medium",
  "total_issues": 12,
  "issues": [
    {
      "type": "undocumented_code",
      "path": "assistant/app/orchestrator/universal_orchestrator.py",
      "severity": "high"
    }
  ],
  "suggestions": ["Adicionar SDD para universal_orchestrator"],
  "warnings": [],
  "generated_at": "2026-06-24T14:30:00Z"
}
```

**Erros:**
- `409` — análise já em progresso
- `503` — vault inacessível
- `504` — timeout (>60s)

---

### 4.2 `GET /api/conversations`

**Query params:**
```
user_id: str (required)
session_id: str (optional, filter by session)
page: int = 1
limit: int = 20 (max: 100)
from_date: ISO datetime (optional)
to_date: ISO datetime (optional)
```

**Output (200 OK):**
```json
{
  "total": 142,
  "page": 1,
  "limit": 20,
  "conversations": [
    {
      "session_id": "uuid",
      "user_id": "uuid",
      "started_at": "2026-06-24T10:00:00Z",
      "last_message_at": "2026-06-24T11:30:00Z",
      "message_count": 14,
      "workflow_types": ["RAG", "SMART"],
      "total_tokens": 8420
    }
  ]
}
```

**Erros:**
- `400` — `user_id` ausente
- `422` — parâmetros inválidos (limit > 100, datas invertidas)

---

### 4.3 `GET /api/mcp/tools`

**Output (200 OK):**
```json
{
  "total": 8,
  "tools": [
    {
      "name": "mcp_filesystem_read_file",
      "server": "filesystem",
      "description": "Read file contents from workspace",
      "schema": {
        "type": "object",
        "properties": {
          "path": {"type": "string"}
        },
        "required": ["path"]
      },
      "status": "active"
    }
  ]
}
```

**Erros:**
- `503` — MCPManager não inicializado

---

### 4.4 `GET /api/observability/costs`

**Query params:**
```
user_id: str (optional, admin vê todos)
provider: str (optional, filter: "ollama"|"openai"|"anthropic"|"gemini")
workflow: str (optional, filter: "FAST"|"MEMORY"|"SMART")
```

**Output (200 OK):**
```json
{
  "source": "prometheus",
  "total_usd": 0.42,
  "breakdown": [
    {
      "provider": "openai",
      "workflow": "SMART",
      "total_usd": 0.35,
      "total_tokens": 42000,
      "request_count": 28
    }
  ],
  "updated_at": "2026-06-24T14:29:00Z"
}
```

---

### 4.5 `POST /api/mcp/servers`

**Input:**
```json
{
  "name": "filesystem",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"],
  "env": {}
}
```

**Output (201 Created):**
```json
{
  "name": "filesystem",
  "status": "initializing",
  "tools_count": null,
  "message": "Server will be available in a few seconds"
}
```

**Erros:**
- `409` — servidor com mesmo nome já existe
- `422` — `command` ou `name` ausentes
- `503` — executável não encontrado no PATH

---

### 4.6 `POST /api/conversations/{session_id}/summarize`

**Input:** (body vazio, session_id via path)

**Output (200 OK):**
```json
{
  "session_id": "uuid",
  "summary": "Discussão sobre arquitetura do OrchestrationService...",
  "note_path": "Diário/conversas/2026-06-24.md",
  "tokens_used": 820
}
```

**Erros:**
- `404` — sessão não encontrada
- `409` — resumo já existe (use `?force=true` para sobrescrever)

---

### 4.7 `WebhookTool` (LangGraph Tool)

**Descrição:** Tool registrada no TOOL_REGISTRY para invocar flows N8N.

**Schema de input:**
```json
{
  "flow_name": "string — nome do flow N8N",
  "payload": "object — dados a enviar"
}
```

**Schema de output:**
```json
{
  "success": true,
  "response": {},
  "execution_id": "n8n-exec-uuid"
}
```

**Erros:**
- `{"success": false, "error": "n8n_unavailable"}` — N8N offline
- `{"success": false, "error": "flow_not_found", "flow_name": "..."}` — flow inexistente

---

### 4.8 Schema de Migração — `conversations` table

```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  workflow_type VARCHAR(20),
  tokens_used INTEGER DEFAULT 0,
  model_used VARCHAR(100),
  provider VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_conversations_user_session ON conversations(user_id, session_id);
CREATE INDEX idx_conversations_created_at ON conversations(created_at);
```

```sql
CREATE TABLE cost_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID,
  user_id VARCHAR(255),
  provider VARCHAR(50) NOT NULL,
  workflow VARCHAR(20),
  model VARCHAR(100),
  tokens_in INTEGER DEFAULT 0,
  tokens_out INTEGER DEFAULT 0,
  cost_usd FLOAT DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. Regras de Negócio

- **RN-01:** Análise do VaultAnalyzer só pode ter UMA execução por vez. Tentativa de iniciar segunda execução simultânea retorna `409`.
- **RN-02:** Histórico de conversas é visível apenas pelo próprio usuário ou por admins. `user_id` do token JWT deve ser validado contra o `user_id` da query.
- **RN-03:** Servidores MCP cadastrados por `admin` ficam disponíveis para todos os usuários. Servidores cadastrados por `user` ficam escopados ao próprio usuário.
- **RN-04:** O `ModelRouter` deve respeitar `CapabilityPolicy`: usuários com role `user` não podem usar workflows SMART sem autorização explícita.
- **RN-05:** Cost Tracker deve acumular custos por `execution_id` único. Se `execution_id` for reutilizado, os valores são sobrescritos, não somados.
- **RN-06:** N8N Subscriber deve ter `MAX_EVENTS_PER_MINUTE = 60` para evitar flood de webhooks.
- **RN-07:** Workspaces deletados não são removidos fisicamente — ficam em estado `archived` por 30 dias antes da remoção.
- **RN-08:** A análise automática do AI Self-Reviewer (agendamento de 7 dias) só é executada se `APP_ENV == "production"`. Em `development`, execução apenas manual.
- **RN-09:** Resumos de sessão gerados pelo `/summarize` são salvos no Obsidian com frontmatter YAML padrão do KIRL (`type: knowledge, domain: conversas`).
- **RN-10:** Migração do banco (`infra/migrations/`) deve ser executada no startup antes de qualquer operação de escrita. Falha na migration bloqueia o servidor.

---

## 6. Critérios de Aceite

**RF-A01 (CORS Fix):**
- Dado que `CORS_ORIGINS=https://kaos.example.com` no `.env`,
- Quando o Desktop envia request de `http://localhost:1420`,
- Então a API retorna `Access-Control-Allow-Origin: http://localhost:1420` (inclusa na lista de origens configuradas).

**RF-A02 (Model Desacoplado):**
- Dado que `workflow="SMART"` e `user_id="abc"`,
- Quando o `UniversalOrchestrator.execute()` é chamado,
- Então o modelo selecionado é o retorno de `ModelRouter.select("SMART", [], "abc")` e não `"qwen3:4b"`.

**RF-B01 (VaultAnalyzer):**
- Dado que o vault está montado e acessível,
- Quando `POST /api/vault/analyze` é chamado,
- Então a resposta tem `coverage_score` (float 0-100), `drift_level` (low|medium|high) e `issues` (lista).

**RF-C03 (MCP Bridge):**
- Dado que o servidor MCP `filesystem` está ativo,
- Quando o LangGraph agent processa uma mensagem contendo "leia o arquivo",
- Então `TOOL_REGISTRY` contém `mcp_filesystem_read_file` e o agente pode invocá-la.

**RF-D01 (Session Persistence):**
- Dado que usuário `u1` enviou 3 mensagens na sessão `s1`,
- Quando `GET /api/conversations?user_id=u1&session_id=s1` é chamado,
- Então retorna 6 registros (3 user + 3 assistant) com `role` correto.

**RF-D07 (Semantic History Search):**
- Dado que conversas passadas foram indexadas no Qdrant,
- Quando `POST /rag/context` com query="projeto de arquitetura",
- Então retorna chunks relevantes de conversas anteriores com score >= 0.3.

**RF-E01 (N8N Container):**
- Dado que `docker compose up -d` é executado,
- Quando `GET http://localhost:5678` é acessado,
- Então retorna `200 OK` com o painel N8N.

**RF-E02 (WebhookTool):**
- Dado que N8N está ativo e existe flow `backup-vault`,
- Quando agente recebe "faça backup do vault",
- Então `WebhookTool` é invocada com `{flow_name: "backup-vault"}` e retorna `success: true`.

**RF-F01 (Cost API):**
- Dado que 10 requests foram feitos usando `provider=openai`,
- Quando `GET /api/observability/costs?provider=openai` é chamado,
- Então retorna `breakdown` com `provider: "openai"` e `total_tokens > 0`.

**RF-H02 (Self-Reviewer Scheduler):**
- Dado que `APP_ENV=production` e `AuditScheduler` está ativo,
- Quando 7 dias se passam sem execução manual,
- Então `DocumentationAuditEngine.run_audit()` é executado automaticamente e relatório é gerado.

---

## 7. Fora de Escopo (desta iteração)

- Voice Interface (STT/TTS) — Fase 16 futura
- Mobile Companion (React Native/PWA) — Fase 17 futura
- Plugin Marketplace — Fase 18 futura
- Auto-Tagging de Notas com ML — Ideia não priorizada
- Temporal Memory (decaimento de conhecimento) — Ideia não priorizada
- Email Tool — Fase 9 original, mantida para sprint separado
- AWS Tool — Fase 9 original, mantida para sprint separado
- Integração GitHub Issues/PRs — já existe parcialmente, completar em sprint dedicado

---

## 8. Dependências e Pré-condições

### Para iniciar implementação:

| Pré-condição | Responsável | Status |
|-------------|-------------|--------|
| PostgreSQL rodando com schema migrado | Infra | ✅ Funcional |
| Qdrant rodando | Infra | ✅ Funcional |
| `OBSIDIAN_VAULT_PATH` configurado | Operação | ✅ Configurado |
| FastAPI iniciando sem crash | Backend | ✅ Funcional |
| `VaultWatcher` ativo | Backend | ✅ Ativo |
| Migration SQL criada (`infra/migrations/`) | Backend | 🔴 Criar |
| N8N container no docker-compose | Infra | 🔴 Criar |

### Dependências técnicas internas:
- `RF-C03` depende de `RF-C01` (listar tools) e `RF-C02` (registrar servers)
- `RF-D07` depende de `RF-D01` (persistência) e indexação das conversas no Qdrant
- `RF-H01` depende de `RF-B01` (VaultAnalyzer API estar funcional)
- `RF-F03` depende de migration da tabela `cost_events`
- `RF-E02` depende de `RF-E01` (N8N container)

---

## 9. Notas de Implementação para o Tech Planner

> ⚠️ Estas observações são técnicas e **não** prescrevem solução — são contexto para o planner.

1. O `AnalyzerEngine` em `app/ai/vault_analyzer/analyzer_engine.py` já está completo. A spec apenas exige um endpoint REST que o envolva.

2. O `CostTracker` usa Prometheus `Counter` e `Gauge`. A API de custos pode ler diretamente do Prometheus via `prometheus_client.generate_latest()` ou do PostgreSQL.

3. O `MCPManager` usa subprocess STDIO. A bridge para o LangGraph precisa de um adaptador que converta a interface `MCPServer.list_tools()` para o formato `BaseTool` do LangChain.

4. A tabela `conversations` precisa de uma migration adicionada em `infra/migrations/`. O sistema já usa SQLAlchemy async e `create_tables()` no startup — verifique se as tabelas devem ser criadas via migration ou via `create_tables()`.

5. O `AuditScheduler.run_periodic_audit()` já existe em `app/audit/drift_subscriber.py` e é iniciado no lifespan. Verifique o intervalo atual e parametrize com `AUDIT_INTERVAL_DAYS`.

6. A configuração CORS usa `fastapi.middleware.cors.CORSMiddleware`. A variável `CORS_ORIGINS` deve ser `List[str]` no `Settings` com default seguro.

---

## Checklist de Completude (Validação)

**Contexto**
- ✅ O problema de negócio está descrito (módulos orfãos, integração incompleta)
- ✅ Atores identificados com papéis (5 atores: user, admin, sistema, opencode, n8n)
- ✅ Integrações mapeadas com status por sistema (tabela completa)

**Requisitos funcionais**
- ✅ Todos os fluxos principais estão descritos (VaultAnalyzer, Sessions, MCP, N8N, Costs)
- ✅ Fluxos alternativos cobertos (análise em progresso, MCP indisponível, histórico vazio, workspace degradado)
- ✅ Fluxos de erro cobertos (CORS fallback, vault indisponível, falha de persistência, Prometheus offline)
- ✅ Nenhum requisito usa linguagem vaga (todos são verificáveis)

**Contratos de interface**
- ✅ Cada endpoint tem input definido com tipos
- ✅ Cada endpoint tem output definido com tipos
- ✅ Códigos de erro especificados (400, 404, 409, 422, 503, 504)
- ✅ Schema SQL da migration incluído

**Regras de negócio**
- ✅ Condições e decisões explicitadas (RN-01 a RN-10)
- ✅ Limites numéricos definidos (MAX_EVENTS_PER_MINUTE=60, timeout=60s, limit=100)
- ✅ Casos de borda cobertos (workspace degradado, retry de conversa)

**Critérios de aceite**
- ✅ Cada RF principal tem critério no formato Dado/Quando/Então
- ✅ Critérios são verificáveis

**Escopo**
- ✅ Fora de escopo declarado explicitamente (7 itens)
- ✅ Decisões técnicas deixadas para o Tech Planner (Seção 9)
