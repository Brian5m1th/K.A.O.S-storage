---
id: sdd_mcp_bridge
type: sdd
phase: Fase 9
status: approved
tags:
  - kaos
  - mcp
  - tools
  - langgraph
---

# SDD — MCP to LangGraph Tool Bridge

## Objetivo

Conectar servidores MCP (Model Context Protocol) ao sistema de tools
do LangGraph Agent, permitindo que ferramentas MCP sejam invocadas
diretamente pelo agente como `StructuredTool` do LangChain.

## Problema

O K.A.O.S possui um `MCPManager` que gerencia servidores MCP como
subprocessos, mas suas ferramentas não eram expostas ao LangGraph agent.
O `TOOL_REGISTRY` continha apenas tools nativas (GitHub, Obsidian) e
MCP tools não apareciam para o classificador de intenção.

## Solução

### Camadas

```
MCPManager (subprocess STDIO)
    ↓
MCPAdapter (build_mcp_tool)
    ↓
StructuredTool (LangChain)
    ↓
TOOL_REGISTRY (agent.nodes.executor)
    ↓
IntentClassifier → FastRouter/SmartRouter
```

### MCPAdapter

`app/tools/mcp_adapter.py` contém:

- `build_mcp_tool(server_name, tool_def)` → `StructuredTool | None`
  - Converte definição MCP para LangChain tool
  - Nome padronizado: `mcp_{server}_{tool}`
  - Função invoca `MCPServer.call_tool()` com os argumentos

- `register_all_mcp_tools()` → `int`
  - Itera servidores MCP ativos
  - Registra tools no `TOOL_REGISTRY`
  - Retorna contagem de tools registradas

### API REST

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/api/mcp/tools` | Lista tools de todos os servidores |
| `GET` | `/api/mcp/servers` | Lista servidores com health |
| `POST` | `/api/mcp/servers` | Registra novo servidor em runtime |

### Fluxo de Startup

1. `main.py` lifespan chama `MCPManager.start_all()`
2. `register_all_mcp_tools()` itera servidores ativos
3. Para cada tool, `build_mcp_tool()` cria `StructuredTool`
4. Tool é registrada no `TOOL_REGISTRY` com prefixo `mcp_`
5. `IntentClassifier` reconhece tools MCP em mensagens

### Tratamento de Erros

- Servidor MCP offline: tool marcada como `disabled`
- Falha de tool: erro retornado como string JSON
- `MCPServer.call_tool()` stub atual retorna `not_implemented`
  (implementação completa do STDIO JSON-RPC é futura)

## Arquivos Relacionados

- `assistant/app/core/mcp_manager.py` — Gerenciamento de servidores
- `assistant/app/core/mcp_registry.py` — Persistência do registry
- `assistant/app/tools/mcp_adapter.py` — Adaptador MCP → LangChain
- `assistant/app/api/mcp.py` — Endpoints REST
- `assistant/app/main.py` — Startup bridge

## Status

**Aprovado** — implementado em 2026-06-24.
