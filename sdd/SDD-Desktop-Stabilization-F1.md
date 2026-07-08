---
type: sdd
domain: desktop
status: approved
version: 1.0
date: 2026-06-22
author: kaos-architect
phase: Fase 1
---

# SDD — Desktop Stabilization (Fase 1)
*K.A.O.S Desktop App — Mock Removal & Backend Connectivity*

> Plano executivo de estabilizacao do desktop K.A.O.S, removendo dados mockados, conectando stores a endpoints reais e destravando o backend (vault).

## Parent
- [[Roadmap Geral]]

## Children
- [[architecture]] (proxima fase)

## Related
- [[SDD-KIRL]]
- [[Configuração de Provedores]]
- [[Arquitetura de Orquestracao]]
- [[sdd_desktop_build_optimization]]

## Tags
#kaos #fase1 #desktop #stabilization #sdd

---

## Sumario Executivo

O desktop K.A.O.S foi construido como um **frontend de demonstracao** com dados mockados em varias paginas. O backend real (`assistant/`, FastAPI) ja existe com dezenas de endpoints funcionais, mas o desktop nunca foi conectado a eles. Alem disso, o backend **nao inicia** devido a um erro de configuracao do vault (`FileNotFoundError: Vault nao encontrado: /vault`).

Esta SDD define o plano para:

1. **Destravar o backend** — corrigir o vault path para que a API inicie sem crash
2. **Criar endpoints faltantes** — `/api/providers`, `/api/system/status`
3. **Conectar stores** — auth-store, system-store, useSystemMetrics hooks
4. **Remover mocks** — Dashboard, Observability, Orchestration, Settings
5. **Melhorar UX** — dropdown de provider + modelo, botoes funcionais, estado vazio

### Roadmap Macro

| Fase | Nome | Status |
|-|-|-|
| **FASE 0** | KIRL (Documentation Runtime) | ✅ Concluida |
| **FASE 1** | **Desktop Stabilization** | 🔜 **Agora** |
| FASE 2 | Auth & First Run Wizard | 📅 Proxima |
| FASE 3 | Provider Catalog | 📅 Futuro |
| FASE 4 | Observability Real (Prometheus + Loki) | 📅 Futuro |
| FASE 5 | OpenCode Layer | 📅 Futuro |
| FASE 6 | Multi User + RBAC | 📅 Futuro |

---

## 1. Diagnostico — Estado Atual

### 1.1 Backend

| Aspecto | Estado |
|-|-|
| Codigo do backend | `assistant/` (FastAPI) |
| Diretorio `backend/` | Vazio (apenas `.gitkeep`) |
| Servico `kaos-api` | **Nao inicia** — `FileNotFoundError: /vault` |
| Endpoints existentes | ~25 routers registrados em `main.py` |
| WebSocket `/ws/metrics` | **Nao existe** — desktop tenta conectar e falha |

### 1.2 Desktop — Paginas com Mocks

| Pagina | Mock | Endpoint Real | Status do Endpoint |
|-|-|-|-|
| Dashboard | `MOCK_WORKFLOWS` (L24-29) | `GET /api/orchestrator/dlq` | ✅ Existe |
| Dashboard | `MOCK_AGENTS` (L31-35) | *Nenhum* | ❌ Placeholder necessario |
| Dashboard | Logs fake c/ `Math.random()` (L44-62) | Prometheus/Loki | 🔜 Fase 4 |
| Dashboard | Metricas sinteticas (fallback `useSystemMetrics`) | `GET /health` + `GET /api/system/status` | 🔜 A4 |
| Observability | `MOCK_ALERTS` (L23-27) | *Nenhum* | ❌ Remover |
| Observability | Logs fake c/ `Math.random()` (L33-58) | Prometheus/Loki | 🔜 Fase 4 |
| Observability | Token Rate hardcoded "342 t/s" | `useSystemStore.metrics.tokenRate` | 🔜 B2 |
| Orchestration | `WORKFLOWS` mock (L15-21) | `GET /api/orchestrator/dlq` | ✅ Existe |
| Orchestration | Botoes "Trigger Manual" sem acao | `POST /api/orchestrator/execute` | ✅ Existe |
| Settings | API Key display `"sk-...****"` (L141) | `GET /auth/key` (masked) | 🔜 A2 |
| Settings | Botoes Test/Save sem `onClick` (L82-88) | `POST /api/setup/provider/test` + `POST /api/setup/provider` | ✅ Existem |
| Settings | Configure/Edit/Remove sem acao | *Nenhum* | ❌ Coming Soon |
| Pipelines | `PIPELINES` mock (L15-28) | *Verificar* | 🟡 Pendente |
| Agents | Dados mockados | *Verificar* | 🟡 Pendente |

