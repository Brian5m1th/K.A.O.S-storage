# K.A.O.S Brain Map — Complete Architecture Blueprint

> Generated: 2026-07-11 | Commit: 97444b52 | Graphify: 12,187 nodes / 22,825 edges

## Layer 1 — Knowledge Layer

```
Knowledge Layer
├── Graphify          (AST code graph, structural queries, path tracing)
│   └── Source: graphify-out/graph.json (12k+ nodes, 22k+ edges)
│   └── Role: Code Intelligence — symbol-level analysis
│
├── Qdrant            (Vector store, semantic embeddings)
│   └── Collection: "kaos"
│   └── Role: Semantic Memory — similarity search
│
├── Obsidian          (Vault notes, wiki-links, markdown)
│   └── Role: Documentation Graph — human-readable knowledge
│
├── PostgreSQL        (Relational DB — conversations, users, costs, features)
│   └── Role: Procedural Memory — structured operational data
│
├── RAG Pipeline      (Chunking → Embedding → Indexing → Retrieval)
│   └── Role: Retrieval-Augmented Generation
│
├── KnowledgeGraph    (Vault + DRL + Code merged graph)
│   └── Role: Unified Knowledge visualization
│
├── GraphRAG          (Future) — Knowledge graph construction + multi-hop reasoning
├── Graphiti          (Future) — Temporal knowledge evolution
├── Mem0              (Future) — Persistent user/agent memory
└── Cognee            (Future) — Entity extraction + knowledge graphs
```

## Layer 2 — Reasoning Layer

```
Reasoning Layer
├── LangGraph         (Agent workflow orchestration)
│   └── Nodes: planner, retrieve, ingest, executor
│
├── Planner           (Task decomposition, execution plans)
│
├── Runtime           (OpenCode executor, watcher)
│
├── Evidence Engine   (Drift detection, architecture audit, SDD validation)
│   └── Sources: Graphify + Git + Tests + Coverage + Benchmarks + ADRs
│
├── Decision Engine   (ADR governance, fitness functions, quality gates)
│
├── Letta/MemGPT      (Future) — Long-running autonomous agent loops
└── DSPy             (Future) — Programmatic LLM optimization
```

## Layer 3 — Execution Layer

```
Execution Layer
├── MCP               (Model Context Protocol — tool sandbox)
│   ├── MCPManager    (Server lifecycle)
│   ├── MCPRegistry   (Tool discovery)
│   ├── MCPHealth     (Health monitoring)
│   └── MCPServerBase (Process isolation)
│
├── Providers         (LLM abstraction)
│   ├── OllamaProvider    (Local inference)
│   ├── OpenAIProvider    (Cloud GPT)
│   ├── ClaudeProvider    (Cloud Claude)
│   ├── GeminiProvider    (Cloud Gemini)
│   └── AirLLMProvider    (Local layer-wise 70B)
│
├── LLMFactory        (Provider routing + fallback chain)
├── ProviderMetrics   (Latency, token rate tracking)
│
├── CircuitBreaker    (Retry 3x → Open 3min → Fallback)
├── DeadLetterQueue   (Failed event persistence)
├── ProviderSelector  (Cost/quality load balancing)
│
├── Workflow Engine   (LangGraph-based workflow execution)
└── Orchestrator      (Universal orchestrator)
```

## Layer 4 — Observability Layer

```
Observability Layer
├── EventBus          (Publish/subscribe + DLQ routing)
├── CostTracker       (Token costs, workflow costs per provider)
├── Tracing           (OpenTelemetry spans)
├── ProviderMetrics   (P95/P99 latency, throughput, errors)
├── NotificationService (Alerts, system notifications)
│
├── Prometheus        (Metrics collection)
├── Loki              (Log aggregation)
├── Grafana           (Dashboards)
├── Langfuse          (Future) — LLM observability + evaluation
│
├── Audit Engine      (Documentation coverage, drift detection)
├── Feature Registry  (Feature lifecycle tracking)
└── DRL Snapshot      (Documentation Runtime Layer state)
```

## Layer 5 — Desktop Layer

```
Desktop Layer
├── React + Zustand   (UI + state management)
├── Application Stores
│   ├── system-store   (System status, runtime, metrics)
│   ├── auth-store     (Authentication, server URL)
│   ├── agent-store    (Agent instances, status)
│   ├── chat-store     (Conversation history)
│   └── update-store   (Auto-update state)
│
├── use-init.ts       (Bootstrap pipeline)
│   └── Docker check → Backend health → Readiness → Bootstrap
│
├── AuthGate          (Offline overlay + auth redirect)
├── AppLayout         (Sidebar + content area)
│
├── Pages
│   ├── Dashboard     (Unified telemetry)
│   ├── Architecture  (ReactFlow graph explorer)
│   ├── Observability (Logs, alerts, metrics)
│   ├── Chat          (Agent conversation)
│   ├── Knowledge Graph (Graph visualization)
│   └── Graphify      (Path inspector)
│
├── Tauri (Desktop shell)
│   ├── updater.rs    (Silent updates)
│   ├── Docker check  (Service health)
│   └── Backend health (Readiness gate)
│
└── EventBus (Frontend) (Desktop-side events)
```

## Layer 6 — Integration Layer

```
Integration Layer
├── REST API (FastAPI)
│   ├── /api/system/*      (Status, dashboard, readiness, environment)
│   ├── /api/auth/*        (Login, token, JWT)
│   ├── /api/chat/*        (Conversation, streaming)
│   ├── /api/agents/*      (Agent instances, status)
│   ├── /api/architecture/*(Graph, dependencies)
│   ├── /api/observability (Health, costs, notifications)
│   └── /api/orchestrator/*(DLQ, pipelines)
│
├── WebSocket / SSE
│   └── /api/observability/logs/stream (Live system logs)
│
├── CLI Tools
│   ├── graphify          (Code graph engine)
│   ├── specify-cli       (SDD workflow)
│   └── kaos-tools        (Audit, architecture)
│
└── External Adapters
    ├── GitHub API        (PRs, commits)
    ├── Docker Engine     (Container orchestration)
    └── Ollama API        (Local LLM server)
```

## Service-to-Capability Mapping

| Service | Current Provider | Future Candidates | Status |
|---|---|---|---|
| GraphService | Graphify (graph.json) | Neo4j, NetworkX | ✅ Active |
| MemoryService | PostgreSQL | Mem0, Graphiti, SQLite | ⚠️ In Research |
| RetrievalService | Qdrant | FalkorDB, ChromaDB | ✅ Active |
| InferenceService | Ollama, OpenAI, Gemini, Claude, AirLLM | Local LLaMA.cpp | ✅ Active |
| PlannerService | LangGraph | Letta, CrewAI, AutoGen | ⚠️ In Research |
| EvidenceService | Graphify + Git + Tests | + ADRs + Benchmarks | ⚠️ Partial |
| KnowledgeService | GraphBuilder + KnowledgeGraph | GraphRAG + Cognee | ⚠️ In Research |
| ExecutionService | MCP | Docker, Kubernetes | ✅ Active |
| TelemetryService | Prometheus, Grafana, Loki | Langfuse, OpenTelemetry | ✅ Active |
| CostService | CostTracker | Langfuse | ✅ Active |
