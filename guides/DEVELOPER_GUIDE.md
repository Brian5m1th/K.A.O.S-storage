---
id: developer_guide
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Guia do Desenvolvedor — K.A.O.S

## Estrutura de Pastas

```
K.A.O.S/
├── assistant/              # Backend Python
│   ├── app/
│   │   ├── main.py         # Inicialização, middleware, rotas
│   │   ├── api/            # FastAPI routers
│   │   ├── agent/          # LangGraph agent
│   │   ├── audit/          # KIRL (Documentation Runtime Layer)
│   │   ├── config/         # Settings + prompts
│   │   ├── domain/         # Domain models (pydantic)
│   │   ├── middleware/     # Custom middleware
│   │   ├── models/         # Model registry + router
│   │   ├── observability/  # EventBus, metrics, tracing
│   │   ├── obsidian/       # Vault integration + watcher
│   │   ├── orchestrator/   # PlanExecutor, CircuitBreaker, DLQ
│   │   ├── providers/      # Chat, Embedding, Vector, Memory
│   │   ├── rag/            # RAG pipeline
│   │   ├── router/         # Intent classification
│   │   ├── service/        # Business logic
│   │   ├── tools/          # LangGraph tools
│   │   └── workflows/      # Workflow definitions
│   ├── tests/              # Testes (unit + integration)
│   └── scripts/            # Scripts utilitários
│
├── desktop/                # Frontend Tauri + React
│   ├── src/
│   │   ├── app/            # Init, providers, routes
│   │   ├── pages/          # Screens (8 páginas)
│   │   ├── widgets/        # Sidebar, CommandPalette, TopBar
│   │   ├── features/       # Business logic hooks
│   │   ├── entities/       # Domain types + pure components
│   │   └── shared/         # UI kit, stores, utils
│   └── src-tauri/          # Rust (Tauri backend)
│
├── infra/                  # Infraestrutura
│   └── docker/             # Docker Compose + Dockerfiles
├── docs/                   # Documentação
└── .github/                # GitHub Actions
```

---

## Stores (Zustand)

### Criar uma Store

```typescript
// desktop/src/shared/lib/stores/minha-store.ts
import { create } from "zustand";

interface MinhaState {
  dados: string[];
  loading: boolean;
  fetchDados: () => Promise<void>;
}

export const useMinhaStore = create<MinhaState>((set) => ({
  dados: [],
  loading: false,

  fetchDados: async () => {
    set({ loading: true });
    try {
      const response = await fetch("/api/minha-rota");
      const data = await response.json();
      set({ dados: data, loading: false });
    } catch {
      set({ loading: false });
    }
  },
}));

// Selectors
export function useMeusDados() {
  return useMinhaStore((s) => s.dados);
}
```

### Consumir em um Componente

```typescript
import { useMinhaStore } from "@/shared/lib/stores/minha-store";

export function MeuComponente() {
  const { dados, loading, fetchDados } = useMinhaStore();

  useEffect(() => { fetchDados(); }, [fetchDados]);

  if (loading) return <p>Carregando...</p>;
  return <ul>{dados.map(d => <li>{d}</li>)}</ul>;
}
```

### Stores Existentes

| Store | Localização | Estado Principal |
|-------|-------------|------------------|
| `system-store` | `stores/system-store.ts` | status, metrics, documentation |
| `chat-store` | `stores/chat-store.ts` | messages, loading, streaming |
| `agent-store` | `stores/agent-store.ts` | agents list |
| `auth-store` | `stores/auth-store.ts` | apiKey, serverUrl, connected |
| `ui-store` | `stores/ui-store.ts` | sidebar, commandPalette |
| `app-store` | `stores/app-store.ts` | theme |
| `drift-store` | `features/documentation-audit/store/drift-store.ts` | driftReport, audit |

---

## Event Bus (TypeScript)

### Emitir um Evento

```typescript
import { eventBus } from "@/shared/lib/event-bus";

eventBus.emit({
  type: "system:status",
  payload: "online",
});
```

### Escutar um Evento

```typescript
import { useEffect } from "react";
import { eventBus } from "@/shared/lib/event-bus";

useEffect(() => {
  const unsubscribe = eventBus.on("system:metrics", (event) => {
    console.log(event.payload);
  });
  return unsubscribe;
}, []);
```

### Tipos de Evento