### 1.3 Stores — Estado Atual

| Store | Estado | Problema |
|-|-|-|
| `auth-store.ts` | `apiKey: ""`, `connected: false` | Nunca tenta conectar ao backend |
| `system-store.ts` | `ollama: false`, `backend: false`, `qdrant: false` | Nunca busca dados reais |
| `chat-store.ts` | `activeModel: "kaos"` | Hardcoded, sem lista de modelos |
| `useSystemMetrics.ts` | Fallback `Math.random()` a cada 2s | WebSocket fake, sem fallback HTTP real |

---

## 2. Arquitetura da Solucao

### 2.1 Principios

1. **Remover mocks, nao reescrever** — o desktop e funcional, so precisa de dados reais
2. **Polling HTTP, nao WebSocket** — para Fase 1, polling simples evita infraestrutura temporaria
3. **URLs de providers fixas no backend** — OpenAI, Anthropic, Google sao gerenciadas pelo backend; apenas Ollama e self-hosted tem URL editavel
4. **API Key gerada pelo backend** — nunca usar senha do usuario como API Key; tres conceitos separados: (a) credenciais de login, (b) API Key do sistema, (c) Provider Keys
5. **Nenhum botao sem implementacao** — se endpoint nao existe, botao `disabled` + "Coming Soon"

### 2.2 Diagrama de Fluxo (Fase 1)

```
Desktop App (Tauri/React)
    │
    ├── auth-store ─────► GET /health ───────────► kaos-api (FastAPI)
    │                    ├── GET /auth/key              │
    │                    └── (polling 30s)              │
    │                                                   │
    ├── system-store ───► GET /health (status)          │
    │                    ├── GET /health/readiness       │
    │                    ├── GET /api/system/status      │
    │                    └── (polling 5s)                │
    │                                                   │
    ├── Dashboard ──────► GET /api/orchestrator/dlq     │
    │                    └── system-store (metricas)     │
    │                                                   │
    ├── Chat ───────────► GET /api/providers            │
    │                    └── POST /v1/chat/completions   │
    │                                                   │
    ├── Settings ───────► POST /api/setup/provider      │
    │                    ├── POST /api/setup/provider/test│
    │                    └── GET /auth/key               │
    │                                                   │
    └── Orchestration ──► GET /api/orchestrator/dlq     │
                        └── POST /api/orchestrator/execute
```

### 2.3 Modelo de Dados — Provider Config

```typescript
interface ProviderConfig {
  id: string;              // "openai" | "anthropic" | "gemini" | "ollama" | "openrouter"
  name: string;            // "OpenAI" | "Anthropic" | ...
  base_url: string;        // URL padrao gerenciada pelo backend
  editable_url: boolean;   // false para OpenAI/Anthropic/Gemini; true para Ollama/self-hosted
  configured: boolean;     // true se tem API Key salva (Ollama sempre true)
  models: string[];        // Lista de modelos disponiveis
}

interface ProvidersResponse {
  providers: ProviderConfig[];
  activeProvider: string;  // ID do provider ativo no momento
}
```

### 2.4 Modelo de Dados — System Status

```typescript
interface SystemStatus {
  backend: boolean;
  qdrant: boolean;
  ollama: boolean;
  postgres: boolean;
  n8n: boolean;
  grafana: boolean;
  prometheus: boolean;
}
```

### 2.5 Modelo de Dados — Auth State (Fase 1, temporario)

