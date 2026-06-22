# Arquitetura do Sistema — K.A.O.S

## Visão Geral

K.A.O.S é uma plataforma de orquestração de IA baseada em capacidades, com arquitetura de microsserviços monorepo, frontend desktop (Tauri) e backend modular (FastAPI).

```
┌───────────────────────────────────────────────────────────┐
│                    DESKTOP (Tauri)                         │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │ Command Pal. │ │   Chat UI   │ │  Architecture    │    │
│  │  (CTRL+K)   │ │  (SSE)      │ │   Graph          │    │
│  └─────────────┘ └──────────────┘ └──────────────────┘    │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │ Doc Health  │ │  Dashboard   │ │    Settings      │    │
│  └─────────────┘ └──────────────┘ └──────────────────┘    │
├───────────────────────────────────────────────────────────┤
│                   LAYER: Zustand Stores                    │
│  system-store · chat-store · agent-store · auth-store     │
│  ui-store · app-store · drift-store                       │
├───────────────────────────────────────────────────────────┤
│                 LAYER: Event Bus (TypeScript)              │
│  tool:* · agent:* · system:* · chat:* · docs:* · graph:*  │
└──────────────────────────┬────────────────────────────────┘
                           │ HTTP / SSE / WebSocket
┌──────────────────────────▼────────────────────────────────┐
│                     BACKEND (FastAPI)                      │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                    API Layer                         │  │
│  │  auth · chat · models · orchestrator · providers     │  │
│  │  rag · indexing · setup · audit · architecture       │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │              Service Layer                            │  │
│  │  service/  ·  llm/  ·  agent/  ·  memory/  ·  rag/   │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │            Workflow / Orchestration                   │  │
│  │  IntentClassifier → ModelRouter → ProviderSelector   │  │
│  │  → PlanExecutor → CircuitBreaker → DLQ               │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │              Provider Layer                           │  │
│  │  Chat · Embedding · Vector · Memory                   │  │
│  │  (Ollama, OpenAI, Anthropic, Gemini, Qdrant)          │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │            Observability / Event Bus                  │  │
│  │  Logger · Metrics · Tracing · Cost · Audit · n8n     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │          KIRL — Documentation Runtime Layer           │  │
│  │  FeatureRegistry → AuditEngine → DRLSnapshot         │  │
│  │  → Graphify → AutoDoc → SDDGenerator                 │  │
│  └─────────────────────────────────────────────────────┘  │
└──────────────────────────┬────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────┐
│                    INFRAESTRUTURA                          │
│                                                           │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
│  │Postgres│ │ Qdrant │ │ Ollama │ │  n8n   │ │  MCP   │  │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘  │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────────────┐  │
│  │Prometh.│ │  Loki  │ │Grafana │ │   Open WebUI     │  │
│  └────────┘ └────────┘ └────────┘ └──────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

---

## Camadas do Backend

### API Layer

Responsável por expor endpoints HTTP. Cada módulo possui seu próprio router FastAPI.

| Módulo | Prefixo | Descrição |
|--------|---------|-----------|
| `auth` | `/api/auth` | Autenticação |
| `chat` | `/api/chat` | Chat com streaming SSE |
| `models` | `/v1/models` | Catálogo de modelos |
| `orchestrator` | `/api/orchestrator` | Execução de workflows |
| `providers` | `/api/setup` | Configuração de providers |
| `rag` | `/rag` | Pipeline RAG |
| `indexing` | `/indexing` | Indexação do vault |
| `audit` | `/api/audit` | Auditoria documental (KIRL) |
| `health` | `/health` | Health check |

**Padrão de roteamento:**

```python
router = APIRouter(prefix="/api/chat", tags=["Chat"])

@router.post("/message")
async def chat_message(request: ChatRequest):
    ...
```

### Service Layer

Camada de negócio, orquestra chamadas entre providers, workflows e banco.

- `service/llm_service.py` — Abstração sobre providers de LLM
- `service/memory_service.py` — Gerenciamento de memória conversacional
- `service/notification_service.py` — Notificações

### Workflow / Orchestration

Pipeline de execução baseada em capacidades:

```
User Request
    ↓
IntentClassifier → define o workflow adequado
    ↓
ServiceRegistry → obtém o workflow
    ↓
ModelRouter → seleciona modelo pela capacidade necessária
    ↓
ProviderSelector → escolhe provedor disponível
    ↓
PlanExecutor → executa o plano com streaming
    ↓
CircuitBreaker → protege contra falhas
    ↓
DeadLetterQueue → armazena execuções falhas
```

### Provider Layer

Adaptadores para provedores de IA, seguindo contratos abstratos:

```
BaseChatProvider
├── OllamaChatProvider
├── OpenAIChatProvider
├── AnthropicChatProvider
└── GeminiChatProvider

