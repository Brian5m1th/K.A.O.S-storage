---
type: knowledge
domain: ia
status: active
---

# Estado do Agente
*Agent State Management*

> Contrato de dados e historico de mensagens que circula entre os nos do grafo do agente inteligente.

## Parent
- [[Fases 6-7 - Watcher LangGraph e MemÓria]]

## Children
- [[index]]
- [[Arquitetura de Orquestracao]]
- [[Fases 6-7 - Watcher LangGraph e Memoria]]
- [[Orquestrador LangGraph]]

## Related
- [[Orquestrador LangGraph]]
- [[Arquitetura de Orquestracao]]

## Tags
#kaos #ia #langgraph #state #python

---

## Conteudo
## 2. Estado do Agente (`agent/state.py`)

O `AgentState` é o "contrato" de dados que circula entre todos os nós do grafo.

```python
from typing import TypedDict, Annotated
from langchain_core.messages import BaseMessage
import operator

class AgentState(TypedDict):
    # Mensagens da conversa (acumuladas via operador de append)
    messages: Annotated[list[BaseMessage], operator.add]
    # Contexto recuperado do Qdrant (RAG)
    retrieved_context: list[dict]
    # Nome da ferramenta decidida pelo planner (None = responder diretamente)
    tool_to_call: str | None
    # Argumentos da ferramenta
    tool_args: dict
    # Resultado da execução da ferramenta
    tool_result: dict | None
    # ID da sessão de chat (para persistência)
    session_id: str
```

---