```typescript
interface AuthState {
  apiKey: string;          // "" (vazio, nunca hardcodado)
  serverUrl: string;       // fixo "http://localhost:8000", removido da UI
  connected: boolean;      // false ate GET /health responder
  maskedKey: string;       // "kaos-dev-key" — apenas para display
  setConnected: (v: boolean) => void;
  fetchConfig: () => Promise<void>;  // nova — tenta conectar ao backend
}
```

---

## 3. Plano de Execucao — 4 Sprints

### 🔴 SPRINT 1 — Destravar Backend

**Objetivo:** Fazer o `kaos-api` iniciar sem crash e validar todos os endpoints existentes.

#### Item 0.1 — Validar estrutura real do Vault

Investigar se o diretorio esperado pelo codigo e:

- `/workspace/wiki` (pastas na raiz do workspace)
- `/workspace/kaos/wiki` (subpasta kaos)
- `/workspace/kaos/raw`

**Arquivos de referencia:**
- `assistant/app/obsidian/vault_init.py` — cria pastas em `OBSIDIAN_VAULT_PATH`
- `assistant/app/config/settings.py` — `OBSIDIAN_VAULT_PATH: str = ""`
- `infra/docker/.env` — `OBSIDIAN_VAULT_PATH=/vault`
- `assistant/.env` — nao define `OBSIDIAN_VAULT_PATH`

**Criterio:** Identificar o path real antes de alterar qualquer configuracao.

#### Item 0.2 — Corrigir configuracao do vault

**Arquivos:** `infra/docker/docker-compose.yml`, `infra/docker/.env`, `assistant/.env`

- Adicionar volume mount no `docker-compose.yml` para o vault (ex: `- ../../workspace/kaos:/vault` ou `- ../../workspace:/vault`, validado no item 0.1)
- Alinhar `OBSIDIAN_VAULT_PATH` no `.env` com o path montado
- Adicionar `OBSIDIAN_VAULT_PATH` no `assistant/.env` para desenvolvimento local

#### Item 0.3 — Subir kaos-api e validar

```bash
# Docker
docker compose -f infra/docker/docker-compose.yml up -d kaos-api

# OU local (dentro de assistant/)
uvicorn app.main:app --reload
```

**✅ Criterio de Aceite:**

| Endpoint | Metodo | Status Esperado |
|-|-|-|
| `GET /health` | `200` | `{"status": "ok", "version": "0.1.0"}` |
| `GET /health/readiness` | `200` | `{"status": "ready", "services": {"ollama": true/false}}` |
| `GET /auth/key` | `200` | `{"configured": true, "masked": "kaos-...key"}` |
| `GET /v1/models` | `200` | `{"object": "list", "data": [...]}` |
| `GET /api/setup/provider` | `200` | Configuracao dos providers |
| `GET /` | `200` | `{"status": "running", ...}` |

> **Regra:** Nao avancar para Sprint 2 enquanto todos os endpoints acima nao retornarem `200`.

---

### 🟡 SPRINT 2 — Endpoints Backend

**Objetivo:** Criar/modificar endpoints que o desktop precisa mas que ainda nao existem ou precisam de ajustes.

#### Item A2 — Modificar `GET /auth/key`

**Arquivo:** `assistant/app/api/auth.py`

**Mudanca:** Remover `api_key` (chave completa) do response. Retornar apenas:

```json
{
  "configured": true,
  "masked": "kaos-dev-key"
}
```

**Motivo:** Seguranca — a chave completa nunca deve ser exposta para o frontend. O desktop ja tem a chave via env ou arquivo.

**Codigo atual:**
```python
@router.get("/key", response_model=ApiKeyResponse)
async def get_api_key(request: Request) -> ApiKeyResponse:
    key = request.app.state.api_key
    masked = key[:6] + "*" * (len(key) - 8) + key[-2:]
    return ApiKeyResponse(api_key=key, masked=masked)
```

**Codigo modificado:**
```python
@router.get("/key")
async def get_api_key(request: Request) -> dict:
    key = request.app.state.api_key
    masked = key[:6] + "*" * (len(key) - 8) + key[-2:]
    return {"configured": True, "masked": masked}
```

> **Nota:** Este endpoint e temporario. Na Fase 2 (Auth & First Run Wizard), sera substituido pelo fluxo JWT.

