---
id: providers
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Providers — K.A.O.S

## Visão Geral

O K.A.O.S suporta múltiplos provedores de LLM, configuráveis via interface do usuário (desktop) e persistidos tanto no backend (`data/provider_config.json`) quanto localmente (`tauri-plugin-store` no desktop).

### Provedores Suportados

| Provedor | Tipo | Requer API Key | Modelo Padrão |
|----------|------|----------------|---------------|
| **Ollama** | Offline (local) | Não | `llama3.1:8b` |
| **OpenAI** | Cloud | Sim | `gpt-4o` |
| **Anthropic** | Cloud | Sim | `claude-3-5-sonnet-20241022` |
| **Google** | Cloud | Sim | `gemini-1.5-pro` |

## Arquitetura

### Backend — `ProviderConfigService`

```
assistant/app/services/provider_config.py
```

Gerencia:
- Leitura/escrita do arquivo `data/provider_config.json`
- Validação de configurações (modelos, APIs keys ofuscadas)
- Fallback para defaults se arquivo não existir

### Endpoints REST

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/setup/provider` | Retorna configuração atual (API keys ofuscadas: `sk-****...****`) |
| `PUT` | `/api/setup/provider` | Atualiza configuração completa |
| `PUT` | `/api/setup/provider/{provider}` | Atualiza apenas um provedor específico |

### Desktop — `ProviderScreen`

```
src/components/setup/ProviderScreen.tsx
```

- UI com abas para cada provedor
- Inputs para API Keys (mascaradas se já cadastradas)
- Seletor de modelo (dropdown com modelos conhecidos + input custom)
- Botão "Test Connection" que chama endpoint de validação
- Botão "Salvar" que persiste via API e localmente via tauri-plugin-store

### Persistência Dual

Para garantir resiliência e experiência offline:

1. **Desktop (Tauri plugin-store):** `~/.dev-k-a-o-s/settings.json` (desenvolvimento) ou diretório do app (produção)
2. **Backend:** `data/provider_config.json` no servidor FastAPI

O fluxo é:
- Ao salvar no desktop, envia `PUT /api/setup/provider` e persiste local
- Ao carregar, tenta buscar do backend primeiro; se offline, usa store local

## Configuração

### Exemplo de `data/provider_config.json`

```json
{
  "ollama": {
    "enabled": true,
    "base_url": "http://localhost:11434",
    "model": "llama3.1:8b",
    "keep_alive": "5m"
  },
  "openai": {
    "enabled": true,
    "api_key": "sk-xxxxxxxxxxxxxxxx",
    "model": "gpt-4o",
    "temperature": 0.7,
    "max_tokens": 4096
  },
  "anthropic": {
    "enabled": false,
    "api_key": "sk-ant-xxxxxxxxxxxx",
    "model": "claude-3-5-sonnet-20241022",
    "temperature": 0.7,
    "max_tokens": 4096
  },
  "google": {
    "enabled": false,
    "api_key": "AIzaXXXXXXXXXXX",
    "model": "gemini-1.5-pro",
    "temperature": 0.7,
    "max_tokens": 4096
  },
  "default_provider": "ollama"
}
```

### Variáveis de Ambiente (Override)

Para ambientes de produção, as API keys podem ser injetadas via env:

| Variável | Provedor | Exemplo |
|----------|----------|---------|
| `OPENAI_API_KEY` | OpenAI | `sk-...` |
| `ANTHROPIC_API_KEY` | Anthropic | `sk-ant-...` |
| `GOOGLE_API_KEY` | Google | `AIza...` |
| `OLLAMA_BASE_URL` | Ollama | `http://ollama:11434` |

Quando a env está presente, o valor no JSON é ignorado.

## Roteamento de Requisições

No backend, a escolha do provedor para cada requisição de chat segue:

1. `provider` explícito no payload da requisição
2. `default_provider` da config
3. Ollama (hardcoded fallback)

O roteamento está em `assistant/app/services/llm_service.py`.

## Segurança

- API Keys são armazenadas em texto plano no `data/provider_config.json`
- No retorno da API (`GET /api/setup/provider`), as keys são ofuscadas: `sk-****...****`
- Em produção, use variáveis de ambiente em vez do arquivo JSON
- O arquivo `data/provider_config.json` está em `.gitignore`

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
