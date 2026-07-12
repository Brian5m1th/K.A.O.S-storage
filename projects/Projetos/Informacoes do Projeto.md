---
id: informacoes-do-projeto
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

﻿---
type: knowledge
domain: projetos
status: active
---

# InformaçÃes do Projeto
*Project Information*

> Metadados administrativos basicos, escopo resumido e referencias primarias sobre a gerencia do projeto.

## Parent
- [[index]]

## Children
- [[Objetivos do Projeto]]

## Related
- [[Backlog do Projeto]]
- [[Objetivos do Projeto]]

## Tags
#kaos #projetos #info #scope

---

## Conteudo
# Projeto — K.A.O.S

> Knowledge AI Operating System — Assistente pessoal offline com IA local.

---

## Qualidade (Quality Attributes)

| Atributo | Prioridade | Estratégia |
|:---------|:-----------|:-----------|
| Privacidade | 🔴 Crítica | 100% offline, modelos locais, sem telemetria |
| Baixa Latência | 🟡 Alta | Streaming, cache de embeddings, lazy loading |
| Modularidade | 🟡 Alta | Camadas isoladas (RAG, Agente, Obsidian, API) |
| Simplicidade | 🟢 Média | Mínimo de abstrações, código direto |
| Testabilidade | 🟢 Média | Testes unitários, fixtures locais sem rede |

---

## Active Initiatives

| Iniciativa | Status | Relacionado |
|:-----------|:-------|:------------|
| P12 Logging Pattern | ✅ Feito | `docs/patterns.md` |
| ListNotesTool | ⬜ Pendente | Fase 3 |
| LangGraph + OpenAI Proxy | 🟡 Em andamento | Fase 7 |
| Streaming real | ⬜ Pendente | Fase 7 |
| Vault folder structure | ⬜ Pendente | Fase 4 |
| RAG testing | ⬜ Pendente | Fase 5 |
| Long-term memory | ⬜ Pendente | Fase 8 |

---

## Branching Strategy

```
main              → estável, releases
├── feature/*     → novas funcionalidades (um branch por passo do backlog)
├── fix/*         → correções de bugs
└── refactor/*    → refatorações sem mudança funcional
```

**Convenções:**
- `feature/logging-marker-standard` — implementar padrão de logs
- `feature/list-notes-tool` — implementar ListNotesTool
- `fix/openai-proxy-streaming` — corrigir streaming
- `refactor/agent-service` — refatorar AgentService

---

## Stack

| Camada | Tecnologia |
|:-------|:-----------|
| Runtime | Python 3.13 |
| Framework | FastAPI |
| LLM | Ollama (Qwen3 4B) |
| Vector DB | Qdrant |
| Agente | LangGraph + LangChain |
| Embeddings | sentence-transformers (BGE-M3) |
| Logs | loguru |
| Watcher | watchdog |

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