#### Item A3 — Criar `GET /api/providers`

**Arquivo novo:** `assistant/app/api/providers.py`

**Arquitetura:** Extensivel por tipo de fonte de modelos.

```python
from enum import Enum
from dataclasses import dataclass

class ProviderSourceType(Enum):
    API = "api"          # Consulta endpoint real (ex: Ollama /api/tags)
    CATALOG = "catalog"  # Lista estatica (ex: Anthropic, Gemini)

@dataclass
class ProviderSource:
    type: ProviderSourceType
    endpoint: str = ""        # Para type=API
    catalog: list[str] = None # Para type=CATALOG
    auth_type: str = "none"   # "header" | "query" | "none"
    api_key_field: str = ""   # Nome do header/query param

PROVIDER_SOURCES = {
    "openai":   ProviderSource(ProviderSourceType.API, "/models", auth_type="header", api_key_field="Authorization"),
    "anthropic":ProviderSource(ProviderSourceType.CATALOG, catalog=["claude-sonnet-4-20250514"], auth_type="header"),
    "gemini":   ProviderSource(ProviderSourceType.CATALOG, catalog=["gemini-2.0-flash"], auth_type="query"),
    "ollama":   ProviderSource(ProviderSourceType.API, "/api/tags", auth_type="none"),
    "openrouter":ProviderSource(ProviderSourceType.API, "/models", auth_type="header"),
}
```

**Providers com `type=api`:** consultam o endpoint real para listar modelos.
**Providers com `type=catalog`:** usam lista estatica (atualizada via versao do backend).

**Response:**
```json
{
  "providers": [
    {
      "id": "openai",
      "name": "OpenAI",
      "base_url": "https://api.openai.com/v1",
      "editable_url": false,
      "configured": true,
      "models": ["gpt-5", "gpt-5-mini"]
    },
    {
      "id": "anthropic",
      "name": "Anthropic",
      "base_url": "https://api.anthropic.com",
      "editable_url": false,
      "configured": false,
      "models": ["claude-sonnet-4-20250514"]
    },
    {
      "id": "ollama",
      "name": "Ollama",
      "base_url": "http://localhost:11434",
      "editable_url": true,
      "configured": true,
      "models": ["qwen3:14b", "qwen3:4b"]
    }
  ],
  "activeProvider": "ollama"
}
```

**Registrar em `main.py`:**
```python
from app.api.providers import router as providers_router
app.include_router(providers_router)
```

#### Item A4 — Criar `GET /api/system/status`

**Arquivo novo:** `assistant/app/api/system.py`

Endpoint que consulta a saude de cada servico interno:

```python
@router.get("/api/system/status")
async def system_status():
    return {
        "backend": True,  # Se o proprio endpoint respondeu
        "qdrant": await check_qdrant(),
        "ollama": await check_ollama(),
        "postgres": await check_postgres(),
        "n8n": await check_n8n(),
        "grafana": await check_grafana(),
        "prometheus": await check_prometheus(),
    }
```

**Implementacao dos checks:**
- `check_qdrant()`: `GET http://qdrant:6333/health` (ou `localhost:6333`)
- `check_ollama()`: `GET http://ollama:11434/api/tags`
- `check_postgres()`: `SELECT 1` via SQLAlchemy
- `check_n8n()`: `GET http://n8n:5678/healthz`
- `check_grafana()`: `GET http://grafana:3001/api/health`
- `check_prometheus()`: `GET http://prometheus:9090/-/ready`

**Registrar em `main.py`:**
```python
from app.api.system import router as system_router
app.include_router(system_router)
```

---

### 🟠 SPRINT 3 — Stores Conectadas

**Objetivo:** Fazer as stores do desktop se comunicarem com o backend antes de alterar qualquer UI.

#### Item B1 — Auth Store

**Arquivo:** `desktop/src/shared/lib/stores/auth-store.ts`

**Interface final:**
```typescript
interface AuthState {
  apiKey: string;          // "" (vazio, nunca hardcodado)
  serverUrl: string;       // "http://localhost:8000" (fixo, removido da UI)
  connected: boolean;      // false ate GET /health responder
  maskedKey: string;       // Para exibicao "kaos-...key"
  checking: boolean;       // true durante fetchConfig()
  setApiKey: (key: string) => void;
  setConnected: (v: boolean) => void;
  fetchConfig: () => Promise<void>;  // Tenta conectar ao backend
}
```