```typescript
type AppEvent =
  | { type: "tool:start" | "tool:complete"; payload: ToolEvent }
  | { type: "agent:status" | "agent:message"; payload: AgentEvent }
  | { type: "system:metrics" | "system:status"; payload: SystemEvent }
  | { type: "chat:stream-start" | "chat:stream-token" | "chat:stream-end" | "chat:error"; payload: ChatEvent }
  | { type: "graph:updated"; payload: GraphData }
  | { type: "docs:auto-updated" | "docs:sync-error"; payload: DocsEvent };
```

---

## APIs (FastAPI)

### Criar um Endpoint

```python
# assistant/app/api/minha_rota.py
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from loguru import logger

router = APIRouter(prefix="/api/minha-rota", tags=["MinhaRota"])

class MeuRequest(BaseModel):
    mensagem: str

class MeuResponse(BaseModel):
    resultado: str

@router.post("/executar", response_model=MeuResponse)
async def executar(request: MeuRequest):
    logger.info("[minha-rota] executando com {}", request.mensagem)
    return MeuResponse(resultado=f"Processado: {request.mensagem}")
```

### Registrar no App

```python
# assistant/app/main.py
from app.api.minha_rota import router as minha_rota_router
app.include_router(minha_rota_router)
```

### Padrões de API

| Padrão | Descrição |
|--------|-----------|
| `prefix="/api/recurso"` | Prefixo do módulo |
| `tags=["Tag"]` | Agrupamento no Swagger |
| `response_model=` | Schema de resposta (Pydantic) |
| `Depends()` | Injeção de dependência |
| `Async` | Todas as rotas são assíncronas |

---

## Event Bus (Python)

### Emitir um Evento

```python
from app.observability.event_bus import EventBus, Event
from uuid import uuid4

event = Event(
    name="meu.evento.executado",
    execution_id=uuid4(),
    trace_id=uuid4(),
    data={"chave": "valor"},
)
await EventBus.publish(event)
```

### Criar um Subscriber

```python
from app.observability.event_bus import Event, EventSubscriber

class MeuSubscriber(EventSubscriber):
    async def on_event(self, event: Event) -> None:
        if event.name == "meu.evento.executado":
            logger.info("Evento recebido: {}", event.data)
```

### Registrar

```python
# Em main.py, no _register_observability()
EventBus.subscribe("meu.evento.executado", MeuSubscriber())
```

### Eventos Existentes

```
request_started, request_completed
intent_classified, model_selected
workflow_started, workflow_completed, workflow_step
llm_request, llm_response
fallback_triggered
orchestrator.execution_started, .completed, .failed
memory.write.*, memory.read.*, memory.deleted
conversation.summarized, conversation.stored
audit.started, audit.completed, drift.detected
```

---

## Providers

### Contrato Base

```python
from abc import ABC, abstractmethod

class BaseChatProvider(ABC):
    provider_name: str

    @abstractmethod
    async def chat(self, messages, **kwargs) -> str: ...
    @abstractmethod
    async def stream(self, messages, **kwargs) -> AsyncIterator[str]: ...
    @abstractmethod
    async def models(self) -> list[str]: ...
    @abstractmethod
    async def healthcheck(self) -> bool: ...
```

### Implementar um Provider

```python
class MeuProvider(BaseChatProvider):
    provider_name = "meu-provider"

    async def chat(self, messages, **kwargs) -> str:
        # Lógica de chamada ao provider
        return "resposta"

    async def stream(self, messages, **kwargs) -> AsyncIterator[str]:
        yield "token"

    async def models(self) -> list[str]:
        return ["modelo-1"]

    async def healthcheck(self) -> bool:
        return True
```

### Registrar

```python
from app.providers.register_all import register_all_providers
register_all_providers()
```

---

## Workflows

### Contrato Base

```python
class BaseWorkflow(ABC):
    name: str
    version: str

    @property
    def required_capabilities(self) -> list[str]: ...

    async def execute(self, plan, request) -> AsyncIterator[str]: ...

    async def healthcheck(self) -> bool: ...
```

### Criar um Workflow

```python
from app.workflows.base import BaseWorkflow

class MeuWorkflow(BaseWorkflow):
    name = "meu-workflow"
    version = "1.0.0"

    @property
    def required_capabilities(self) -> list[str]:
        return ["fast_chat"]

    async def execute(self, plan, request):
        yield "processando..."
        resultado = await algum_processo(request)
        yield resultado
```

### Registrar

```python
from app.workflows.impl.registry import register_workflows
register_workflows()
```

---

## Agentes (LangGraph)

### Estado do Agente