BaseEmbeddingProvider
├── BGEEmbeddingProvider
└── OpenAIEmbeddingProvider

BaseVectorStore
└── QdrantVectorStore

BaseMemoryProvider
├── ObsidianMemoryProvider
└── PostgresMemoryProvider
```

### Observability / Event Bus

Sistema de eventos baseado em pub/sub com subscribers especializados:

```python
EventBus
├── LoggerSubscriber      → logs estruturados
├── MetricsSubscriber     → métricas Prometheus
├── TracingSubscriber     → OpenTelemetry spans
├── CostTracker           → custo por requisição
├── AuditSubscriber       → auditoria de execuções
├── N8NSubscriber         → webhooks para n8n
└── DriftSubscriber       → detecção de drift (KIRL)
```

22 eventos definidos, incluindo:
- `request_started`, `request_completed`
- `workflow_started`, `workflow_completed`
- `orchestrator.execution_*`
- `memory.*`, `conversation.*`
- `audit.*`, `drift.*`

---

## Camadas do Frontend

O frontend segue **Feature-Sliced Design (FSD)**:

```
src/
├── app/           # Inicialização, providers, rotas
├── pages/         # Páginas (uma por rota)
├── widgets/       # Componentes complexos (sidebar, command-palette)
├── features/      # Hooks de negócio organizados por feature
├── entities/      # Tipos de domínio + componentes puros
└── shared/        # Design system, stores, API client
```

### Stores (Zustand)

| Store | Estado | Uso |
|-------|--------|-----|
| `system-store` | status, metrics, documentation | Dashboard, sidebar |
| `chat-store` | messages, loading, streaming | Chat |
| `agent-store` | agents list, CRUD | Agents page |
| `auth-store` | apiKey, serverUrl, connected | Conexão com backend |
| `ui-store` | sidebarCollapsed, commandPaletteOpen | Layout |
| `app-store` | theme | Tema |
| `drift-store` | driftReport, isLoading | KIRL dashboard |

### Event Bus (TypeScript)

```typescript
type AppEvent =
  | { type: "tool:*"; payload: ToolEvent }
  | { type: "agent:*"; payload: AgentEvent }
  | { type: "system:*"; payload: SystemEvent }
  | { type: "chat:*"; payload: ChatEvent }
  | { type: "graph:updated"; payload: GraphData }
  | { type: "docs:*"; payload: DocsEvent }
```

### Command Palette (CTRL+K)

Comandos registrados no `CommandRegistry`:

| ID | Label | Categoria |
|----|-------|-----------|
| `go-dashboard` | Go to Dashboard | navigation |
| `go-chat` | Open Chat | navigation |
| `go-documentation` | Open Documentation Health | navigation |
| `run-audit` | Run Documentation Audit | actions |
| `audit-undocumented` | Show Undocumented Features | actions |
| `toggle-theme` | Toggle Theme | toggles |
| (mais 5) | ... | navigation |

---

## KIRL — K.A.O.S Intelligence Runtime Layer

Camada de auditoria documental que valida consistência entre código, commits e SDDs.

```
FeatureRegistry (fonte da verdade)
    ↓
CommitMapper (git log → features)
    ↓
CodeScanner (filesystem + regex)
    ↓
SDDResolver (docs existentes)
    ↓
AuditEngine (comparação e drift)
    ↓
DRLSnapshot (estado unificado)
    ↓
Graphify (grafo da arquitetura)
    ↓
AutoDoc (geração automática de SDDs)
```

Ver [Guia KIRL](guides/KIRL_GUIDE.md) para detalhes de uso.

---

## Fluxos de Dados

### Chat com Streaming

```
User → Chat UI → POST /api/chat/message
    → IntentClassifier → WorkflowRouter
    → ModelRouter → ProviderSelector
    → PlanExecutor → streaming SSE
    → Chat UI (tokens em tempo real)
    → MemoryService (salva conversa)
```

### Indexação do Vault

```
Obsidian Vault → VaultWatcher (watchdog)
    → detecta mudanças → VaultIndexer
    → TextSplitter (chunking)
    → Embedder (sentence-transformers)
    → Qdrant (storage vetorial)
```

### Auditoria KIRL

```
Manual (botão "Run Audit") ou automático (30s)
    → AuditEngine.run_audit()
    → FeatureRegistry.load_from_json()
    → CommitMapper.generate_map()
    → SDDResolver.scan_all_sdds()
    → CodeScanner.scan_all()
    → DriftReport (5 métricas)
    → persist JSONs (coverage, missing, inconsistencies)
    → DRLSnapshot.build_snapshot()
    → EventBus (audit.completed)
    → UI se atualiza (SystemStore.documentation)