**Comportamento do `fetchConfig()`:**
1. Tenta `GET http://localhost:8000/health`
2. Se sucesso → `setConnected(true)`
3. Tenta `GET http://localhost:8000/auth/key`
4. Se sucesso → armazena `maskedKey` para exibicao
5. Se qualquer falha → `setConnected(false)`
6. `setInterval` a cada 30s repetindo o processo

**Inicializacao:** O `useEffect` no App root chama `fetchConfig()` no mount.

#### Item B2 — System Store

**Arquivo:** `desktop/src/shared/lib/stores/system-store.ts`

**Nova action `fetchAll()`:**
```typescript
fetchAll: async () => {
  const serverUrl = "http://localhost:8000";
  const apiKey = ""; // sera preenchido pelo auth flow

  // Parallel calls
  const [health, readiness, systemStatus, providerActive] = await Promise.allSettled([
    kaosFetch(`${serverUrl}/health`, apiKey),
    kaosFetch(`${serverUrl}/health/readiness`, apiKey),
    kaosFetch(`${serverUrl}/api/system/status`, apiKey),
    kaosFetch(`${serverUrl}/api/setup/provider/active`, apiKey),
  ]);

  // Atualiza estado conforme resultados
  if (health.status === "fulfilled" && health.value.ok) {
    const data = await health.value.json();
    set(data.status === "ok" ? "online" : "degraded");
  }

  // ... similar para os outros endpoints
}
```

**Polling:** Chamar `fetchAll()` a cada 5s via `setInterval` no Dashboard.

#### Item B4 — useSystemMetrics Hook

**Arquivo:** `desktop/src/features/dashboard/hooks/useSystemMetrics.ts`

**Mudancas:**
1. Remover tentativa de conexao WebSocket (`ws://localhost:8000/ws/metrics`)
2. Remover todo o fallback simulado (`Math.random()`)
3. Substituir por polling HTTP simples:

```typescript
export function useSystemMetrics() {
  // ... stores ...

  useEffect(() => {
    const poll = async () => {
      try {
        const res = await kaosFetch("http://localhost:8000/api/system/status", "");
        if (res.ok) {
          const data = await res.json();
          // Atualiza historico e stores
        }
      } catch {
        // Silently fail — stores mantem ultimos valores conhecidos
      }
    };

    poll(); // Primeira chamada imediata
    const interval = setInterval(poll, 5000);
    return () => clearInterval(interval);
  }, []);
}
```

---

### 🟢 SPRINT 4 — Remocao dos Mocks

**Objetivo:** Substituir todos os dados mockados por dados reais ou placeholders honestos.

#### Item B3 — Dashboard

**Arquivo:** `desktop/src/pages/dashboard/index.tsx`

| Elemento | Antes | Depois |
|-|-|-|
| `MOCK_WORKFLOWS` (L24-29) | Array estatico de 4 workflows | `GET /api/orchestrator/dlq` com loading state |
| `MOCK_AGENTS` (L31-35) | 3 agentes inventados | Placeholder: "Agent telemetry coming soon in Fase 4" |
| Logs fake (L44-62) | `setInterval` 4s com `Math.random()` | `<p>No telemetry available — Prometheus/Loki in Fase 4</p>` |
| Metric cards | `history.cpu[...]` do fallback sintetico | `useSystemStore.metrics` + `useSystemStore.runtime` (dados reais do polling) |

**Estado de loading:** Enquanto `GET /api/orchestrator/dlq` nao responde, mostrar skeleton loading.

**Estado de erro:** Se o backend estiver offline, mostrar cards vazios com indicacao de "Backend offline".

#### Item C4 — Observability

**Arquivo:** `desktop/src/pages/observability/index.tsx`

