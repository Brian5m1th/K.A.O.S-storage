---
id: sdd_obsidian_tools
type: sdd
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

Source: Notas no ClickUp
Tags: #sdd #langgraph #tools #json-schema #fastapi
Related: [[sdd_obsidian_memoria]] [[sdd_obsidian_rag]] [[sdd_obsidian_watcher]] [[Fluxo de Dados]]

# SDD Componente — Schemas das Ferramentas (Tools)

Esta nota descreve as especificações técnicas das ferramentas (Tools) expostas pelo FastAPI para o motor de agentes do LangGraph. Elas são a ponte que permite à IA manipular arquivos markdown e realizar buscas semânticas.

---

## Catálogo de Ferramentas

### 1. CreateNoteTool

Entrada:
```json
{"title": "Config Docker Compose", "folder": "CI-CD", "content": "# Docker Compose\nDetalhes..."}
```
Retorno:
```json
{"status": "CREATED", "path": "CI-CD/Config Docker Compose.md"}
```

### 2. ReadNoteTool

Entrada:
```json
{"path": "CI-CD/Config Docker Compose.md"}
```
Retorno:
```json
{"path": "CI-CD/Config Docker Compose.md", "content": "# Docker Compose\n...", "last_modified": "2026-06-10T13:14:00Z"}
```

### 3. UpdateNoteTool

Entrada:
```json
{"path": "CI-CD/Config Docker Compose.md", "content": "# Novo conteúdo", "mode": "overwrite"}
```
Retorno:
```json
{"status": "UPDATED", "path": "CI-CD/Config Docker Compose.md"}
```

### 4. DeleteNoteTool

Entrada:
```json
{"path": "CI-CD/Config Docker Compose.md"}
```
Retorno:
```json
{"status": "DELETED", "path": "CI-CD/Config Docker Compose.md"}
```

### 5. SearchNotesTool

Entrada:
```json
{"query": "Como configurar Qdrant", "folder_filter": "CI-CD", "limit": 3}
```
Retorno:
```json
{"query": "Como configurar Qdrant", "documents": [{"path": "...", "score": 0.892, "content": "..."}]}
```

---

## Tratamento de Erros

```json
{"status": "ERROR", "error_type": "FileNotFound", "message": "Nota não encontrada.", "recovery_suggestion": "Verifique o caminho usando SearchNotesTool."}
```

## Relação com outras Notas

- [[sdd_obsidian_watcher]] — Como as tools interagem com o filesystem
- [[sdd_obsidian_rag]] — Lógica de busca semântica

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
