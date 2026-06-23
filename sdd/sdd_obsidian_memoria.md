---
id: sdd_obsidian_memoria
type: sdd
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

Source: Notas no ClickUp
Tags: #sdd #obsidian #memoria #rag #langgraph
Related: [[index]] [[sdd_obsidian_watcher]] [[sdd_obsidian_rag]] [[sdd_obsidian_tools]]

# SDD — Sistema de Memória Inteligente com Obsidian

## Caso de Uso (User Story)

> "Como usuário do Assistente de IA Pessoal, eu quero que a IA consiga criar, atualizar, pesquisar e organizar notas dentro do meu Vault Obsidian, para que todo conhecimento gerado durante conversas, estudos, projetos e documentações seja armazenado e reutilizado futuramente como memória de longo prazo."

---

## Arquitetura do Sistema

Camada de controle (FastAPI) + camada agentiva (LangGraph) + barramento de monitoramento (File Watcher) + armazenamento/busca semântica (Qdrant + RAG).

```
User → Open WebUI → FastAPI → LangGraph (Agent Orchestrator)
                                        → Ferramentas: Create, Read, Update, Delete, Search
                                        → Vault Obsidian (filesystem)
                                        → File Watcher (Watchdog) → Indexer → Qdrant
```

---

## Estrutura de Pastas no Vault

- `Projetos/`, `Arquitetura/`, `SDD/`, `Estudos/`, `IA/`, `Java/`, `Python/`, `AWS/`, `CI-CD/`, `Diário/`

---

## Requisitos Funcionais

| ID | Descrição |
| :--- | :--- |
| RF-001 | IA deve criar notas Markdown no Vault |
| RF-002 | IA deve atualizar notas existentes |
| RF-003 | IA deve excluir notas |
| RF-004 | IA deve consultar notas textualmente |
| RF-005 | IA deve executar busca semântica |
| RF-006 | Indexação automática de novos arquivos |
| RF-007 | Reindexação em modificações/exclusões |
| RF-008 | Uso de notas como contexto para prompts |
| RF-009 | Sugerir categoria ao salvar nota |
| RF-010 | Resumir conversas antes de salvar no Diário |

---

## Requisitos Não Funcionais

- RNF-001: Python 3.13
- RNF-002: Suportar 100k+ documentos
- RNF-003: Indexação < 5s por documento
- RNF-004: Persistência local (Qdrant + Postgres)
- RNF-005: Docker Compose compatível
- RNF-006: Múltiplos modelos de embedding

---

## Componentes Detalhados

1. [[sdd_obsidian_watcher]] — File Watcher & Indexer Service
2. [[sdd_obsidian_rag]] — Vector Search & RAG Service
3. [[sdd_obsidian_tools]] — Schemas das Ferramentas (Tools)

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