| Elemento | Antes | Depois |
|-|-|-|
| `MOCK_ALERTS` (L23-27) | 3 alertas inventados | Empty state: "No alerts" |
| Logs fake (L33-58) | `setInterval` 3s com `Math.random()` | Empty state: "No telemetry available — Prometheus/Loki in Fase 4" |
| Token Rate "342 t/s" (L85) | Hardcoded | `{metrics.tokenRate} t/s` de `useSystemStore` |
| Latency (L92-96) | `runtime.latency` (ja conectado) | Mantido |
| Services (L64-68) | `services.ollama/backend/qdrant` (ja conectado via B2) | Mantido |

#### Item C5 — Orchestration

**Arquivo:** `desktop/src/pages/orchestration/index.tsx`

| Elemento | Antes | Depois |
|-|-|-|
| `WORKFLOWS` mock (L15-21) | 5 workflows estaticos | `GET /api/orchestrator/dlq` |
| Botao "Trigger Manual" | Sem acao real | `POST /api/orchestrator/execute` com `{ workflowId }` |
| Botao "Refresh" | Apenas visual | `fetchAll()` do sistema |

#### Item C1 — Model Selector

**Arquivo:** `desktop/src/pages/chat/index.tsx` + `desktop/src/features/ask-ai/ui/ModelSelector.tsx`

**Fluxo:**
1. `ChatPage` monta → `GET /api/providers`
2. Estado local: `providers: ProviderConfig[]`, `selectedProvider`, `selectedModel`
3. Passa `providers` para `ModelSelector` como prop

**ModelSelector modificado:**
```tsx
interface Props {
  currentModel: string;
  defaultModel: string;
  fastModel: string;
  fastMode: boolean;
  providers: ProviderConfig[];
  selectedProvider: string;
  onProviderChange: (provider: string) => void;
  onModelChange: (model: string) => void;
  onFastModeToggle: (active: boolean) => void;
}
```

**Renderizacao:**
```
[Provider ▼]  [Model ▼]  [D] [⚡] [✏]  [Fast Mode ON/OFF]
```

- Provider dropdown: lista de `providers[].name`
- Model dropdown: `providers.find(p => p.id === selectedProvider).models`
- Botoes D / ⚡ / ✏: mantidos como atalhos
- Custom model (✏): **preservado** — importante para OpenRouter e modelos que surgem antes do catalogo

#### Item C2 — Settings: Providers

**Arquivo:** `desktop/src/pages/settings/index.tsx`

**Provider card modificado:**
```tsx
{providers.map((provider) => (
  <Card key={provider.id}>
    <CardContent>
      <h3>{provider.name}</h3>
      <Badge variant={provider.configured ? "success" : "neutral"}>
        {provider.configured ? "Connected" : "Disabled"}
      </Badge>

      {provider.editable_url && (
        <Input placeholder="API URL" defaultValue={provider.base_url} />
      )}

      <Input type="password" placeholder="API Key" />
      <Input placeholder="Model" />

      <div class="flex gap-2">
        <Button onClick={() => testProvider(provider.id)}>
          <RefreshCw /> Test
        </Button>
        <Button onClick={() => saveProvider(provider.id)}>
          Save
        </Button>
      </div>
    </CardContent>
  </Card>
))}
```

**Funcoes:**
```typescript
const testProvider = async (provider: string) => {
  const res = await kaosFetch("http://localhost:8000/api/setup/provider/test", "", {
    method: "POST",
    body: JSON.stringify({ provider, url, apiKey }),
  });
  // Atualiza badge conforme resultado
};

const saveProvider = async (provider: string) => {
  const res = await kaosFetch("http://localhost:8000/api/setup/provider", "", {
    method: "POST",
    body: JSON.stringify({ [provider]: { url, apiKey, model } }),
  });
  // Feedback visual de sucesso/erro
};
```

#### Item C3 — Settings: Botoes sem acao

Aplicar regra: **nenhum botao sem implementacao.**

| Botao | Acao |
|-|-|
| "Configure" (GitHub, N8N, Qdrant) | `disabled` + `title="Coming Soon"` |
| "Edit" (env vars) | `disabled` + `title="Coming Soon"` |
| "Remove" (env vars) | `disabled` + `title="Coming Soon"` |
| "Add Variable" | `disabled` + `title="Coming Soon"` |
| API Key display | Buscar `masked` de `GET /auth/key` |

