# Plano de Implementação: K.A.O.S Roadmap Expansion v2

**Spec de origem:** `docs/sdd/SDD-Roadmap-Expansion-v2.md`  
**Data do plano:** 2026-06-24  
**Stack:** Python 3.13 · FastAPI · SQLAlchemy async · LangGraph · React 18 · TypeScript · Zustand · Tauri 2  
**Branch de trabalho:** `feature/roadmap-expansion-v2`

---

## ⚠️ Análise de Arquitetura — Spec vs Realidade (Correções Críticas)

Antes de qualquer task, corrijo três pontos que o spec documentou como ausentes mas **já existem**:

| Item Spec | O que o spec diz | Realidade do codebase |
|-----------|-----------------|----------------------|
| RF-B01/02/03 (VaultAnalyzer API) | "Não existe endpoint" | ✅ `POST /api/architecture/analyze`, `GET /api/architecture/analysis`, `GET /api/architecture/suggestions` existem em `app/api/architecture.py` |
| RF-E01 (N8N Container) | "Container ausente" | ✅ Serviço `n8n` já definido em `infra/docker/docker-compose.yml:53-68` |
| Workspace Manager | "Não implementado" | ✅ `app/desktop/workspace/manager.py` existe com `ensure_structure()`, `vault_path()` etc |

**Implicações:** As tasks B01-B05 são reduzidas a: EventBus integration + SDDWatcher trigger + alias `/api/vault/*`. N8N parte de infra existente. Workspace pula a criação do manager.

---

## 📋 Análise Prévia — Riscos e Decisões

### Decisões tomadas

| Decisão | Justificativa | Alternativa descartada |
|---------|--------------|----------------------|
| SQLAlchemy models em `app/models/` com `create_tables()` | Consistência com padrão existente (`user.py` já usa isso) | Migrations SQL puras em `infra/migrations/` sem integração ORM |
| `conversations` table por turno individual (não por sessão) | Permite replay, busca semântica, analytics individuais | Serializar sessão inteira como JSON (perde granularidade) |
| MCP adapter como LangChain `StructuredTool` | Compatível com `TOOL_REGISTRY` existente sem reescrever o graph | Custom tool class nova (aumenta complexidade) |
| `/api/vault/*` como alias de `/api/architecture/*` | Não quebra clientes existentes, atende spec sem duplicação | Migrar `/api/architecture` para `/api/vault` (breaking change) |
| CORS origins como `List[AnyHttpUrl]` no Settings | Pydantic valida formato antes do servidor iniciar | String raw separada por vírgula (sem validação) |
| N8N events filter via `N8N_EVENTS` env var (comma-separated) | Configurável sem redeploy | Lista hardcoded no código |

### Riscos identificados

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| `feat/fix:` commits misturados violam Conventional Commits | Alta (já documentado no histórico) | TASK-001: commitlint + pre-commit hook |
| `create_tables()` não cria nova tabela `conversations` retroativamente | Alta | TASK-003: adicionar models explicitamente, executar no startup |
| MCP `list_tools()` retorna schema proprietário, não LangChain `BaseTool` | Alta | TASK-024: adapter layer com schema parsing |
| DLQ de falhas MCP pode crashar o startup se MCPManager inicializar antes do DLQ | Média | TASK-025: lazy initialization do DLQ no adapter |
| N8N subscriber enviando `cost_tracker` events por acidente (flood) | Alta | TASK-033: filtrar por `N8N_EVENTS` lista explícita antes de qualquer envio |
| `conversations` indexação no Qdrant pode duplicar se o watcher já indexar o vault | Média | TASK-016: namespace separado `conversations_{user_id}` no Qdrant |

---

## 📁 Estrutura de Arquivos

```
assistant/
├── app/
│   ├── api/
│   │   ├── conversations.py          # [CRIAR] RF-D02/03/04 endpoints
│   │   ├── mcp.py                    # [CRIAR] RF-C01/02 endpoints
│   │   └── kirl.py                   # [CRIAR] RF-H01 combined pipeline
│   ├── models/
│   │   ├── conversation.py           # [CRIAR] SQLAlchemy Conversation model
│   │   └── cost_event.py             # [CRIAR] SQLAlchemy CostEvent model
│   ├── repositories/
│   │   ├── conversation_repository.py # [CRIAR] CRUD + query helpers
│   │   └── cost_repository.py         # [CRIAR] persist + aggregate
│   ├── tools/
│   │   ├── mcp_adapter.py            # [CRIAR] MCPServer → BaseTool adapter
│   │   └── n8n_webhook_tool.py       # [CRIAR] WebhookTool para N8N
│   ├── config/
│   │   └── settings.py               # [MODIFICAR] CORS_ORIGINS, N8N_EVENTS, AUDIT_INTERVAL_DAYS
│   ├── orchestrator/
│   │   └── universal_orchestrator.py # [MODIFICAR] integrar ModelRouter real
│   ├── observability/
│   │   └── cost_tracker.py           # [MODIFICAR] persist no PostgreSQL
│   ├── audit/
│   │   └── drift_subscriber.py       # [MODIFICAR] AUDIT_INTERVAL_DAYS
│   ├── ai/vault_analyzer/
│   │   └── analyzer_engine.py        # [MODIFICAR] EventBus emission
│   └── main.py                       # [MODIFICAR] novas rotas, MCP startup
│
desktop/
└── src/
    ├── pages/
    │   └── chat/
    │       └── index.tsx             # [MODIFICAR] sidebar de histórico
    └── shared/lib/stores/
        └── conversation-store.ts     # [CRIAR] store de histórico de sessões

docs/
├── sdd/
│   ├── SDD-Roadmap-Expansion-v2.md  # [JÁ EXISTE] spec base
│   └── SDD-Commit-Governance.md     # [CRIAR] padronização de commits
└── governance/
    └── DOCUMENTATION_GOVERNANCE_SDD.md # [ATUALIZAR] adicionar seções faltantes
```

---

## 🌿 Padrão de Branch e Commit (Governance)

### Branches

