---
id: sdd_open_code_identidade
type: sdd
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# SDD — Identidade K.A.O.S & Estratégia Monorepo

**Atenção (Open Code Context)**: Este documento serve como declaração oficial da identidade do projeto e da estratégia estrutural do repositório.

---

## 1. Identidade do Projeto

- **Nome Oficial**: K.A.O.S
- **Identidade do Agente**: Sempre que houver um System Prompt, o agente deve assumir a identidade do **K.A.O.S**
- **Nomenclatura**:
  - `kaos-platform` (Monorepo)
  - `kaos-assistant` (Python/FastAPI/LangGraph)
  - `kaos-backend` (Java/Spring Boot)
  - `kaos-infra` (Docker Compose, N8N)

---

## 2. Estratégia de Repositório (Monorepo)

```text
kaos-platform/
├── assistant/     # Python, FastAPI, LangGraph, RAG
├── backend/       # Java, Spring Boot
├── infra/         # Docker Compose, configurações N8N
└── docs/          # SDDs e documentação
```

**Diretrizes:**
1. Componentes isolados (não compartilham código na raiz)
2. Scripts globais e docker-compose na raiz ou `infra/`
3. Infra portável (WSL2 + Docker), sem dependências Windows nativas

---

## 3. Diretrizes Arquiteturais

1. **Memória Principal**: Obsidian Vault + RAG (Qdrant)
2. **Inteligência**: LangGraph + Ollama
3. **Execução Externa**: N8N via webhooks
4. **Regras de Negócio**: Spring Boot (PostgreSQL)

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