---

## 4. Arquivos Afetados

### Backend (`assistant/`)

| Arquivo | Acao | Sprint |
|-|-|-|
| `infra/docker/docker-compose.yml` | Adicionar volume mount vault | 1 |
| `infra/docker/.env` | Alinhar `OBSIDIAN_VAULT_PATH` | 1 |
| `assistant/.env` | Adicionar vault path (dev) | 1 |
| `assistant/app/config/settings.py` | Se necessario, ajustar `WORKSPACE_ROOT` | 1 |
| `assistant/app/api/auth.py` | Remover `api_key` full do response | 2 |
| `assistant/app/api/providers.py` | **NOVO** — `GET /api/providers` | 2 |
| `assistant/app/api/system.py` | **NOVO** — `GET /api/system/status` | 2 |
| `assistant/app/main.py` | Registrar novos routers | 2 |

### Desktop (`desktop/`)

| Arquivo | Acao | Sprint |
|-|-|-|
| `src/shared/lib/stores/auth-store.ts` | `fetchConfig()`, reconnect, `maskedKey` | 3 |
| `src/shared/lib/stores/system-store.ts` | `fetchAll()` com polling | 3 |
| `src/features/dashboard/hooks/useSystemMetrics.ts` | Polling HTTP, remover WebSocket + fallback | 3 |
| `src/pages/dashboard/index.tsx` | Remover mocks, conectar stores | 4 |
| `src/pages/observability/index.tsx` | Remover mocks, empty states | 4 |
| `src/pages/orchestration/index.tsx` | Dados reais do DLQ | 4 |
| `src/pages/chat/index.tsx` | Provider dropdown | 4 |
| `src/features/ask-ai/ui/ModelSelector.tsx` | Dropdown duplo provider+model | 4 |
| `src/pages/settings/index.tsx` | Test/Save reais, Coming Soon, editable_url | 4 |
| `src/pages/agents/index.tsx` | *Verificar mocks* | 4 |
| `src/pages/pipelines/index.tsx` | *Verificar mocks* | 4 |

---

## 5. Decisoes Arquiteturais

| Decisao | Opcao Rejeitada | Opcao Escolhida | Motivo |
|-|-|-|-|
| Modelos dos providers | Hardcodar no frontend | `GET /api/providers` com `type=api\|catalog` | Extensivel sem reescrever endpoint |
| Comunicacao em tempo real | WebSocket `/ws/metrics` | Polling HTTP (`GET /api/system/status`) | Evita infraestrutura temporaria; WS na Fase 4 |
| Auth default `apiKey` | `"kaos-dev-key"` | `""` (vazio) | Funciona em qualquer ambiente; `GET /auth/key` descobre config |
| URLs de providers | Editable para todos | Fixas (backend) para OpenAI/Anthropic/Gemini; editaveis para Ollama/self-hosted | Evita usuario quebrar integracao |
| Custom model input | Remover | Manter | Essencial para OpenRouter e modelos novos |
| Senha do usuario = API Key | Acoplar | Separar tres conceitos | Login ≠ API Key ≠ Provider Keys |

---

## 6. Criterios de Aceite por Sprint

### Sprint 1 — Backend Funcional

- [ ] `docker compose up -d kaos-api` inicia sem crash
- [ ] `GET /health` → `200`
- [ ] `GET /health/readiness` → `200`
- [ ] `GET /auth/key` → `200`
- [ ] `GET /v1/models` → `200`
- [ ] `GET /api/setup/provider` → `200`
- [ ] `GET /` → `200`

### Sprint 2 — Endpoints Novos

- [ ] `GET /auth/key` retorna apenas `{configured, masked}` (sem `api_key` full)
- [ ] `GET /api/providers` retorna lista com providers configurados e modelos
- [ ] Providers com `type=api` consultam endpoints reais para listar modelos
- [ ] `GET /api/system/status` retorna status de todos os servicos
- [ ] Todos endpoints documentados no Swagger (`/docs`)

### Sprint 3 — Stores Conectadas