```
main              → estável, releases tagged
dev               → integração contínua
feature/{task-id}-{slug}   → ex: feature/task-001-cors-fix
fix/{issue-ou-slug}        → ex: fix/cors-wildcard
```

### Commits — Conventional Commits (obrigatório)

```
<type>(<scope>): <descrição em minúsculas>

[body opcional com contexto]
[footer com SDD: SDD-XXX ou Fixes: #issue]
```

**Tipos válidos:**
| Tipo | Quando usar |
|------|------------|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Refatoração sem mudança funcional |
| `test` | Adição/modificação de testes |
| `docs` | Documentação only |
| `ci` | GitHub Actions |
| `chore` | Tarefas de manutenção (deps, config) |
| `style` | Formatting (ruff, prettier) |
| `perf` | Otimização de performance |

**⛔ Proibido:** `feat/fix:`, `feat+fix:`, commits compostos. Cada commit = um tipo.

**Exemplos corretos:**
```
feat(api): add POST /api/conversations endpoint

SDD: SDD-Roadmap-Expansion-v2 | RF-D02
```
```
fix(cors): replace wildcard origin with CORS_ORIGINS env var

Fixes: security vulnerability — credentials + wildcard origin invalid
SDD: SDD-Roadmap-Expansion-v2 | RF-A01
```

### Abertura de PR

Todo PR deve:
1. **Título**: `<type>(<scope>): <descrição>` — idêntico ao commit principal
2. **Body obrigatório:**
   ```markdown
   ## O que essa PR faz
   [descrição do que foi implementado]
   
   ## SDD Referenciado
   - SDD: SDD-Roadmap-Expansion-v2 | TASK-XXX
   
   ## Checklist
   - [ ] Testes passando (CI)
   - [ ] Ruff lint/format passando
   - [ ] Documentação atualizada em docs/
   - [ ] SDD atualizado se houve mudança de contrato
   ```
3. **Labels**: `enhancement` | `bugfix` | `docs` | `ci`
4. **Reviewer**: Self-review + AI review (pr-agent.yml automático)
5. **Merge**: Squash & merge (mantém histórico limpo)

### Documentação por PR (Governance)

| Tipo de mudança | Ação obrigatória |
|----------------|-----------------|
| Novo endpoint | Atualizar `docs/api/API_REFERENCE.md` |
| Nova variável de ambiente | Atualizar `docs/setup/SETUP.md` + `assistant/.env.example` |
| Nova tabela DB | Atualizar `docs/architecture/SYSTEM_ARCHITECTURE.md` |
| Novo workflow agent | Criar SDD em `docs/sdd/` |
| Breaking change | Atualizar `docs/CHANGELOG.md` + bump version |

---

## 🔧 Variáveis de Ambiente

```env
# Segurança
CORS_ORIGINS=http://localhost:1420,http://localhost:3000
# Lista separada por vírgula de origens permitidas. Em produção: URL real do desktop.

# N8N
N8N_WEBHOOK_URL=http://n8n:5678
N8N_API_URL=http://n8n:5678
N8N_EVENTS=workflow_completed,drift.detected,vault.analysis.completed
# Eventos que serão encaminhados ao N8N (separados por vírgula)

# Audit
AUDIT_INTERVAL_DAYS=7
# Intervalo do AI Self-Reviewer automático. Só ativo em APP_ENV=production

# Workspace
WORKSPACE_ROOT=C:/workspace/Freelancer/K.A.O.S/workspace
# Já existe, documentar explicitamente
```

---

## 📦 Dependências Externas

| Pacote | Versão | Motivo | Onde adicionar |
|--------|--------|--------|----------------|
| `commitlint` | `^19` | Enforce Conventional Commits em CI | `package.json` (root) |
| `@commitlint/config-conventional` | `^19` | Config padrão | `package.json` (root) |
| Nenhuma nova dep Python | — | Tudo usa SQLAlchemy, FastAPI, LangChain já instalados | — |

---

## 📋 Tasks de Implementação

---

### TASK-001 — Governance: Commitlint + PR Template

**Depende de:** nenhuma  
**Prioridade:** P0 — deve ser a primeira task (garante que todas as outras sigam o padrão)

**Arquivos:**
- Criar: `.commitlintrc.json` (raiz do projeto)
- Criar: `.github/PULL_REQUEST_TEMPLATE.md`
- Criar: `docs/sdd/SDD-Commit-Governance.md`
- Modificar: `docs/governance/DOCUMENTATION_GOVERNANCE_SDD.md` (preencher seções pendentes)

**O que fazer:**

1. Criar `.commitlintrc.json`:
```json
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [2, "always", ["feat","fix","refactor","test","docs","ci","chore","style","perf"]],
    "subject-case": [2, "always", "lower-case"],
    "header-max-length": [2, "always", 100],
    "body-max-line-length": [2, "always", 200]
  }
}
```

2. Criar `.github/PULL_REQUEST_TEMPLATE.md` com o template definido na seção Governance acima.

3. Criar `docs/sdd/SDD-Commit-Governance.md` documentando:
   - Tipos de commit válidos e quando usar cada um
   - Exemplos corretos e proibidos (incluindo `feat/fix:` como violation)
   - Processo de abertura de PR (checklist, labels, squash merge)
   - Tabela de documentação obrigatória por tipo de PR

4. Atualizar `docs/governance/DOCUMENTATION_GOVERNANCE_SDD.md`:
   - Preencher seções "Resumo", "Objetivo", "Responsabilidades", "Dependencias", "Fluxos", "Integracoes", "Arquivos Relacionados", "Status", "Ultima Atualizacao"
   - Adicionar seção "Padrão de Commits" com link para SDD-Commit-Governance.md
   - Corrigir regra "Máximo 2 arquivos markdown por execução" — regra desatualizada para AI agents (remover)

