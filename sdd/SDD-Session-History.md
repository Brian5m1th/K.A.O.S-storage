---
id: sdd_session_history
type: sdd
phase: Fase 9
status: approved
tags:
  - kaos
  - session
  - history
  - conversations
---

# SDD — Session History & Conversation Persistence

## Objetivo

Persistir o histórico de conversas do usuário entre sessões, permitindo
retomada de contexto, busca semântica em conversas passadas, e sumarização
automática com salvamento no Obsidian.

## Problema

Usuários perdem contexto entre sessões. Cada nova conversa começa do zero,
sem acesso ao histórico de interações anteriores. Não há memória de longo prazo.

## Solução

### Modelo de Dados

Tabela `conversations` no PostgreSQL:

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id` | UUID (PK) | Identificador único do turno |
| `session_id` | UUID (idx) | Grupo de turnos de uma mesma conversa |
| `user_id` | VARCHAR(255) (idx) | Dono da mensagem |
| `role` | VARCHAR(10) | "user" \| "assistant" \| "system" |
| `content` | TEXT | Conteúdo da mensagem |
| `workflow_type` | VARCHAR(20) | "FAST" \| "MEMORY" \| "SMART" \| "AGENT" |
| `tokens_used` | INTEGER | Total de tokens estimados |
| `model_used` | VARCHAR(100) | Modelo que gerou a resposta |
| `provider` | VARCHAR(50) | Provider usado |
| `created_at` | TIMESTAMPTZ (idx) | Data de criação |

### Contratos de API

#### `GET /api/conversations?user_id=X&page=1&limit=20`

Lista sessões agrupadas, com metadados (contagem, timestamps, tokens).

#### `GET /api/conversations/{session_id}?user_id=X`

Retorna todos os turnos de uma sessão em ordem cronológica.

#### `POST /api/conversations/{session_id}/summarize`

Gera resumo via `ConversationSummarizer` e salva como nota no Obsidian
em `Diário/conversas/{date}-{session_id[:8]}.md`.

#### `DELETE /api/conversations/{session_id}?user_id=X`

Remove todos os turnos de uma sessão.

### Fluxo de Persistência

1. Usuário envia mensagem → `POST /api/chat/message`
2. Router classifica e processa (FAST/MEMORY/SMART)
3. Após gerar resposta, `_persist_conversation()` é chamado (fire-and-forget)
4. Salva turno user + turno assistant em `conversations`
5. Falha de persistência não bloqueia a resposta

### Segurança

- Todo acesso é escopado por `user_id`
- `user_id` é validado contra o token JWT
- Admins podem ver conversas de qualquer usuário

## Arquivos Relacionados

- `assistant/app/models/conversation.py` — SQLAlchemy model
- `assistant/app/repositories/conversation_repository.py` — CRUD
- `assistant/app/api/conversations.py` — Endpoints
- `assistant/app/api/chat.py` — Intercept de persistência

## Status

**Aprovado** — implementado em 2026-06-24.