```python
from typing import TypedDict, Annotated
from langgraph.graph import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    retrieved_context: list[str]
    tool_to_call: str | None
    tool_args: dict | None
    session_id: str
    user_id: str
```

### Nós do Grafo

```python
from langgraph.graph import StateGraph, END

def node_retrieve(state: AgentState) -> dict:
    context = search_similar(state["messages"][-1].content)
    return {"retrieved_context": context}

def node_generate(state: AgentState) -> dict:
    response = llm.generate(state["messages"], state["retrieved_context"])
    return {"messages": [response]}

graph = StateGraph(AgentState)
graph.add_node("retrieve", node_retrieve)
graph.add_node("generate", node_generate)
graph.add_edge("retrieve", "generate")
graph.add_edge("generate", END)
graph.set_entry_point("retrieve")
app = graph.compile()
```

---

## Ferramentas (LangGraph Tools)

### Criar uma Ferramenta

```python
from langchain_core.tools import tool

@tool
def minha_ferramenta(parametro: str) -> str:
    """Descrição do que a ferramenta faz."""
    return f"Processado: {parametro}"
```

### Registrar

```python
from app.tools.github_tools import register_github_tools
register_github_tools()
```

### Ferramentas Existentes

- ReadNoteTool
- CreateNoteTool
- DeleteNoteTool
- SearchNotesTool
- ListNotesTool
- SaveConversationTool
- ListProjectsTool
- GitHub (PR, Issue, File)

---

## Páginas (Frontend)

### Criar uma Página

```typescript
// desktop/src/pages/minha-pagina/index.tsx
import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/shared/ui/card";

export function MinhaPagina() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Minha Página</h1>
      <Card>
        <CardHeader><CardTitle>Conteúdo</CardTitle></CardHeader>
        <CardContent>
          <p>Olá, mundo!</p>
        </CardContent>
      </Card>
    </div>
  );
}
```

### Adicionar Rota

```typescript
// desktop/src/app/routes/pages/minha-pagina/index.tsx
import { MinhaPagina } from "@/pages/minha-pagina";
export default MinhaPagina;
```

### Registrar no Router

```typescript
// desktop/src/app/routes/index.tsx
import MinhaPagina from "./pages/minha-pagina";

// Adicionar ao array de rotas:
<Route path="/minha-pagina" element={
  <Suspense><AnimatedPage><MinhaPagina /></AnimatedPage></Suspense>
} />
```

### Adicionar na Sidebar

```typescript
// desktop/src/widgets/sidebar/index.tsx
const NAV_ITEMS = [
  // ...
  { id: "minha-pagina", label: "Minha Pagina", path: "/minha-pagina", icon: MeuIcone },
];
```

---

## Eventos (Criação)

### Backend (Python)

1. Adicionar constante em `observability/event_bus.py`
2. Emitir com `await EventBus.publish(event)`
3. Criar subscriber se necessário

### Frontend (TypeScript)

1. Adicionar tipo em `shared/lib/event-bus.ts` (AppEvent union)
2. Emitir com `eventBus.emit({ type, payload })`
3. Escutar com `eventBus.on(type, handler)`

---

## Integrações

### Criar uma Integração

1. Identificar o serviço externo
2. Criar provider adapter se for um LLM/vector DB
3. Criar API endpoints se for uma API REST
4. Criar subscriber se for event-driven
5. Documentar em `docs/providers/` ou `docs/guides/`
6. Registrar no `main.py` + `docker-compose.yml` se necessário

### Integrações Existentes

- Ollama (LLM local)
- OpenAI (LLM cloud)
- Anthropic (LLM cloud)
- Gemini (LLM cloud)
- Qdrant (vector DB)
- PostgreSQL (database)
- n8n (automação)
- Obsidian (vault)
- GitHub (tools)
- Prometheus + Grafana (observabilidade)
- MCP (Model Context Protocol)

---

## Boas Práticas

### Python
- Type hints obrigatórios (`def func(x: str) -> int:`)
- Usar `| None` em vez de `Optional` (`x: str | None = None`)
- Usar `list[X]` em vez de `List[X]` (PEP 585)
- Logs com tags: `[start]`, `[finish]`, `[info]`, `[error]`
- Exceptions com loguru

### TypeScript
- Strict mode habilitado
- Imports absolutos com `@/` (`@/shared/ui/button`)
- Function components com `interface Props`
- Hooks prefixados com `use`
- Stores em Zustand com selectors

### Commits
```
feat: nova funcionalidade
fix: correção de bug
docs: documentação
test: testes
refactor: refatoração
style: formatação
```