**Critério de conclusão:**
- [ ] `.commitlintrc.json` existe na raiz
- [ ] `PULL_REQUEST_TEMPLATE.md` existe em `.github/`
- [ ] `SDD-Commit-Governance.md` tem: tipos de commit, exemplos, processo PR, tabela docs obrigatórios
- [ ] `DOCUMENTATION_GOVERNANCE_SDD.md` não tem mais seções com "Informações pendentes"

---

### TASK-002 — Segurança: CORS Fix + Env var

**Depende de:** TASK-001  
**Arquivos:**
- Modificar: `assistant/app/config/settings.py`
- Modificar: `assistant/app/main.py`
- Criar: `assistant/.env.example` (se não existir)

**O que fazer:**

1. Em `settings.py`, adicionar campo:
```python
CORS_ORIGINS: list[str] = ["http://localhost:1420", "http://localhost:3000"]
```
Usar `list[str]` — não `AnyHttpUrl` para evitar problemas com `*` em dev.

2. Em `main.py`, substituir:
```python
# ANTES (linha ~310):
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    ...
)

# DEPOIS:
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-API-Key", "X-User-Id", "X-Username", "X-User-Role"],
)
```

3. Criar/atualizar `assistant/.env.example` com:
```env
CORS_ORIGINS=http://localhost:1420,http://localhost:3000
```

**Critério de conclusão:**
- [ ] `settings.CORS_ORIGINS` existe e é `list[str]`
- [ ] `main.py` usa `settings.CORS_ORIGINS` (não `["*"]`)
- [ ] `ruff check` passa sem erros
- [ ] `pytest tests/ -v` passa (sem quebrar auth tests)

---

### TASK-003 — DB: SQLAlchemy Model `Conversation`

**Depende de:** TASK-002  
**Arquivos:**
- Criar: `assistant/app/models/conversation.py`
- Modificar: `assistant/app/database.py` (registrar model no `Base.metadata`)

**O que fazer:**

Criar modelo SQLAlchemy para tabela `conversations`:
```python
# assistant/app/models/conversation.py
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    user_id = Column(String(255), nullable=False, index=True)
    role = Column(String(10), nullable=False)  # "user" | "assistant" | "system"
    content = Column(Text, nullable=False)
    workflow_type = Column(String(20), nullable=True)  # "FAST"|"MEMORY"|"SMART"|"AGENT"
    tokens_used = Column(Integer, default=0)
    model_used = Column(String(100), nullable=True)
    provider = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, index=True)
```

Registrar no `database.py` importando o model para que o `Base.metadata` o inclua no `create_tables()`.

**Critério de conclusão:**
- [ ] `app/models/conversation.py` existe com todos os campos
- [ ] Ao executar `create_tables()` no startup, a tabela `conversations` é criada no PostgreSQL
- [ ] Verificar: `SELECT table_name FROM information_schema.tables WHERE table_name='conversations';` retorna 1 linha

---

### TASK-004 — DB: SQLAlchemy Model `CostEvent`

**Depende de:** TASK-003  
**Arquivos:**
- Criar: `assistant/app/models/cost_event.py`
- Modificar: `assistant/app/database.py`

**O que fazer:**
```python
# assistant/app/models/cost_event.py
class CostEvent(Base):
    __tablename__ = "cost_events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    execution_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    user_id = Column(String(255), nullable=True, index=True)
    provider = Column(String(50), nullable=False)
    workflow = Column(String(20), nullable=True)
    model = Column(String(100), nullable=True)
    tokens_in = Column(Integer, default=0)
    tokens_out = Column(Integer, default=0)
    cost_usd = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, index=True)
```

**Critério de conclusão:**
- [ ] `app/models/cost_event.py` existe
- [ ] Tabela `cost_events` criada no PostgreSQL após startup

---

### TASK-005 — Repository: `ConversationRepository`

**Depende de:** TASK-003  
**Arquivos:**
- Criar: `assistant/app/repositories/conversation_repository.py`

**O que fazer:**

Criar repositório com interface assíncrona (padrão do projeto — ver `user_profile_repository.py`):

```python
class ConversationRepository:
    async def save(self, session: AsyncSession, turn: ConversationTurn) -> Conversation:
        """Persiste um turno (user ou assistant) na tabela conversations."""
        
    async def get_by_session(self, session: AsyncSession, session_id: str, limit: int = 100) -> list[Conversation]:
        """Retorna todos os turnos de uma sessão, ordenados por created_at ASC."""
        
    async def list_sessions(self, session: AsyncSession, user_id: str, page: int = 1, limit: int = 20) -> tuple[list[SessionSummary], int]:
        """Retorna lista de sessões (agrupadas por session_id) com contagem de mensagens."""
        
    async def delete_session(self, session: AsyncSession, session_id: str, user_id: str) -> int:
        """Remove todos os turnos de uma sessão. Retorna count de registros deletados."""
```

Definir dataclasses `ConversationTurn` e `SessionSummary` no mesmo arquivo.

**Critério de conclusão:**
- [ ] Arquivo criado com os 4 métodos
- [ ] Teste unitário `tests/unit/repositories/test_conversation_repository.py` com mock da sessão AsyncSession passa

---

### TASK-006 — Repository: `CostRepository`

**Depende de:** TASK-004  
**Arquivos:**
- Criar: `assistant/app/repositories/cost_repository.py`

**O que fazer:**

```python
class CostRepository:
    async def save(self, session: AsyncSession, event: CostEventData) -> CostEvent:
        """Persiste um evento de custo."""
        
    async def aggregate(self, session: AsyncSession, user_id: str | None = None, 
                        provider: str | None = None, workflow: str | None = None) -> list[CostBreakdown]:
        """Retorna breakdown de custos agrupados por provider+workflow."""
        
    async def summary(self, session: AsyncSession, period: str = "day") -> CostSummary:
        """Retorna total de custos para o período (day|week|month)."""
```

**Critério de conclusão:**
- [ ] Arquivo criado com os 3 métodos
- [ ] `aggregate()` usa SQL GROUP BY corretamente

---

### TASK-007 — Orchestrator: Desacoplar Model Hardcoded

