Source: LLM Wiki Pattern + K.A.O.S SDD-009
Tags: #sdd #wiki #knowledge #llm-wiki #rag #synthesis
Related: [[index]] [[00_visao_geral]] [[sdd_llm_provider_hybrid]] [[02_fluxo_dados]]

# SDD — Knowledge Wiki Layer (LLM Wiki + RAG Híbrido)

## Objetivo

Transformar o K.A.O.S de um sistema RAG passivo para um **Sistema Operacional de Conhecimento** onde o LLM incrementalmente constrói e mantém uma wiki persistente, estruturada e interligada.

---

## Arquitetura Alvo

```
RAW SOURCES → INGESTION AGENT (LangGraph) → KNOWLEDGE WIKI → QUERY PIPELINE (wiki-first, Qdrant-second)
```

### Estrutura do Vault

```
{vault}/wiki/
├── AGENTS.md, index.md, log.md
├── entities/    (pessoas, projetos, tecnologias)
├── concepts/    (RAG, embeddings, LangGraph)
├── sources/     (resumo de fontes ingeridas)
└── synthesis/   (análises e comparações)
```

### Frontmatter Obrigatório

```yaml
---
title: Nome
type: entity|concept|source|synthesis
tags: [tag1, tag2]
sources: [source_file]
created: 2026-06-18
updated: 2026-06-18
---
```

### Draft Mode

Toda alteração proposta primeiro como `.draft.md`, aguarda aprovação do usuário antes de virar `.md`.

### Ferramentas Wiki

- Escrita: `create_entity`, `update_entity`, `create_concept`, `create_source_page`, `create_synthesis`, `append_log`, `update_index`
- Draft: `create_entity_draft`, `approve_draft`, `reject_draft`, `list_drafts`
- Manutenção: `lint_wiki`, `read_wiki_page`, `search_wiki`

### Query Evolution

```
Pergunta → index.md → Entities → Concepts → Synthesis → Qdrant (fallback) → LLM
```

### Relação com Outros Componentes

| Componente | Relação |
|------------|---------|
| RAG Pipeline | Qdrant vira camada de fallback semântico |
| LangGraph | Novo nó `ingest_source` + entry point condicional |
| Triple Router | Novo intent type INGEST |
| LLM Provider | Wiki layer é independente do provider |
