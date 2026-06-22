Source: Antigravity AI
Tags: #sdd #python #fastapi #proxy #openai #gateway
Related: [[index]] [[00_visao_geral]] [[02_fluxo_dados]] [[sdd_fase2_ia_local]]

# SDD — Proxy OpenAI & Gateway de Orquestração

## Objetivo

Documentar a arquitetura do proxy OpenAI-compatível que roteia requisições do Open WebUI através do FastAPI, injetando o system prompt do K.A.O.S. e garantindo que todo o tráfego passe pelo gateway antes de chegar ao Ollama.

---

## Visão Geral

```
Open WebUI → FastAPI (Triple-Router) → FAST / MEMORY / SMART → Ollama / Tools
```

---

## Endpoints do Gateway

| Endpoint | Método | Router | Streaming |
| :------- | :----- | :----- | :-------: |
| `GET /health` | GET | health | ❌ |
| `POST /api/chat/message` | POST | chat | ✅ |
| `POST /v1/chat/completions` | POST | openai | ✅ |
| `POST /chat/completions` | POST | legacy | ✅ |
| `GET /v1/models` | GET | openai | ❌ |
| `GET /models` | GET | legacy | ❌ |
| `POST /indexing/full` | POST | indexing | ❌ |
| `POST /rag/context` | POST | rag | ❌ |

### Modelos Disponíveis

| Model ID | Rota | Uso |
| :------- | :--- | :-- |
| `kaos` | DEFAULT | SMART (LangGraph completo) |
| `kaos-fast` | FAST | Ferramentas diretas, sem LLM/RAG |
| `kaos-rag` | MEMORY | RAG + Ollama, sem LangGraph |

---

## Fluxo do Proxy OpenAI (Triple-Router)

1. Open WebUI → `POST /v1/chat/completions`
2. FastAPI verifica/insere System Prompt do K.A.O.S.
3. Intent Classifier classifica (keyword match → FAST/MEMORY, LLM fallback → SMART)
4. FAST → executa tool diretamente
5. MEMORY → RAG + Ollama streaming
6. SMART → LangGraph (retrieve → planner → executor)

---

## Configuração do Open WebUI

```yaml
environment:
  - OPENAI_API_BASE_URL=http://host.docker.internal:8000
  - OPENAI_API_KEY=kaos-local
  - DEFAULT_MODEL=qwen3:4b
```

---

## Contexto de Usuário

A partir da Fase 8, o gateway propaga `UserContext` (user_id, username, role) do Open WebUI para o AgentService. Consulte [[sdd_user_context_propagation]].