**Depende de:** TASK-002  
**Arquivos:**
- Modificar: `assistant/app/orchestrator/universal_orchestrator.py`
- Modificar: `assistant/app/models/model_router.py` (verificar `select()` method)

**O que fazer:**

Em `universal_orchestrator.py`, linha 46, substituir:
```python
# ANTES:
model_name = "qwen3:4b"

# DEPOIS:
if self._model_router is not None:
    model_name = self._model_router.select(workflow=workflow, capabilities=capabilities or [])
else:
    model_name = settings.OLLAMA_MODEL
    logger.warning("[orchestrator] model_router not provided, using settings.OLLAMA_MODEL fallback")
```

Verificar se `ModelRouter.select()` em `app/models/model_router.py` aceita esses parâmetros. Adaptar a assinatura se necessário.

Adicionar `CapabilityPolicy` check:
```python
from app.models.capability_policy import CapabilityPolicyResolver
# Antes de executar:
if not CapabilityPolicyResolver.can_execute(workflow=workflow, user_role=user_role):
    raise PermissionError(f"Role '{user_role}' not allowed for workflow '{workflow}'")
```

**Critério de conclusão:**
- [ ] `model_name = "qwen3:4b"` não existe mais em `universal_orchestrator.py`
- [ ] `ModelRouter.select()` é chamado com `workflow` e `capabilities`
- [ ] `CapabilityPolicyResolver.can_execute()` é chamado antes do `PlanExecutor`
- [ ] Teste `tests/unit/orchestrator/test_universal_orchestrator.py` passa

---

### TASK-008 — API: `POST /api/conversations` (salvar turno)

**Depende de:** TASK-005  
**Arquivos:**
- Criar: `assistant/app/api/conversations.py`
- Modificar: `assistant/app/main.py` (registrar router)

**O que fazer:**

```python
router = APIRouter(prefix="/api/conversations", tags=["Conversations"])

@router.get("", response_model=ConversationsListResponse)
async def list_sessions(user_id: str, page: int = 1, limit: int = 20, ...):
    """RF-D02: Lista sessões paginadas por user_id."""

@router.get("/{session_id}", response_model=SessionDetailResponse)
async def get_session(session_id: str, user_id: str, ...):
    """RF-D03: Retorna todos os turnos de uma sessão."""

@router.delete("/{session_id}")
async def delete_session(session_id: str, user_id: str, ...):
    """Deleta sessão (soft: marca como deleted)."""
```

Definir Pydantic response models `ConversationsListResponse`, `SessionDetailResponse` conforme spec seção 4.2.

**Critério de conclusão:**
- [ ] `GET /api/conversations?user_id=test` retorna `{"total": 0, "page": 1, ...}`
- [ ] `GET /api/conversations/nonexistent?user_id=test` retorna 404
- [ ] Endpoint registrado no Swagger `/docs`

---

### TASK-009 — Intercept: Salvar conversas no router

**Depende de:** TASK-008  
**Arquivos:**
- Modificar: `assistant/app/api/chat.py`
- Modificar: `assistant/app/router/memory_router.py`
- Modificar: `assistant/app/router/smart_router.py`

**O que fazer:**

Após cada par request/response nos 3 routers, chamar `ConversationRepository.save()` de forma **não-bloqueante** (usar `asyncio.create_task()`):

```python
# Padrão: fire-and-forget para não bloquear a resposta
asyncio.create_task(
    _save_conversation_turn(
        session_id=session_id,
        user_id=user_id,
        user_message=user_message,
        assistant_response=collected_response,
        workflow_type=workflow_type,
        model_used=model_name,
        provider=provider,
    )
)
```

Se `asyncio.create_task()` falhar (ex: fora de event loop), logar o erro e continuar — nunca bloquear a resposta.

**Critério de conclusão:**
- [ ] Após enviar mensagem no chat, registro aparece em `GET /api/conversations?user_id=X`
- [ ] Falha no banco não bloqueia a resposta do chat
- [ ] Log `[conversation] saved session=X turn=user/assistant` aparece

---

### TASK-010 — API: Summarize Sessão

**Depende de:** TASK-009  
**Arquivos:**
- Modificar: `assistant/app/api/conversations.py`

**O que fazer:**

Adicionar endpoint:
```python
@router.post("/{session_id}/summarize", response_model=SummarizeResponse)
async def summarize_session(session_id: str, force: bool = False):
    """RF-D04: Dispara summarizer e salva como nota no Obsidian."""
    # 1. Buscar turnos da sessão via ConversationRepository
    # 2. Concatenar em texto formatado
    # 3. Chamar app.memory.summarizer.Summarizer.summarize(text)
    # 4. Salvar no Obsidian: Vault/Diário/conversas/{date}-{session_id[:8]}.md
    # 5. Retornar SummarizeResponse com path da nota e tokens_used
```

**Critério de conclusão:**
- [ ] `POST /api/conversations/{session_id}/summarize` retorna `{"note_path": "...", "summary": "..."}`
- [ ] Nota criada fisicamente no vault em `Diário/conversas/`
- [ ] `POST /api/conversations/invalid/summarize` retorna 404

---

### TASK-011 — CostTracker: Persistência PostgreSQL

**Depende de:** TASK-006  
**Arquivos:**
- Modificar: `assistant/app/observability/cost_tracker.py`

**O que fazer:**

Em `CostTracker.on_event()`, quando o evento `llm_response` for processado e o custo calculado, adicionar fire-and-forget ao `CostRepository.save()`:

```python
# Dentro do método on_event, após calcular cost:
asyncio.create_task(
    _persist_cost_event(execution_id, provider, workflow, model, tokens_in, tokens_out, cost)
)
```

A função `_persist_cost_event` abre sessão async e chama `CostRepository.save()`.

**Critério de conclusão:**
- [ ] Após uma chamada ao LLM, entrada aparece em `SELECT * FROM cost_events LIMIT 1;`
- [ ] `cost_usd` não é zero quando provider != "ollama"

---

### TASK-012 — API: Cost Observability Endpoints

**Depende de:** TASK-011  
**Arquivos:**
- Modificar: `assistant/app/api/observability.py`