- [ ] Auth store tenta `GET /health` no mount
- [ ] Se backend online → `connected = true`
- [ ] Se backend offline → `connected = false`, UI reflete
- [ ] Reconexao automatica a cada 30s
- [ ] System store `fetchAll()` busca dados reais
- [ ] Polling a cada 5s
- [ ] `useSystemMetrics` sem nenhum `Math.random()` ou WebSocket fake

### Sprint 4 — Sem Mocks

- [ ] Dashboard sem `MOCK_WORKFLOWS`, `MOCK_AGENTS`, logs fake
- [ ] Observability sem `MOCK_ALERTS`, logs fake
- [ ] Orchestration com dados de `GET /api/orchestrator/dlq`
- [ ] Settings com Test/Save funcionais
- [ ] Settings sem botoes sem acao (todos ou funcionais ou `disabled`)
- [ ] Chat com dropdown de provider + modelo
- [ ] Nenhum `Math.random()` no codigo do desktop

---

## 7. Riscos e Mitigacoes

| Risco | Probabilidade | Impacto | Mitigacao |
|-|-|-|-|
| Vault path incorreto apos correcao | Media | Alto | Validar estrutura manualmente antes de alterar (Item 0.1) |
| `GET /api/system/status` timeout para servicos offline | Alta | Baixo | Timeout curto (2s) por servico; retornar `false` sem crash |
| Desktop quebra ao receber dados reais com formato diferente | Media | Medio | Tipagem compartilhada; testar com Postman antes de integrar |
| Polling 5s causa carga no backend | Baixa | Baixo | Endpoints sao leves (health checks); 5s e aceitavel |
| Provedor externo (OpenAI, Anthropic) offline durante teste | Media | Baixo | `POST /api/setup/provider/test` ja trata `RequestError` |

---

## 8. Proxima Fase (Fase 2 — Auth & First Run Wizard)

Apos a Fase 1, o proximo passo e substituir o modelo de autenticacao por API Key por um sistema completo com:

- `POST /api/auth/register` — criar usuario admin
- `POST /api/auth/login` — email + senha → JWT
- `GET /api/auth/me` — validar session
- `POST /api/auth/logout` — invalidar token
- FirstRunWizard — tela de setup inicial (nome, email, senha, criar workspace)
- LoginScreen — tela de login
- Auth guard — rotas protegidas, redirect se nao autenticado

A API Key interna (gerada automaticamente) continua existindo para integracoes (N8N, OpenCode, agents), mas e separada das credenciais de login do usuario.

```
Fase 1                    Fase 2
┌────────────────┐       ┌──────────────────┐
│ API Key Auth   │──►    │ JWT + Session    │
│ (temporario)   │       │ + First Run      │
│                │       │ + Login Screen   │
│ GET /auth/key  │       │ POST /auth/login │
└────────────────┘       └──────────────────┘
```

---

## 9. Referencias

- [[Roadmap Geral]] — Roadmap macro do K.A.O.S
- [[SDD-KIRL]] — Documentation Runtime Layer
- [[Configuração de Provedores]] — Provider configuration via Desktop
- [[Arquitetura de Orquestracao]] — Workflow orchestration
- [[sdd_desktop_build_optimization]] — Desktop build optimization
- [[FIRST_RUN]] — Guia de primeira execucao
- [[INSTALLATION]] — Guia de instalacao

---

*Esta SDD define o plano de estabilizacao do desktop K.A.O.S como fase 1 do roadmap, priorizando a remocao de mocks e conexao com o backend real antes de qualquer feature nova.*

## Resumo
- Informações pendentes de validação ou auto-geração.

## Objetivo
- Informações pendentes de validação ou auto-geração.

## Responsabilidades
- Informações pendentes de validação ou auto-geração.

## Dependencias
- Informações pendentes de validação ou auto-geração.

## Fluxos
- Informações pendentes de validação ou auto-geração.

## Integracoes
- Informações pendentes de validação ou auto-geração.

## Arquivos Relacionados
- Informações pendentes de validação ou auto-geração.

## Referencias KIRL
- Informações pendentes de validação ou auto-geração.

## Status
- Informações pendentes de validação ou auto-geração.

## Ultima Atualizacao
- Informações pendentes de validação ou auto-geração.
