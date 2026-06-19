Source: Antigravity AI
Tags: #sdd #python #langgraph #agente #memoria #fase6 #fase7
Related: [[index]] [[backlog]] [[sdd_fase4_rag_pipeline]] [[sdd_fase3_obsidian_service]] [[02_fluxo_dados]] [[sdd_obsidian_tools]]

# SDD — Fases 6 e 7: LangGraph Agent + Memória de Longo Prazo

## Objetivo

Implementar o orquestrador central de inteligência da plataforma usando LangGraph. O agente receberá os inputs do usuário, recuperará contexto do Vault via RAG, decidirá quais ferramentas executar e gerará respostas coerentes. Na Fase 7, o sistema ganha comandos semânticos para persistir e recuperar memória de longo prazo.

---

## Status: ✅ CONCLUÍDO

| Componente | Status |
|------------|--------|
| AgentState | ✅ user_id, username, role propagados |
| Grafo LangGraph | ✅ retrieve → planner → executor (loop) |
| Tool Registry | ✅ 7 tools Obsidian + save_conversation |
| MemoryService | ✅ Vault/users/{user_id}/ |
| Fast Intent Classifier | ✅ Keywords PT-BR/EN, LLM fallback |
| MemoryRouter | ✅ RAG + Ollama streaming (sem LangGraph) |
| Triple-Router | ✅ FAST / MEMORY / SMART routing |

---

## 1. Estrutura de Módulos

```text
app/
├── agent/
│   ├── __init__.py
│   ├── state.py            # TypedDict do estado do grafo
│   ├── graph.py            # Builder do grafo LangGraph
│   └── nodes/
│       ├── retrieve.py     # Nó: busca RAG no Qdrant
│       ├── planner.py      # Nó: LLM decide próxima ação
│       └── executor.py     # Nó: executa ferramenta escolhida
└── service/
    └── agent_service.py    # Serviço que instancia e invoca o grafo
```

---

## 2. Estado do Agente (`agent/state.py`)

```python
from typing import TypedDict, Annotated
from langchain_core.messages import BaseMessage
import operator

class AgentState(TypedDict):
    messages: Annotated[list[BaseMessage], operator.add]
    retrieved_context: list[dict]
    tool_to_call: str | None
    tool_args: dict
    tool_result: dict | None
    session_id: str
```

---

## 3. Nó de Recuperação RAG (`agent/nodes/retrieve.py`)

```python
from langchain_core.messages import HumanMessage
from app.rag.retriever.semantic_retriever import SemanticRetriever

_retriever = SemanticRetriever()

def retrieve_context(state: AgentState) -> dict:
    last_message = next((m for m in reversed(state["messages"]) if isinstance(m, HumanMessage)), None)
    if not last_message:
        return {"retrieved_context": []}
    results = _retriever.search(query=last_message.content, limit=5)
    context = [{"path": r.path, "content": r.excerpt, "score": r.score} for r in results]
    return {"retrieved_context": context}
```

---

## 4. Nó Planner (`agent/nodes/planner.py`)

```python
from langchain_ollama import ChatOllama
from langchain_core.messages import SystemMessage
from app.config.settings import settings

_llm = ChatOllama(model=settings.OLLAMA_MODEL, base_url=settings.OLLAMA_BASE_URL)

def planner(state: AgentState) -> dict:
    context_text = "\n\n".join(f"[{c['path']}]\n{c['content']}" for c in state.get("retrieved_context", []))
    messages = [SystemMessage(content=SYSTEM_PROMPT + (f"\n\nContexto:\n{context_text}" if context_text else ""))] + state["messages"]
    response = _llm.invoke(messages)
    if hasattr(response, "tool_calls") and response.tool_calls:
        tool_call = response.tool_calls[0]
        return {"tool_to_call": tool_call["name"], "tool_args": tool_call["args"], "messages": [response]}
    return {"tool_to_call": None, "messages": [response]}
```

---

## 5. Grafo LangGraph (`agent/graph.py`)

```python
from langgraph.graph import StateGraph, END
from app.agent.nodes.retrieve import retrieve_context
from app.agent.nodes.planner import planner
from app.agent.nodes.executor import executor

def build_graph() -> StateGraph:
    graph = StateGraph(AgentState)
    graph.add_node("retrieve", retrieve_context)
    graph.add_node("planner", planner)
    graph.add_node("executor", executor)
    graph.set_entry_point("retrieve")
    graph.add_edge("retrieve", "planner")
    graph.add_conditional_edges("planner", lambda s: "executor" if s.get("tool_to_call") else END)
    graph.add_edge("executor", "planner")
    return graph.compile()

agent_graph = build_graph()
```

---

## 6. Agent Service (`service/agent_service.py`)

```python
from langchain_core.messages import HumanMessage
from app.agent.graph import agent_graph

class AgentService:
    async def process_message(self, session_id: str, user_message: str) -> str:
        initial_state = AgentState(
            messages=[HumanMessage(content=user_message)],
            retrieved_context=[], tool_to_call=None, tool_args={}, tool_result=None, session_id=session_id,
        )
        final_state = await agent_graph.ainvoke(initial_state)
        last_ai_message = next((m for m in reversed(final_state["messages"]) if m.type == "ai"), None)
        return last_ai_message.content if last_ai_message else "Sem resposta."
```

---

## Dependências

- [[sdd_fase3_obsidian_service]] — Tools do Obsidian registradas no Tool Registry
- [[sdd_fase4_rag_pipeline]] — SemanticRetriever usado no nó de recuperação
