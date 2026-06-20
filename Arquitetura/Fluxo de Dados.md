---
type: knowledge
domain: arquitetura
status: active
---

# Fluxo de Dados
*System Data Flow*

> Mapeamento do ciclo de vida das requisicoes e processamento de mensagens entre o Open WebUI, FastAPI e LangGraph.

## Parent
- [[Arquitetura Geral]]

## Children
- [[Estrutura de Pastas]]
- [[Infraestrutura Docker]]

## Related
- [[Estrutura de Pastas]]
- [[Arquitetura de Orquestracao]]
- [[Infraestrutura Docker]]

## Tags
#kaos #arquitetura #dataflow #langgraph

---

## Conteudo
# Fluxo de Dados e Ciclo de Vida do Agente

Esta nota documenta os caminhos que uma mensagem percorre, incluindo o **roteamento inteligente** (FAST/MEMORY/SMART).

---

## Visão Geral do Roteamento

Toda mensagem passa pelo `IntentClassifier` antes de ser processada:

1. **FAST** → execução direta de tools (sem LLM, sem RAG, sem LangGraph)
2. **MEMORY** → RAG + LLM (sem LangGraph)
3. **SMART** → LangGraph completo (planner + executor + tools)

```
                                 ┌─────────────┐
                                 │  Mensagem    │
                                 │  + user_id   │
                                 └──────┬──────┘
                                        │
                                 ┌──────▼──────┐
                                 │   Cache     │
                                 │  (hit? retorna) │
                                 └──────┬──────┘
                                        │
                                 ┌──────▼──────────┐
                                 │ IntentClassifier │
                                 │  keyword + LLM   │
                                 └──────┬──────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
              ┌─────▼─────┐     ┌──────▼──────┐     ┌─────▼──────┐
              │   FAST     │     │   MEMORY    │     │   SMART     │
              │ (tool sem  │     │ (RAG + LLM  │     │ (LangGraph  │
              │  LLM/RAG)  │     │  sem tools) │     │  completo)  │
              └─────┬─────┘     └──────┬──────┘     └─────┬──────┘
                    │                  │                  │
              ┌─────▼─────┐     ┌──────▼──────┐     ┌─────▼──────────┐
              │  Tool      │     │  Qdrant     │     │  AgentService  │
              │  Registry  │     │  + Ollama   │     │  (LangGraph)   │
              └───────────┘     └─────────────┘     │  + user context │
                                                     └────────────────┘
```

---

## Fluxo FAST — Execução Direta de Tools

Usado para comandos diretos que não precisam de conhecimento do vault nem raciocínio complexo.

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário
    participant API as FastAPI
    participant CLASS as IntentClassifier
    participant FAST as FastRouter
    participant TOOL as Tool Registry

    User->>API: "liste minhas notas"
    API->>CLASS: classify("liste minhas notas")
    CLASS-->>API: FAST
    API->>FAST: fast_route("liste minhas notas")
    FAST->>TOOL: list_notes()
    TOOL-->>FAST: resultado
    FAST-->>API: resposta
    API-->>User: "3 notas encontradas"
```

---

## Fluxo MEMORY — RAG + LLM sem LangGraph

Usado para perguntas que precisam de contexto do Vault mas não exigem ferramentas ou raciocínio multi-passo.

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário
    participant API as FastAPI
    participant CLASS as IntentClassifier
    participant MEM as MemoryRouter
    participant RAG as Qdrant
    participant LLM as Ollama

    User->>API: "o que existe no backlog?"
    API->>CLASS: classify(...)
    CLASS-->>API: MEMORY
    API->>MEM: stream(query)
    MEM->>RAG: search(query, limit=5)
    RAG-->>MEM: chunks relevantes
    MEM->>LLM: system + contexto + pergunta
    LLM-->>MEM: stream de tokens
    MEM-->>API: tokens
    API-->>User: resposta fundamentada
```

---

## Fluxo SMART — LangGraph Completo

Usado para perguntas complexas que exigem planejamento, múltiplas ferramentas ou raciocínio encadeado.

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário
    participant API as FastAPI
    participant SVC as SmartRouter (AgentService)
    participant GRAPH as LangGraph
    participant LLM as Ollama

    User->>API: "compare projetos X e Y"
    API->>CLASS: classify(...)
    CLASS-->>API: SMART
    API->>SVC: stream(session_id, mensagem, user_context)
    SVC->>GRAPH: astream_events(initial_state)
    
    loop LangGraph Loop
        GRAPH->>GRAPH: retrieve_context
        GRAPH->>LLM: planner
        LLM-->>GRAPH: decisão
        alt tool call
            GRAPH->>GRAPH: executor
        end
    end
    
    GRAPH-->>SVC: eventos
    SVC-->>API: tokens
    API-->>User: resposta
```

---

## Fluxo Proxy OpenAI (/v1/chat/completions)

Usado pelo Open WebUI. O FastAPI atua como proxy compatível com OpenAI, com o mesmo roteamento inteligente.

```mermaid
sequenceDiagram
    autonumber
    actor User as Usuário (Open WebUI)
    participant OWUI as Open WebUI
    participant PROXY as FastAPI (/v1/chat/completions)
    participant CLASS as IntentClassifier
    participant LLM as Ollama

    User->>OWUI: Digita mensagem
    OWUI->>PROXY: POST /v1/chat/completions (com user context)
    PROXY->>CLASS: classify(mensagem)
    CLASS-->>PROXY: MEMORY/SMART
    PROXY->>PROXY: roteia para router adequado (com user_id)
    router->>LLM: processa
    LLM-->>router: stream
    router-->>PROXY: tokens
    PROXY-->>OWUI: SSE stream (formato OpenAI)
    OWUI-->>User: Exibe resposta
```

---

## Relacao com outras Notas
- [[Arquitetura de OrquestraçAo]] — SDD detalhada do proxy gateway




