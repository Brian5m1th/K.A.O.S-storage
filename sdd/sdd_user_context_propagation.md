Source: K.A.O.S Project
Tags: #sdd #user-context #multiusuario #memoria
Related: [[index]] [[02_fluxo_dados]] [[sdd_obsidian_memoria]] [[sdd_arquitetura_orquestracao]] [[backlog]]

# SDD — User Context Propagation & Multiusuário

> Status: **Implementado** ✅

---

## Objetivo

Permitir que o K.A.O.S identifique qual usuário do Open WebUI iniciou uma conversa, possibilitando memória isolada por usuário, histórico individual e preferências separadas.

---

## Fluxo Atual

```
Open WebUI (headers: x-user-id, x-username, x-user-role)
  → FastAPI /v1/chat/completions (UserContext in request)
  → Intent Classifier → Router (FAST/MEMORY/SMART)
  → AgentService / MemoryRouter / FastRouter (user_id propagated)
  → MemoryService (Vault/users/{user_id}/)
```

---

## Modelo de Contexto

```python
class UserContext(BaseModel):
    user_id: str
    username: str
    role: str
```

---

## Alterações no AgentState

```python
class AgentState(TypedDict):
    messages: list
    retrieved_context: list
    tool_to_call: str | None
    tool_args: dict
    tool_result: dict | None
    session_id: str
    user_id: str
    username: str
    role: str
```

---

## Estrutura de Memória

```
Vault/users/{user_id}/
├── preferencias.md
├── projetos.md
└── memoria.md
```

---

## Compatibilidade com PostgreSQL

A implementação segue o padrão Repository:

```python
class MemoryRepository(Protocol): ...
class ObsidianMemoryRepository: ...    # Atual
class PostgresMemoryRepository: ...    # Futuro
```

---

## Critérios de Aceite ✅

- [x] Usuário autenticado no Open WebUI é identificado pelo FastAPI
- [x] AgentState contém user_id, username, role
- [x] MemoryService utiliza user_id (escopo `Vault/users/{user_id}/`)
- [x] Preferências isoladas por usuário
- [x] Conversas salvas separadamente por usuário
- [x] Compatível com futura migração para PostgreSQL
- [x] Logs registram usuário responsável pela ação
