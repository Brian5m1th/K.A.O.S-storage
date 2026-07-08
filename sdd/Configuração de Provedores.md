---
type: knowledge
domain: ia
status: active
created_by: OpenCode
---

# Configuração de Provedores
*Provider Configuration via Desktop App*

> Sistema de configuração dinâmica de provedores LLM via API, permitindo ao usuário configurar chaves de API, URLs e modelos de cada provedor diretamente pela interface desktop, sem edição manual de arquivos .env.

## Parent
- [[Provedor Hibrido de LLM]]

## Children

## Related
- [[Variaveis de Ambiente]]
- [[Arquitetura de Orquestracao]]
- [[Ferramentas do LangGraph]]

## Tags
#kaos #ia #llm #provedores #setup #configuration

---

## Conteudo

## 1. Problema

Atualmente, a configuração de provedores LLM depende de variáveis de ambiente definidas em `.env`:

```env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
OLLAMA_BASE_URL=http://localhost:11434
```

Isso exige que o usuário:
1. Edite manualmente o arquivo `.env`
2. Reinicie o servidor FastAPI
3. Conheça a estrutura de configuração do projeto

Para uma aplicação desktop que visa ser acessível, esse fluxo inviabiliza a adoção por usuários não-técnicos.

## 2. Solução

Criar um sistema de configuração dividido em tres camadas:

```
Desktop App (React + Tauri)
        │
        ├── Tauri plugin-store (cache local offline)
        │
        └── POST /api/setup/provider → Backend FastAPI
                │
                └── ProviderConfigService
                        ├── Salva em data/provider_config.json
                        ├── Patcheia settings em memoria
                        └── Invalida caches do LLMFactory
```

### 2.1 Camada de Persistencia

| Local | Tecnologia | Finalidade |
|-------|-----------|------------|
| Desktop | `@tauri-apps/plugin-store` | Cache local offline (carregamento instantaneo) |
| Desktop → Backend | `POST /api/setup/provider` | Envio ao servidor |
| Backend | `data/provider_config.json` | Persistencia no servidor (sobrevive a restart) |
| Backend | `settings` em memoria | Disponivel imediatamente para LLMFactory |

### 2.2 Payload do Endpoint

`POST /api/setup/provider` aceita um unico JSON com a configuracao de todos os provedores:

```json
{
  "ollama": {
    "url": "http://localhost:11434",
    "model": "qwen3:14b"
  },
  "openai": {
    "apiKey": "sk-proj-...",
    "url": "https://api.openai.com/v1",
    "model": "gpt-4o"
  },
  "anthropic": {
    "apiKey": "sk-ant-...",
    "url": "https://api.anthropic.com",
    "model": "claude-sonnet-4-20250514"
  },
  "gemini": {
    "apiKey": "AIza...",
    "url": "https://generativelanguage.googleapis.com",
    "model": "gemini-2.0-flash"
  }
}
```

### 2.3 Fluxo de Configuracao

```
1. Desktop App inicia
   │
2. ProviderScreen monta
   │
   ├── Carrega do plugin-store (instantaneo)
   │     └── Se vazio → GET /api/setup/provider
   │           └── Se vazio → defaults (Ollama local)
   │
3. Usuario preenche os campos de cada provedor
   │
4. Clica "Continue"
   │
   ├── Salva no plugin-store (offline first)
   └── POST /api/setup/provider (envia ao servidor)
         │
         ├── ProviderConfigService.salva JSON
         ├── Patch em settings.* (em memoria)
         └── Invalida _factory caches
```

## 3. Arquitetura do Backend

### ProviderConfigService

```
assistant/app/setup/
  __init__.py
  provider_config.py
```

Servico singleton responsavel por:

1. **load()**: Le `data/provider_config.json` e retorna config atual
2. **save(config)**: Salva JSON + patcheia `settings` + invalida caches
3. **get()**: Retorna config atual (fundido com defaults do settings)

Patch de settings apos save:

| Variavel | Origem no payload |
|----------|------------------|
| `settings.OLLAMA_BASE_URL` | `ollama.url` |
| `settings.OPENAI_API_KEY` | `openai.apiKey` |
| `settings.ANTHROPIC_API_KEY` | `anthropic.apiKey` |
| `settings.GEMINI_API_KEY` | `gemini.apiKey` |
| (modelos) | `{provider}.model` |

Invalidacao de caches apos save (seta `None` para forçar rebuild):

| Modulo | Variavel |
|--------|---------|
| `app.api.openai` | `_factory` |
| `app.agent.nodes.planner` | `_factory` |
| `app.router.intent_classifier` | `_classifier._factory` |

### Endpoints da API