```

---

## Dependências Entre Módulos

```
desktop/ (React/Tauri)
    ├── assistant/ (Python/FastAPI)
    │   ├── infra/ (Docker/Postgres/Qdrant)
    │   └── ollama/ (LLM)
    └── docs/ (Obsidian)
```

### Regras de Dependência (FSD)

```
app/ → widgets/, features/, entities/, shared/
widgets/ → features/, entities/, shared/
features/ → entities/, shared/
entities/ → shared/
shared/ → (nenhuma dependência interna)
```

---

## Segurança

- **API Key**: Autenticação via header `x-api-key` ou `Authorization: Bearer`
- **CORS**: Liberado para desenvolvimento (`allow_origins=["*"]`)
- **Senhas**: Gerenciadas via variáveis de ambiente
- **Chaves de API**: Armazenadas em `data/api_key.txt`, geradas automaticamente

---

## Observabilidade

### Métricas (Prometheus)

Endpoints instrumentados automaticamente via `prometheus-fastapi-instrumentator`:

- `http_request_duration_seconds`
- `http_requests_total`
- Métricas customizadas (tokens, custos, falhas)

### Logs (Loguru)

Formato JSON em produção:

```json
{
  "timestamp": "2026-06-22T10:30:00",
  "level": "INFO",
  "logger": "app.main",
  "message": "[audit] coverage=87.5%",
  "extra": {"event_name": "audit.completed"}
}
```

### Tracing (OpenTelemetry)

Spans para:

- Orchestrator execution
- LLM requests
- Workflow steps
- Provider calls

---

## Tecnologias por Camada

| Camada | Linguagem | Framework | Database | Cache |
|--------|-----------|-----------|----------|-------|
| Backend | Python 3.13 | FastAPI + LangGraph | PostgreSQL | — |
| Frontend | TypeScript 5.5 | React 18 + Zustand | — | — |
| Desktop | Rust | Tauri 2 | — | — |
| Vector DB | — | Qdrant | — | — |
| Observability | — | Prometheus + Loki + Grafana | — | — |
| CI/CD | — | GitHub Actions | — | — |
| Automation | — | n8n | — | — |
| MCP | — | Model Context Protocol | — | — |

---

## Diagrama de Implantação

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Usuário │────▶│ Desktop  │────▶│ Backend  │
│          │     │ :1420    │     │ :8000    │
└──────────┘     └──────────┘     └────┬─────┘
                                       │
              ┌────────────────────────┼────────────────────┐
              │                        │                    │
        ┌─────▼─────┐          ┌──────▼──────┐      ┌─────▼─────┐
        │ PostgreSQL │          │   Qdrant    │      │   Ollama  │
        │   :5432    │          │   :6333     │      │  :11434   │
        └───────────┘          └─────────────┘      └───────────┘
              │                                          │
        ┌─────▼─────┐                             ┌──────▼──────┐
        │ Prometheus │                             │  OpenAI /   │
        │   :9090    │                             │  Anthropic  │
        └───────────┘                             └─────────────┘
```

---

## Evolução da Arquitetura

### 2026 Q1 — Fundação
- LangGraph + Ollama + Qdrant
- RAG pipeline
- Obsidian watcher

### 2026 Q2 — Plataforma
- SDD-040 (Universal Orchestration)
- KIRL (Documentation Runtime Layer)
- Observabilidade (Prometheus, Grafana, Loki)

### 2026 Q3 — Inteligência
- AI Vault Analyzer
- Architecture Graph
- Auto-Documentation contínua
- OpenCode Configuration Layer

### 2026 Q4 — Autonomia
- AI Architecture Reviewer
- Self-Healing DRL
- Predictive Architecture
- MCP Integration

---

## Glossário Arquitetural

| Termo | Definição |
|-------|-----------|
| **Capacidade** | Habilidade que o sistema pode executar (chat, reasoning, coding) |
| **Workflow** | Sequência de passos para executar uma capacidade |
| **Provider** | Adaptador para um serviço externo (Ollama, OpenAI, Qdrant) |
| **SDD** | Software Design Document — documento de design |
| **KIRL** | K.A.O.S Intelligence Runtime Layer — auditoria documental |
| **DRL** | Documentation Runtime Layer — runtime da documentação |
| **FSD** | Feature-Sliced Design — organização frontend |
| **MCP** | Model Context Protocol — contexto para LLMs |
| **DLQ** | Dead Letter Queue — execuções falhas |
| **SSE** | Server-Sent Events — streaming de eventos |