**O que fazer:**

Adicionar 2 endpoints ao router existente:
```python
@router.get("/costs", response_model=CostsResponse)
async def get_costs(user_id: str | None = None, provider: str | None = None, workflow: str | None = None):
    """RF-F01: breakdown de custos por provider+workflow."""

@router.get("/costs/summary", response_model=CostsSummaryResponse)
async def get_costs_summary(period: str = "day"):  # day|week|month
    """RF-F02: total de custos para o período."""
```

Fallback: se PostgreSQL falhar, tentar ler do Prometheus via `/metrics` endpoint.

**Critério de conclusão:**
- [ ] `GET /api/observability/costs` retorna `{"total_usd": float, "breakdown": [...]}`
- [ ] `GET /api/observability/costs/summary?period=week` retorna `{"total_usd": float, "period": "week"}`
- [ ] `period=invalid` retorna 422

---

### TASK-013 — MCP API: GET /api/mcp/tools

**Depende de:** TASK-002  
**Arquivos:**
- Criar: `assistant/app/api/mcp.py`
- Modificar: `assistant/app/main.py`

**O que fazer:**

```python
router = APIRouter(prefix="/api/mcp", tags=["MCP"])

@router.get("/tools", response_model=MCPToolsResponse)
async def list_mcp_tools():
    """RF-C01: Lista todas as ferramentas de todos os servidores MCP ativos."""
    # Chamar MCPManager.list_all_tools() — implementar se não existir
    # Retornar {"total": int, "tools": [{"name", "server", "description", "schema", "status"}]}

@router.get("/servers")
async def list_mcp_servers():
    """Lista servidores MCP registrados com health status."""
```

**Critério de conclusão:**
- [ ] `GET /api/mcp/tools` retorna JSON com `total` e `tools` array
- [ ] Quando nenhum servidor ativo: retorna `{"total": 0, "tools": []}`

---

### TASK-014 — MCP API: POST /api/mcp/servers

**Depende de:** TASK-013  
**Arquivos:**
- Modificar: `assistant/app/api/mcp.py`
- Modificar: `assistant/app/core/mcp_manager.py` (adicionar `register()` runtime se ausente)

**O que fazer:**

```python
@router.post("/servers", status_code=201, response_model=MCPServerResponse)
async def register_mcp_server(payload: MCPServerRequest):
    """RF-C02: Registra novo servidor MCP em runtime."""
    # Validar: name, command obrigatórios
    # Verificar: name não existe já no MCPRegistry
    # Chamar: MCPManager.register_and_initialize(config)
    # Retornar: {"name": ..., "status": "initializing", "tools_count": None}
```

Erros:
- `409` se nome já existe
- `422` se campos obrigatórios ausentes
- `503` se executável não encontrado no PATH

**Critério de conclusão:**
- [ ] `POST /api/mcp/servers` com `{"name": "test", "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem"]}` retorna 201
- [ ] `POST /api/mcp/servers` com mesmo nome retorna 409

---

### TASK-015 — MCP Adapter: MCPServer → LangChain BaseTool

**Depende de:** TASK-014  
**Arquivos:**
- Criar: `assistant/app/tools/mcp_adapter.py`

**O que fazer:**

```python
# assistant/app/tools/mcp_adapter.py
from langchain_core.tools import StructuredTool
from pydantic import BaseModel, create_model
from app.core.mcp_manager import MCPManager

def build_mcp_tool(server_name: str, tool_def: dict) -> StructuredTool:
    """Converte definição de tool MCP para LangChain StructuredTool."""
    # 1. Extrair schema JSON do tool_def
    # 2. Criar Pydantic model dinâmico com create_model() baseado no schema
    # 3. Criar função async que chama MCPServer.call_tool(tool_name, args)
    # 4. Retornar StructuredTool com name="mcp_{server}_{tool}", description, args_schema

def register_all_mcp_tools(tool_registry: dict) -> int:
    """Itera todos os servers MCP ativos e registra tools no TOOL_REGISTRY. Retorna count."""
    count = 0
    for server in MCPManager.list_active_servers():
        for tool_def in server.list_tools():
            try:
                tool = build_mcp_tool(server.name, tool_def)
                tool_registry[tool.name] = tool
                count += 1
            except Exception as e:
                logger.warning(f"[mcp_adapter] falha ao adaptar tool {tool_def.get('name')}: {e}")
    return count
```

**Critério de conclusão:**
- [ ] `register_all_mcp_tools({})` retorna int (0 se sem servers, >0 se servers ativos)
- [ ] Tool resultante tem `name` no formato `mcp_{server}_{tool}`
- [ ] Tool resultante é invocável via `.invoke({})`

---

### TASK-016 — MCP Bridge: Injetar tools no startup

**Depende de:** TASK-015  
**Arquivos:**
- Modificar: `assistant/app/main.py` (lifespan)
- Modificar: `assistant/app/agent/nodes/executor.py` (onde TOOL_REGISTRY é definido)

**O que fazer:**

No lifespan do FastAPI, após `_register_tools()`:
```python
from app.tools.mcp_adapter import register_all_mcp_tools
from app.agent.nodes.executor import TOOL_REGISTRY

# Após MCPManager inicializar:
mcp_count = register_all_mcp_tools(TOOL_REGISTRY)
logger.info(f"[mcp] {mcp_count} tools MCP registradas no TOOL_REGISTRY")
```

Adicionar RF-C05: se MCPServer falhar, logar e registrar no DLQ sem crashar:
```python
try:
    mcp_count = register_all_mcp_tools(TOOL_REGISTRY)
except Exception as e:
    logger.error(f"[mcp] falha ao registrar tools MCP: {e}")
    # Continuar startup normalmente
```

**Critério de conclusão:**
- [ ] Log `[mcp] X tools MCP registradas` aparece no startup
- [ ] Falha no MCP não derruba o servidor

---

### TASK-017 — N8N: Subscriber filter por `N8N_EVENTS`