## Resumo
- Informações pendentes de validação ou auto-geração.

## Objetivo
- Informações pendentes de validação ou auto-geração.

## Responsabilidades
- Informações pendentes de validação ou auto-geração.

## Padrão de Commits

Todo commit deve seguir **Conventional Commits** conforme definido em
[SDD-Commit-Governance.md](../sdd/SDD-Commit-Governance.md).

### Formato

```
<tipo>(<escopo>): <descrição em minúsculas>

[body opcional]
SDD: SDD-Nome | RF-XXX
```

### Tipos Válidos

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Refatoração sem mudança funcional |
| `test` | Testes |
| `docs` | Documentação |
| `ci` | CI/CD |
| `chore` | Manutenção (deps, config) |
| `style` | Formatting |
| `perf` | Performance |

### Exemplos

```
feat(api): add POST /api/conversations endpoint
fix(cors): replace wildcard origin with CORS_ORIGINS env var
docs(governance): add commitlint config and PR template
```

### ⛔ Proibido

- `feat/fix:` — barra separadora
- `feat+fix:` — tipos compostos
- Commits sem tipo (`atualiza`, `wip`)

## Stores Existentes (Zustand)

| Store | Função | Arquivo |
|-------|--------|---------|
| `useAppStore` | Tema (dark/light) | `shared/lib/stores/app-store.ts` |
| `useAuthStore` | Autenticação JWT + API Key | `shared/lib/stores/auth-store.ts` |
| `useChatStore` | Mensagens do chat + streaming | `shared/lib/stores/chat-store.ts` |
| `useAgentStore` | Agentes LangGraph | `shared/lib/stores/agent-store.ts` |
| `useConversationStore` | Histórico de sessões | `shared/lib/stores/conversation-store.ts` |
| `useUIStore` | UI state (sidebar, modals) | `shared/lib/stores/ui-store.ts` |
| `useThemeStore` | Tema (synced with app-store) | `shared/lib/stores/theme-store.ts` |
| `useSystemStore` | System info + health | `shared/lib/stores/system-store.ts` |
| `useUpdateStore` | Auto-update Tauri | `shared/lib/stores/update-store.ts` |

## Governança de PR

### Checklist de Abertura de PR

- [ ] Testes passando (`pytest tests/ -v`)
- [ ] Ruff lint/format passando (`ruff check . && ruff format --check .`)
- [ ] Documentação atualizada em `docs/` (se aplicável)
- [ ] SDD atualizado se houve mudança de contrato
- [ ] Variáveis de ambiente documentadas em `.env.example` (se aplicável)
- [ ] `desktop/` — `npm run build` passa sem erros (se aplicável)

### Documentação Obrigatória por Tipo de PR

| Tipo de mudança | Ação obrigatória |
|----------------|-----------------|
| Novo endpoint | Atualizar `docs/api/API_REFERENCE.md` |
| Nova variável de ambiente | Atualizar `assistant/.env.example` + `docs/setup/SETUP.md` |
| Nova tabela DB | Atualizar `docs/architecture/SYSTEM_ARCHITECTURE.md` |
| Novo workflow agent | Criar SDD em `docs/sdd/` |
| Breaking change | Atualizar `docs/CHANGELOG.md` + bump version |

## Dependencias

- Python 3.13 (via `uv`)
- Node.js 20+ (para desktop)
- PostgreSQL 16
- Qdrant
- Docker + Docker Compose (para infra completa)
- Rust + Tauri CLI (para build desktop)

## Fluxos

### Desenvolvimento Local

1. `cd assistant && uv sync`
2. `uv run uvicorn app.main:app --reload --port 8000`
3. Em outro terminal: `cd desktop && npm run dev`

### Testes

```bash
cd assistant
uv run pytest tests/ -v --asyncio-mode=auto
```

### Build Desktop

```bash
cd desktop
npm run build
npx tauri build
```

## Arquivos Relacionados

- `docs/sdd/SDD-Commit-Governance.md` — Padronização de commits e PRs
- `.commitlintrc.json` — Regras de commitlint
- `.github/PULL_REQUEST_TEMPLATE.md` — Template de PR
- `docs/governance/DOCUMENTATION_GOVERNANCE_SDD.md` — Governança de documentação

## Status

**Vigente** — atualizado em 2026-06-24.

## Ultima Atualizacao

2026-06-24 — Adicionado Padrão de Commits, Stores Existentes, Governança de PR, seções de dependências preenchidas.