| Metodo | Rota | Descricao |
|--------|------|-----------|
| `GET` | `/api/setup/provider` | Retorna config atual de todos os provedores |
| `POST` | `/api/setup/provider` | Salva config de todos os provedores |
| `POST` | `/api/setup/provider/test` | Testa conexao com um provedor especifico |

**POST /api/setup/provider/test** recebe:

```json
{
  "provider": "openai",
  "url": "https://api.openai.com/v1",
  "apiKey": "sk-..."
}
```

E retorna `200 OK` ou erro com mensagem.

## 4. Arquitetura do Frontend

### ProviderScreen (React)

Interface dividida em 4 secoes (cards), uma por provedor:

```
┌─────────────────────────────────┐
│  Ollama (Local)                 │  ← expandido por padrao
│  URL: [http://localhost:11434  ]│
│  Model: [qwen3:14b             ]│
│  [Test Connection] ✓            │
├─────────────────────────────────┤
│  OpenAI                         │  ← colapsado
│  API Key: [•••••••••••••••    ]│
│  Model: [gpt-4o                ]│
│  [Test Connection]              │
├─────────────────────────────────┤
│  Anthropic Claude               │  ← colapsado
│  API Key: [•••••••••••••••    ]│
│  Model: [claude-sonnet-4       ]│
│  [Test Connection]              │
├─────────────────────────────────┤
│  Google Gemini                  │  ← colapsado
│  API Key: [•••••••••••••••    ]│
│  Model: [gemini-2.0-flash      ]│
│  [Test Connection]              │
├─────────────────────────────────┤
│  [← Back]          [Continue →] │
└─────────────────────────────────┘
```

### Integracao com Tauri plugin-store

```typescript
import { Store } from '@tauri-apps/plugin-store';

// Ao montar:
const store = await Store.load('settings.json');
const saved = await store.get<ProviderConfig>('providerConfig');
if (saved) setConfig(saved);

// Ao salvar:
await store.set('providerConfig', config);
await store.save();
```

### Separacao de conceitos

Corrige bug existente onde `serverUrl` (backend FastAPI) era usado como URL do provider. Agora:

| Variavel | Valor | Uso |
|----------|-------|-----|
| `serverUrl` | `http://localhost:8000` | Backend FastAPI (fixo) |
| `config.ollama.url` | `http://localhost:11434` | URL do Ollama |
| `config.openai.url` | `https://api.openai.com/v1` | URL do OpenAI |

## 5. Integracao com o Ecossistema

### LLMFactory

O `LLMFactory._create_provider()` atualmente le settings diretamente:

```python
# factory.py:84
api_key=settings.OPENAI_API_KEY
# factory.py:90
api_key=settings.ANTHROPIC_API_KEY
```

Apos o patch do `ProviderConfigService`, os valores de `settings.*` refletem a config vinda do endpoint. Nenhuma mudanca no factory e necessaria.

### Fallback Chain

A `FALLBACK_CHAIN` continua sendo lida de `settings.FALLBACK_CHAIN` (env var). O setup UI permite configurar todos os provedores, e o fallback usa os que estiverem com chave valida.

### Offline Mode

A camada desktop (plugin-store) garante que:
- Config carrega instantaneamente mesmo sem backend
- Se backend estiver offline, config local ainda funciona
- Na proxima vez que backend estiver online, config e sincronizada

## 6. Seguranca

- API keys trafegam via HTTPS em producao
- No desktop, plugin-store salva em `$APPDATA_DIR` (protegido por SO)
- Backend salva keys em `data/provider_config.json` (fora do webroot)
- Keys nunca sao expostas em logs (filtro no `ProviderConfigService`)
- Campo de API key no frontend usa `type="password"` com toggle show/hide

## 7. Dependencias

### Backend (Python)
- Nenhuma nova dependencia (usa json nativo + settings do pydantic-settings)

### Frontend (Desktop)
- `@tauri-apps/plugin-store` ^2.0.0
- `tauri-plugin-store = "2"` (Rust, Cargo.toml)
- Permissao `"store:default"` nas capabilities

## 8. Proximos Passos

- [ ] Implementar ProviderConfigService (provider_config.py)
- [ ] Implementar endpoints GET/POST /api/setup/provider
- [ ] Implementar endpoint de test de conexao
- [ ] Registrar router no main.py
- [ ] Instalar @tauri-apps/plugin-store
- [ ] Registrar plugin no lib.rs
- [ ] Criar capabilities/default.json
- [ ] Reescrever ProviderScreen (multi-provider + api keys)
- [ ] Atualizar App.tsx (callback simplificado)
- [ ] Testar fluxo completo offline-first

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