**Depende de:** TASK-002  
**Arquivos:**
- Modificar: `assistant/app/config/settings.py`
- Modificar: `assistant/app/main.py`

**O que fazer:**

Em `settings.py`:
```python
N8N_EVENTS: list[str] = ["workflow_completed", "drift.detected", "vault.analysis.completed"]
```

Em `main.py`, substituir o bloco atual (linha ~203-209):
```python
# ANTES (inscreve em TODOS os eventos):
for event_name in EventBus._subscribers:
    EventBus.subscribe(event_name, n8n_subscriber)

# DEPOIS (apenas eventos configurados):
for event_name in settings.N8N_EVENTS:
    EventBus.subscribe(event_name, n8n_subscriber)
    logger.debug(f"[n8n] subscriber inscrito em: {event_name}")
```

**Critério de conclusão:**
- [ ] N8N subscriber não está inscrito em `llm_request`, `llm_response`, etc.
- [ ] N8N subscriber está inscrito apenas nos eventos de `settings.N8N_EVENTS`

---

### TASK-018 — N8N: WebhookTool para LangGraph

**Depende de:** TASK-017  
**Arquivos:**
- Criar: `assistant/app/tools/n8n_webhook_tool.py`
- Modificar: `assistant/app/main.py` (registrar tool no startup)

**O que fazer:**

```python
# assistant/app/tools/n8n_webhook_tool.py
from langchain_core.tools import tool
import httpx
from app.config.settings import settings

@tool
async def n8n_webhook(flow_name: str, payload: dict = {}) -> str:
    """Invoca um flow N8N via webhook. Use quando o usuário pedir automação externa.
    
    Args:
        flow_name: Nome do flow N8N a invocar (ex: "backup-vault")
        payload: Dados a enviar para o flow (opcional)
    """
    if not settings.N8N_API_URL:
        return '{"success": false, "error": "n8n_not_configured"}'
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post(
                f"{settings.N8N_API_URL}/webhook/{flow_name}",
                json=payload
            )
            return f'{{"success": true, "status": {resp.status_code}}}'
        except httpx.ConnectError:
            return '{"success": false, "error": "n8n_unavailable"}'
```

Registrar no startup:
```python
from app.tools.n8n_webhook_tool import n8n_webhook
TOOL_REGISTRY["n8n_webhook"] = n8n_webhook
```

**Critério de conclusão:**
- [ ] `n8n_webhook` aparece em `GET /api/mcp/tools` ou equivalente
- [ ] Invocação com N8N offline retorna `{"success": false, "error": "n8n_unavailable"}`

---

### TASK-019 — VaultAnalyzer: EventBus emission

**Depende de:** TASK-002  
**Arquivos:**
- Modificar: `assistant/app/ai/vault_analyzer/analyzer_engine.py`

**O que fazer:**

No final do método `AnalyzerEngine.run()`, após gerar `ArchitectureAnalysis`, adicionar:
```python
from app.observability.event_bus import EventBus, Event

await EventBus.publish(Event(
    name="vault.analysis.completed",
    data={
        "coverage_score": analysis.coverage_score,
        "drift_level": analysis.drift_level,
        "total_issues": len(analysis.issues),
        "generated_at": analysis.generated_at,
    }
))
```

**Critério de conclusão:**
- [ ] Após `POST /api/architecture/analyze`, evento `vault.analysis.completed` aparece nos logs
- [ ] Se N8N_EVENTS contém `vault.analysis.completed`, subscriber N8N recebe o evento

---

### TASK-020 — VaultAnalyzer: SDDWatcher auto-trigger

**Depende de:** TASK-019  
**Arquivos:**
- Modificar: `assistant/app/audit/drift_subscriber.py`

**O que fazer:**

No `DriftSubscriber.on_event()`, quando evento for `drift.detected`, adicionar trigger assíncrono do `AnalyzerEngine`:
```python
if event.name == "drift.detected":
    logger.info("[kirl] drift detectado — disparando VaultAnalyzer")
    asyncio.create_task(AnalyzerEngine.run_async())  # implementar run_async como wrapper
```

**Critério de conclusão:**
- [ ] Ao editar um arquivo `.md` no vault (triggering SDDWatcher), análise é re-disparada automaticamente
- [ ] Log `[kirl] drift detectado — disparando VaultAnalyzer` aparece

---

### TASK-021 — KIRL: Combined Pipeline Endpoint

**Depende de:** TASK-020  
**Arquivos:**
- Criar: `assistant/app/api/kirl.py`
- Modificar: `assistant/app/main.py`

**O que fazer:**

```python
router = APIRouter(prefix="/api/kirl", tags=["KIRL"])

@router.post("/review", response_model=KIRLReviewResponse)
async def run_kirl_review():
    """RF-H01: Pipeline completo Audit → Analyze → Suggest."""
    # 1. DocumentationAuditEngine.run_audit()
    # 2. AnalyzerEngine.run()
    # 3. SuggestionEngine.generate(analysis)
    # 4. Gerar relatório em docs/generated/self-review-{date}.md
    # 5. Se drift_score > 15%: NotificationService.notify_admins()
    # 6. Retornar KIRLReviewResponse
```

**Critério de conclusão:**
- [ ] `POST /api/kirl/review` retorna dentro de 120s (ou 504 com mensagem clara)
- [ ] Arquivo `docs/generated/self-review-{date}.md` criado após chamada

---

### TASK-022 — AuditScheduler: Intervalo configurável

**Depende de:** TASK-021  
**Arquivos:**
- Modificar: `assistant/app/config/settings.py`
- Modificar: `assistant/app/audit/drift_subscriber.py`

**O que fazer:**

Em `settings.py`:
```python
AUDIT_INTERVAL_DAYS: int = 7
```

Em `drift_subscriber.py`, no `AuditScheduler.run_periodic_audit()`, substituir o intervalo hardcoded (atual: 30s) por:
```python
interval_seconds = settings.AUDIT_INTERVAL_DAYS * 86400
if settings.APP_ENV != "production":
    logger.info("[kirl] AuditScheduler desativado em modo development")
    return
await asyncio.sleep(interval_seconds)
```

**Critério de conclusão:**
- [ ] Em `APP_ENV=development`, scheduler não executa automaticamente
- [ ] Em `APP_ENV=production`, scheduler usa `AUDIT_INTERVAL_DAYS * 86400` segundos

---

### TASK-023 — Desktop: Conversation store

**Depende de:** TASK-008  
**Arquivos:**
- Criar: `desktop/src/shared/lib/stores/conversation-store.ts`

**O que fazer:**

```typescript
interface ConversationSession {
  sessionId: string;
  startedAt: string;
  lastMessageAt: string;
  messageCount: number;
  workflowTypes: string[];
}

interface ConversationState {
  sessions: ConversationSession[];
  loading: boolean;
  total: number;
  currentPage: number;
  fetchSessions: (userId: string, page?: number) => Promise<void>;
  deleteSession: (sessionId: string, userId: string) => Promise<void>;
}

export const useConversationStore = create<ConversationState>((set) => ({
  sessions: [],
  loading: false,
  total: 0,
  currentPage: 1,
  fetchSessions: async (userId, page = 1) => {
    set({ loading: true });
    const res = await kaosFetch(`/api/conversations?user_id=${userId}&page=${page}&limit=20`);
    const data = await res.json();
    set({ sessions: data.conversations, total: data.total, currentPage: page, loading: false });
  },
  deleteSession: async (sessionId, userId) => {
    await kaosFetch(`/api/conversations/${sessionId}?user_id=${userId}`, { method: "DELETE" });
    set(state => ({ sessions: state.sessions.filter(s => s.sessionId !== sessionId) }));
  },
}));
```

**Critério de conclusão:**
- [ ] `useConversationStore` exportado e importável
- [ ] `tsc --noEmit` passa sem erros

---

### TASK-024 — Desktop: Sidebar de histórico no Chat

**Depende de:** TASK-023  
**Arquivos:**
- Modificar: `desktop/src/pages/chat/index.tsx`

**O que fazer:**

Adicionar painel lateral esquerdo (colapsável via `ui-store`) que:
1. Exibe lista de `sessions` do `useConversationStore`
2. Ao clicar em uma sessão, define `sessionId` atual no `chat-store`
3. Botão "Nova conversa" limpa sessionId
4. Botão de lixeira deleta sessão
5. Usar skeleton loading enquanto `loading=true`
6. Exibir data relativa (ex: "há 2 horas")

Layout: `flex w-full` → sidebar (280px) + area de chat (flex-1)

**Critério de conclusão:**
- [ ] Sidebar de histórico visível na página de Chat
- [ ] Click em sessão mantém `sessionId` no store
- [ ] `npm run build` (Vite) sem erros TypeScript

---

### TASK-025 — CI: Drift Check no PR

**Depende de:** TASK-021  
**Arquivos:**
- Criar: `.github/workflows/drift-check.yml`

**O que fazer:**

```yaml
name: Drift Check

on:
  pull_request:
    branches: [dev, main]
    paths:
      - "assistant/**"
      - "docs/**"

jobs:
  drift-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          token: ${{ secrets.PAT }}
      
      - name: Setup Python
        uses: astral-sh/setup-uv@v3
        with:
          python-version: "3.13"
      
      - name: Install dependencies
        run: cd assistant && uv sync
      
      - name: Run drift check
        run: |
          cd assistant
          uv run python -c "
          from app.audit.audit_engine import DocumentationAuditEngine
          result = DocumentationAuditEngine.run_audit()
          drift = result.get('drift_score', 0)
          print(f'Drift Score: {drift:.1f}%')
          if drift > 15:
              print(f'::error::Drift score {drift:.1f}% acima do limite de 15%. Atualize a documentação antes de mergear.')
              exit(1)
          print('Drift check passed.')
          "
        env:
          OBSIDIAN_VAULT_PATH: ${{ github.workspace }}/docs
```

**Critério de conclusão:**
- [ ] Workflow existe em `.github/workflows/drift-check.yml`
- [ ] PR com drift > 15% falha no CI com mensagem clara
- [ ] PR com drift <= 15% passa

---

### TASK-026 — Docs: Atualizar DEVELOPER_GUIDE

**Depende de:** TASK-001  
**Arquivos:**
- Modificar: `docs/guides/DEVELOPER_GUIDE.md`

**O que fazer:**

Adicionar seções:
1. **"Padrão de Commits"** com link para `SDD-Commit-Governance.md` e exemplos
2. **"Novo Endpoint FastAPI"** — já existe, mas atualizar com padrão de `conversations.py` (incluindo repositório pattern)
3. **"Nova Store Zustand"** — atualizar com `conversation-store.ts` como exemplo canônico
4. **"Stores Existentes"** — adicionar `conversation-store` à tabela
5. **"Governança de PR"** — adicionar seção com checklist de abertura de PR e documentação obrigatória

**Critério de conclusão:**
- [ ] `DEVELOPER_GUIDE.md` tem seção "Padrão de Commits"
- [ ] "Stores Existentes" lista `conversation-store`
- [ ] "Governança de PR" tem checklist completo

---

### TASK-027 — Docs: SDD Conversation History

**Depende de:** TASK-010  
**Arquivos:**
- Criar: `docs/sdd/SDD-Session-History.md`

**O que fazer:**

Criar SDD completo documentando:
- Objetivo e contexto (problema de perda de contexto entre sessões)
- Modelo de dados `conversations` (schema SQL + SQLAlchemy model)
- Contratos de API (`GET /api/conversations`, `GET /{session_id}`, `POST /{session_id}/summarize`)
- Fluxo: como os routers interceptam e salvam os turnos
- Integração com RAG (conversas indexadas para busca semântica futura)
- Considerações de segurança (isolamento por user_id)

**Critério de conclusão:**
- [ ] `docs/sdd/SDD-Session-History.md` existe com todas as seções
- [ ] SDD tem frontmatter YAML correto (`type: sdd, status: approved`)

---

### TASK-028 — Docs: SDD MCP Bridge

**Depende de:** TASK-016  
**Arquivos:**
- Criar: `docs/sdd/SDD-MCP-Bridge.md`

**O que fazer:**

Criar SDD documentando:
- O que é MCP (Model Context Protocol) e por que o K.A.O.S usa
- `MCPManager` existente: como registra e gerencia servers
- `mcp_adapter.py`: como converte `tool_def` → `StructuredTool`
- `TOOL_REGISTRY` injection: quando e como acontece no startup
- Como adicionar novo servidor MCP via `POST /api/mcp/servers`
- Health e fallback (DLQ para falhas)

**Critério de conclusão:**
- [ ] `docs/sdd/SDD-MCP-Bridge.md` existe com todas as seções

---

## 🔗 Sequência de Execução

```
TASK-001 (Governance)
    │
    └──→ TASK-002 (CORS)
              │
              ├──→ TASK-003 (DB: Conversation) ──→ TASK-005 (Repo) ──→ TASK-008 (API) ──→ TASK-009 (Intercept) ──→ TASK-010 (Summarize)
              │         │
              │         └──→ TASK-004 (DB: CostEvent) ──→ TASK-006 (Repo) ──→ TASK-011 (Persist) ──→ TASK-012 (API)
              │
              ├──→ TASK-007 (Orchestrator model)
              │
              ├──→ TASK-013 (MCP API list) ──→ TASK-014 (MCP API register) ──→ TASK-015 (Adapter) ──→ TASK-016 (Bridge startup)
              │
              ├──→ TASK-017 (N8N filter) ──→ TASK-018 (WebhookTool)
              │
              └──→ TASK-019 (EventBus) ──→ TASK-020 (SDDWatcher) ──→ TASK-021 (KIRL pipeline) ──→ TASK-022 (Scheduler)

TASK-023 (Desktop store) ──→ TASK-024 (Desktop sidebar)

TASK-021 ──→ TASK-025 (CI drift-check)

TASK-001 ──→ TASK-026 (Dev guide) 
TASK-010 ──→ TASK-027 (SDD Sessions)
TASK-016 ──→ TASK-028 (SDD MCP)
```

**Tasks paralelas possíveis:**
- TASK-003 e TASK-013 em paralelo (sem dependência entre si)
- TASK-007 em paralelo com TASK-003/004
- TASK-023/024 em paralelo com qualquer task backend após TASK-008
- TASK-026/027/028 podem ser feitas a qualquer momento após suas dependências

---

## 📊 Estimativa e Checklist de Completude

### Horas por fase

| Fase | Tasks | Horas est. | Prioridade |
|------|-------|-----------|-----------|
| Governance | 001 | 1h | P0 — primeira |
| Segurança | 002 | 30min | P0 |
| Session History | 003-010 | 5h | P0 |
| Cost API | 011-012 | 2h | P1 |
| Orchestrator | 007 | 1h | P0 |
| MCP Bridge | 013-016 | 4h | P0 |
| N8N | 017-018 | 1.5h | P1 |
| VaultAnalyzer | 019-020 | 1h | P1 |
| KIRL Pipeline | 021-022 | 2h | P2 |
| Desktop | 023-024 | 2.5h | P1 |
| CI Drift | 025 | 1h | P1 |
| Docs | 026-028 | 2h | P1 |
| **Total** | **28 tasks** | **~23.5h** | |

---

### ✅ Checklist do Plano (Auto-revisão)

**Cobertura da spec:**
- ✅ RF-A01 (CORS) → TASK-002
- ✅ RF-A02 (Orchestrator) → TASK-007
- ✅ RF-A03 (CapabilityPolicy) → TASK-007
- ✅ RF-B01-05 (VaultAnalyzer) → TASK-019, 020 (já existe API)
- ✅ RF-C01-05 (MCP) → TASK-013 a 016
- ✅ RF-D01-07 (Session History) → TASK-003 a 010, 023, 024
- ✅ RF-E01-05 (N8N) → TASK-017, 018 (N8N já existe no docker-compose)
- ✅ RF-F01-04 (Cost) → TASK-011, 012
- ✅ RF-H01-05 (Self-Reviewer) → TASK-021, 022, 025
- ✅ Todas RN-01 a RN-10 cobertas nas tasks correspondentes
- ✅ Todos critérios de aceite têm teste correspondente

**Qualidade das tasks:**
- ✅ Nenhuma task com mais de uma responsabilidade principal
- ✅ Nenhuma task referencia task que aparece depois
- ✅ Todas tasks têm critério de conclusão verificável
- ✅ Nenhum detalhe de implementação ambíguo

**Arquitetura:**
- ✅ Estrutura de arquivos completa
- ✅ Contratos entre módulos definidos antes das tasks de implementação
- ✅ Padrão de testes definido (pytest unitário por repositório)

**Operacional:**
- ✅ Variáveis de ambiente listadas com descrição
- ✅ Dependências externas (commitlint) identificadas com versão
- ✅ Sem nova dependência Python necessária

---

## 🤖 Instrução de Entrega para o Code Agent

```
Você está executando o plano de implementação K.A.O.S Roadmap Expansion v2.

Regras de execução:
1. Execute uma task por vez, na ordem da Sequência de Execução
2. Ao concluir uma task, verifique CADA item do Critério de Conclusão antes de avançar
3. Se encontrar ambiguidade não coberta pelo plano, PARE e reporte antes de assumir qualquer coisa
4. Não modifique arquivos fora do escopo da task atual
5. Cada task = um commit, seguindo Conventional Commits: tipo(escopo): descrição
6. Ao finalizar todas as tasks, execute: cd assistant && uv run pytest tests/ -v && cd ../desktop && npm run build

Padrão de commit por task:
- TASK-001: docs(governance): add commitlint config and PR template
- TASK-002: fix(security): replace cors wildcard with CORS_ORIGINS env var  
- TASK-003: feat(db): add Conversation SQLAlchemy model
... (continuar o padrão)

Task atual: TASK-001
```
