# K.A.O.S Platform Evolution & Autonomous Engineering Specification (v13)

This master blueprint defines the 43-chapter engineering standards, governance protocols, lifecycle management, and runtime loop for the K.A.O.S platform.

---

## 1. Architectural Rules & Core Bounds

> [!IMPORTANT]
> **Zero Tolerance for Fabricated Data**: K.A.O.S Desktop must never fabricate runtime information in production mode.
> If backend data is unavailable, unreachable, or incomplete, the UI shall display:
> - **Loading** (during query state)
> - **Offline** (if the backend is unreachable)
> - **Unknown** / **No Data** (if values are uninitialized or empty)
> - **Error** (with detailed messages and stacktraces where applicable)
>
> The frontend must never generate simulated operational metrics, fake alerts, placeholder logs, artificial VRAM, fabricated model names, synthetic costs, or randomly generated runtime values.
>
> **CPU/VRAM Detection**: If no Nvidia or AMD GPU is detected:
> - The backend must report VRAM as `null` (used and total).
> - The frontend must display `VRAM: CPU Mode`.
> - Never output fake VRAM allocations (such as `1.0 / 16GB` or `0.0 / 16GB`) when GPU hardware is absent.

---

## 2. Platform Core Fixes (Phase 12 Recap)

### Component 0: Frontend Mock Elimination Audit & CI Check
- **Dashboard & Observability**: Remove `fallbackAlerts`, static log seeds, and fallback mock badges.
- **Auto-verification**: Integrate `verify-no-mocks.ps1` to reject hardcoded mock patterns on check-in.

### Component 1: Consolidation of Duplicate Stores & Hooks
- Delete duplicate stores under `shared/lib/stores/` and direct imports to `@/application/stores`. Remove duplicate `useSystemMetrics` hooks.

### Component 2: Boot & Readiness Gates (Offline Blocking Screen)
- Implement `GET /api/system/readiness` returning state for DB, vectors, and providers.
- Halt boot progression if offline, displaying a block overlay with retry buttons. Reroute and measure startup timers.

### Component 3: Endpoint Unification (GET `/api/system/dashboard`)
- Aggregate 12 telemetry requests into a single `/api/system/dashboard` call utilizing `asyncio.gather` for parallelized execution.

---

## 3. Tool Integration: Spec Kit, Graphify, AirLLM, & Advanced Tool Suite

We have integrated core engineering, SDD, local execution, and advanced cognitive libraries:

### 3.1. GitHub Spec Kit
- **Status**: Installed and configured for Google Antigravity (`specify-cli`).
- **Scaffold**: Active SDD memories placed inside `.specify/memory/` (`constitution.md`, `specification.md`, `plan.md`, `tasks.md`).
- **Standard**: All future feature requirements must be documented in Spec Kit format prior to starting implementation.

### 3.2. Graphify Codebase Mapped
- **Status**: Installed via `graphifyy` and integrated into `.agents/rules/graphify.md`.
- **Dataset**: Generated `graphify-out/graph.json` containing 12,187 nodes and 22,825 AST code and doc connections.

#### 3.2.1. Proof of Graphify Execution (Codebase Relationship Queries)

To verify the relationships and dependency structures of model providers, we queried the Graphify knowledge graph CLI directly:

**Query 1: Explaining OllamaProvider**
```bash
$ graphify explain "OllamaProvider"
Node: OllamaProvider
  ID:        assistant_app_llm_providers_ollama_provider_ollamaprovider
  Source:    assistant/app/llm/providers/ollama_provider.py L12
  Type:      code
  Community: OllamaProvider
  Degree:    12

Connections (12):
  <-- LLMFactory [uses] [INFERRED]
  --> BaseProvider [uses] [INFERRED]
  <-- ._create_provider() [calls] [INFERRED]
  --> .astream() [method] [EXTRACTED]
  --> .ainvoke() [method] [EXTRACTED]
  --> .invoke() [method] [EXTRACTED]
  --> ._rebuild() [method] [EXTRACTED]
  --> .stream() [method] [EXTRACTED]
  --> .__init__() [method] [EXTRACTED]
  --> .model_name() [method] [EXTRACTED]
  --> .provider_name() [method] [EXTRACTED]
  <-- ollama_provider.py [contains] [EXTRACTED]
```

**Query 2: Tracing Path between Active Config Resolver and OllamaProvider**
```bash
$ graphify path "get_active_provider_config" "OllamaProvider"
Shortest path (3 hops):
  get_active_provider_config() <--calls [INFERRED]-- ._resolve_model_config() <--method [EXTRACTED]-- LLMFactory --uses [INFERRED]--> OllamaProvider
```

These outputs provide deterministic, verifiable proof that the Graphify indexing engine successfully mapped and linked K.A.O.S system configurations to their runtime destinations.

---

### 3.3. AirLLM Inference Layer
- **Status**: Cloned repository from `lyogavin/airllm` into the project root.
- **Goal**: Serve as a low-VRAM, layer-wise model execution runner to process massive 70B parameter models (e.g. Llama 3.1 70B) or higher on standard developer hardware (e.g. 4GB/8GB GPUs) without quantization degradation.
- **Integration**: Implemented `AirLLMProvider` in the backend provider structure. Routes prefixed with `airllm-` (e.g. `airllm-meta-llama/Meta-Llama-3-8B`) will automatically trigger the layer-wise inference loop.

### 3.4. Advanced Tool Suite Layering (Memory, RAG, & Orchestration)
To elevate the platform's cognitive ability, we adopt the following layered architecture:
- **Multi-Agent Layer**: LangGraph for orchestration + Letta (MemGPT) for long-running research loops + OpenHands/Aider for code edits.
- **Unified Memory**: Mem0 for user profiles/preferences + Graphiti for temporal relations evolution.
- **Knowledge Graph RAG**: Graphify for code AST relationships + Microsoft GraphRAG for high-level semantic community indexing.
- **Retrieval & Databases**: LlamaIndex for parsing + FalkorDB (via local docker) for Cypher graph queries + Qdrant for vector embeddings.
- **Observability**: OpenTelemetry instrumentation + Langfuse dashboard for tracing, evaluations, and inference cost tracking.

---

## 4. Graph Architecture Comparison & Deprecation Strategy

```
               COMPARISON OF GRAPH PLATFORMS
┌──────────────────────────────────────┬─────────────────────────────────────┐
│  Built-in Architecture Graph (Old)   │    Graphify Codebase Graph (New)    │
├──────────────────────────────────────┼─────────────────────────────────────┤
│ • High-level components (files/notes)│ • Granular symbols (funcs/imports)  │
│ • Simple regex scanner (CodeScanner) │ • AST Tree-sitter analyzer (Exact)  │
│ • Handcrafted relations only         │ • Louvain community groupings       │
│ • Small, lightweight layout render   │ • Large, heavy database structure   │
└──────────────────────────────────────┴─────────────────────────────────────┘
```

### Recommendation: Hybrid Integration & Deprecation
- **Deprecate the local `CodeScanner`**: The regex scanner (`assistant/app/audit/code_scanner.py`) is prone to errors, ignores actual imports, and requires hardcoded patterns. It is deprecated and removed.
- **Adopt `graphify-out/graph.json` as the unified source**:
  - The backend `GraphBuilder` will be refactored to read from `graphify-out/graph.json` instead of running `CodeScanner.scan_all()`.
  - To prevent frontend rendering crashes with 12,000+ nodes, the backend `/api/architecture/graph` will load `graph.json`, aggregate and cluster nodes at the file/component level, and serve a clean high-level summary to the ReactFlow explorer.
  - Expose a new desktop tab **"Graphify Inspector"** which calls `graphify path` in the backend to let users search and visually trace exact AST paths (e.g. from a route to a model field) across the codebase.

---

## 5. Engineering Standards & Governance

To maintain consistency as the platform grows, every new feature, module, or api route must adhere to these structural policies:

- **Directory Layout (FSD Compliance)**:
  - Frontend code is separated into: `app/` (routes/setup), `pages/` (view controllers), `features/` (isolated logic domains), `entities/` (state models), and `shared/` (common UI elements).
  - Backend modules are divided strictly into: `api/` (rest endpoints), `core/` (services/watchers), `domain/` (entities), and `workflows/` (LangGraph nodes).
- **Naming Conventions**: Use `camelCase` for TypeScript variables, `snake_case` for Python APIs/variables, and `kebab-case` for workspace folders and files.
- **Dependency Injection**: Services and repositories must be injected via dependencies (e.g. FastAPI `Depends`) to enable stubbing in unit tests.
- **DTO Standards**: All input and output payloads at the API layer must use strictly validated Pydantic models or TypeScript interfaces. Direct database model exposure is prohibited.
- **Feature Flags**: Introduce a flags repository (`app/api/feature_flags.py`) to gate new capabilities before deployment validation.

---

## 6. Reliability Engineering (How Features Fail)

All operations targeting external providers, databases, or local watchers must be governed by a programmatic safety pipeline:

```
Request/Action ──► [Try] ──► [On Failure] ──► Retry (3x) ──► Circuit Breaker ──► Local Fallback ──► Log & Alert
```

- **Retry Policies**: Standardize on exponential backoff: retry 3 times with `t = 2^n * 500ms`.
- **Circuit Breaker state rules**: If a service logs 5 failures in 60 seconds, trip the breaker for 3 minutes, automatically executing the local fallback.
- **Fallback Providers**: If `openai` or another cloud LLM provider is blocked or offline, instantly fall back to the configured local `ollama` model (`qwen3:14b`) and flag the run as "Degraded Performance".
- **Compensating Actions**: Workflows that fail midway must trigger undo handlers (e.g., delete temp index folders, revert incomplete database writes).

---

## 7. Observability Platform

Observability must be embedded at the structural level. Every active system resource must emit structured telemetry data.

### 7.1. Tool Telemetry Matrix

Each tool run must record:
- `tool_name`, `execution_start_time`, `execution_end_time`
- `status` (`success` | `failure`)
- `error_message`, `stack_trace`
- `resource_metrics` (CPU, Memory Delta, VRAM Delta during execution)
- `token_count`, `cost_usd` (for LLM calls)

### 7.2. Workflow Telemetry
LangGraph workflow states must track and log step execution, transition times between nodes, queue duration, and state modifications.

### 7.3. API Telemetry
The FastAPI instrumentation must log P95/P99 latency, throughput (requests/minute), and error rates (`5xx` codes) to Prometheus/Loki.

---

## 8. Engineering Quality Gates

No code check-in or deployment merge may proceed without passing the automated quality checks in the pipeline:

```
Lint & Code Style Scan ──► Type Checks ──► Unit & Integration Tests ──► Coverage Check ──► Mutation Score ──► Security Scan ──► Build Verification
```

- **Coverage Gate**: Require a minimum of 80% line coverage for all python and typescript controllers.
- **Mutation Testing Gate**: Verify test assertion validity by requiring a mutation score above 60%.
- **Dependency Check**: Reject check-in if deprecated packages or licenses that violate open-source constraints are found.

---

## 9. Refactoring Strategy & Anti-Pattern Check

Maintain code cleanliness by continuously monitoring files for architectural smells.

- **Automated Complexity Scanner**: Run complexity audits. Any method with cyclomatic complexity > 10 must be refactored.
- **Code Smell Checklist**:
  - **Dead Code**: Remove unused functions, variables, and imports.
  - **Large Classes**: Split classes with length > 300 lines.
  - **Duplicate Code**: Extract duplicated statements spanning > 6 lines into common modules.
  - **God Objects**: Refactor components carrying both business logic, API definition, and state synchronization.

---

## 10. Automated Testing Strategy

Implement a robust, layered testing pyramid:

| Test Level | Coverage Target | Purpose | Tools |
|---|---|---|---|
| **Unit Tests** | > 85% | Validate single functions, helpers, and DTO parsing. | Pytest / Vitest |
| **Integration Tests** | > 70% | Verify database queries, RAG context generation, and graph states. | Pytest-asyncio |
| **Contract Tests** | 100% | Ensure API request/response JSON match schema schemas. | MSW / Pydantic |
| **UI Snapshot Tests** | Core Pages | Validate visual layout consistency across builds. | Playwright |
| **Chaos Tests** | Services | Inject database errors, closed ports, and filesystem blockages. | Mocking / Custom scripts |
| **Performance Tests** | Telemetry APIs | Measure P99 API latency under parallel loads. | Locust / Artillery |

---

## 11. Security Engineering

Apply defense-in-depth principles:

- **Secrets Scanner**: Run pre-commit scanner (e.g. `gitleaks`) to check for committed API keys, tokens, or plaintext passwords.
- **Vault Sandbox**: Isolate vault operations. Prevent path traversals by ensuring all resolved paths stay within the configured `OBSIDIAN_VAULT_PATH`.
- **MCP Permissions System**: Enforce a prompt authorization model. Whenever an MCP tool requests OS access, display a confirmation screen to the user.
- **Prompt Injection Filter**: Apply pre-filters on the backend router to sanitize user requests containing system prompt bypass triggers.

---

## 12. Performance Engineering Targets

Maintain strict performance budgets:

- **Backend Limits**:
  - P95 latency for API requests: `< 200ms` (excluding inference).
  - Connection pool utilization: `< 80%` average.
- **Frontend Limits**:
  - Bundle size (gzip): `< 2.5MB`.
  - Frame rate: `60 FPS` during graph layout renders.
  - Memory leak limit: `< 5MB` delta over 1 hour of use.
- **Inference Limits**:
  - Local Ollama token rate: `> 15 tokens/sec`.
  - Context retrieval index search time: `< 30ms`.

---

## 13. Architecture Fitness Functions

Enforce boundary policies using automated scripts (`verify-architecture.ps1` / pytest-archon):

- **Fit Function 1**: Frontend source files (`desktop/src/`) must never import or depend on backend files (`assistant/`).
- **Fit Function 2**: Workflow handlers (`workflows/impl/`) must not perform SQL transactions (must delegate to repositories).
- **Fit Function 3**: Tools must not access UI components or react state hooks.
- **Fit Function 4**: Avoid circular dependencies. A cycle in module imports automatically blocks git commit.

---

## 14. AI Engineering Layer

Introduce a localized engineering co-pilot inside K.A.O.S:
- **Code & Prompt Reviewer**: Programmatic lint checking code formatting, SOLID violations, and prompt safety.
- **Automatic Test Generator**: Automatically scans modified backend methods, generates matching unit tests with mocks, and executes them to verify correctness.

---

## 15. Knowledge Intelligence Graph

Build a unified relational knowledge graph in the background:

```
 Obsidian Note ◄──► Architecture ADR ◄──► Code Symbol ◄──► Database Model ◄──► Test Suite
```

- Connect markdown documentation nodes with active code files, database schemas, and corresponding unit tests to represent project status in real time.

---

## 16. Self-Healing Platform

- **Fault Detection & Autocall**: When the system detects a service failure (e.g. database connection lost), trigger the self-healing loop:
  - Attempt database session pool reset.
  - Flush expired caches.
  - Notify the user with a clean, actionable status banner.
  - Log an incident report to the system folder.

---

## 17. Continuous Architecture Evolution

- **Weekly Evolution Report**: A background cron service (`PlatformEvolutionEngine`) scans code commits, dependency lists, and test files to generate a consolidated `PROJECT_HEALTH.md` markdown inside the vault.
- The engine assigns structural scores, highlights technical debt, alerts for outdated packages, and outlines priorities for the next maintenance cycle.

---

## 18. AI Planning Engine

- When a new feature prompt is received (e.g., "Integrar OAuth2"):
  - Generate Requirements (EARS/GEARS formats).
  - Draft the Architecture Proposal and ADR file.
  - Produce the SQL/database schema modifications.
  - Scaffold test cases and define the migration/rollback strategies.

---

## 19. Plugin Ecosystem

Enable extensibility by decoupling core systems from plugins:
- Create a Plugin System where new Agents, Workflows, Prompt Templates, and Custom Tools can be loaded dynamically from the `.opencode` directory without altering the canonical backend source files.

---

## 20. Autonomous Platform Evolution Loop

- Implement the complete autonomous evolution flow:
```
Observe State ──► Collect Metrics ──► Detect Problems ──► Analyze ──► Generate Refactor ──► Run Benchmark ──► Approve & Deploy
```

---

## 21. Capability Maturity Matrix

| Capability Area | Level 1 (Initial) | Level 2 (Managed) | Level 3 (Defined) | Level 4 (Measured) | Level 5 (Optimizing) |
|---|---|---|---|---|---|
| **Architecture** | Ad-hoc modules | FSD structure | Unified router | Telemetry-aware | Self-refactoring |
| **Testing** | Manual testing | Basic Unit tests | Integration tests | Mutation testing | Auto-test generation |
| **Observability** | Console printing | Basic File logging | EventBus SSE | OpenTelemetry metrics | Self-healing diagnostic |
| **Security** | None | Secrets Scanner | RBAC & Sandbox | MCP isolation | Prompt Injection filters |

---

## 22. Technical Debt & Platform Readiness Registry

Before releasing a new version or feature, the system must score **90+** on the Readiness Report:
- **Readiness Score formula**:
```
Readiness = (0.3 * Test Coverage) + (0.3 * Architecture Fit) + (0.2 * Security Score) + (0.2 * Telemetry Coverage)
```

---

## 23. Architecture Decision Records Governance

All structural decisions must be committed to the vault in `docs/adr/` using the following governance rules:

- **ADR Frontmatter Lifecycle**: Every ADR file must declare a Status key with the enum values: `Accepted`, `Deprecated`, `Superseded`, `Rejected`.
- **Ownership**: Declare a single `Decision Owner` and a scheduled `Review Date` (default 6 months from entry).
- **Merge Block**: CI automatically rejects any PR that changes configuration variables, database schemas, or dependency layers if a matching new or updated ADR is not included.

---

## 24. Definition of Done (DoD)

A development ticket or pull request is strictly considered complete when and only when all of the following steps have been programmatically validated:

1. **Requirements (EARS/GEARS)**: Traceability map matches spec behaviors.
2. **Architecture**: Fit functions confirm zero boundary imports violations.
3. **Implementation**: Zero mock variables, static strings, or fake delays.
4. **Tests**: Pytest and Vitest test runs exit successfully. Code coverage matches gate limits.
5. **Documentation**: OpenAPI schemas updated and ADR files saved on disk.
6. **Telemetry**: OpenTelemetry trace spans, metrics logging, and alerts are registered.

---

## 25. Release Engineering

- **Semantic Versioning**: Follow `MAJOR.MINOR.PATCH` increments.
- **Release Channels**:
  - `dev` -> local builds.
  - `nightly` -> compiled daily for automated staging runs.
  - `beta`/`rc` -> pre-production user validation.
  - `stable` -> release candidate production distribution.
- **Automated Rollback**: If the desktop launcher fails readiness check three consecutive times after an auto-update, automatically restore the previous stable build and notify the telemetry channel.

---

## 26. Dependency Lifecycle Management

- **Outdated Scans**: Periodic scans running `npm outdated` and `pip list --outdated` are parsed by the `SelfAuditEngine`.
- **Breaking Changes**: Warn if security updates introduce breaking changes by querying package registries.
- **License Compliance**: Reject integration of dependencies using copyleft licenses (e.g. GPLv3) that conflict with project deployment goals.

---

## 27. Workspace Lifecycle

Workspaces must follow an explicit CRUD lifecycle:
- **Operations**:
  - `Create`: initialize standard vault subfolders, SQLite caches, and database schemas.
  - `Clone`: duplicate state models and git configs.
  - `Snapshot`: backup local state before applying schema migrations.
  - `Archive`/`Delete`: wipe database records, delete vector indexes, and close handlers.

---

## 28. Memory Engineering

K.A.O.S stores memory across isolated, specialized partitions:

```
┌────────────────────────────────────────────────────────┐
│                   Memory System                        │
├────────────────────────────────────────────────────────┤
│ Episodic (Chat histories, temporal sessions)           │
│ Semantic (RAG vectors, system documents, knowledge)    │
│ Procedural (Execution scripts, workflows, capabilities)│
│ Decision (ADR schemas, architectural bounds)           │
│ User Profile (Preferences, role context, RBAC limits)  │
└────────────────────────────────────────────────────────┘
```

---

## 29. Prompt Engineering Framework

Prompts are version-controlled assets. Every prompt must contain:
- `owner`: the responsible agent module.
- `inputs`/`outputs`: schema structures.
- `safety_filters`: rules against payload injection.
- **Evaluation**: Prompts run through automated A/B tests to check token-rate outputs and model reasoning consistency before merging into stable channels.

---

## 30. Provider Intelligence

The local AI router executes dynamic cost-quality load balancing:
- Monitor latency, availability, rate limit status, and token cost for active providers (OpenAI, Anthropic, Gemini, local Ollama, LM Studio, AirLLM).
- Automatically route complex planning tasks to advanced cloud models, while routing simple ingestion and semantic indexing tasks to fast local models.

---

## 31. AI Evaluation Framework

Measure system quality using specialized benchmark suites:
- **Coding Benchmark**: Syntax validation, compiler checks, and tests coverage matching.
- **Reasoning/RAG Benchmark**: Precision/Recall metrics on context injections, check for hallucinations in generated summaries.
- **Agent Benchmark**: Goal achievement rate vs number of tool invocations.

---

## 32. Data Lifecycle

Define strict retention rules for local operational data:

| Data Type | Active Store | Backup Policy | Retention / TTL |
|---|---|---|---|
| **System Logs** | Loki / Local text | Daily compression | 7 days |
| **Qdrant Vectors** | Collection 'kaos' | Weekly snapshot | Indefinite |
| **Chat Sessions** | PostgreSQL | Daily DB backup | 90 days |
| **Workspace Files** | Local Vault | Git submodule commit | Indefinite |

---

## 33. Event-Driven Architecture

The core of the system is managed by the `EventBus`:
- **Event Schema**: Events must contain: `event_name`, `payload`, `timestamp`, `producer_module`, and `schema_version`.
- **Handling**: Failed consumers automatically route their payloads to the Dead Letter Queue (DLQ) for retry scheduling.

---

## 34. Cost Engineering

Telemetry dashboards track inference expenses:
- Display real-time token metrics (Input/Output rates), embedding storage expenses, and API billing rates.
- Local execution computes simulated GPU power/electrical consumption to compare offline costs against cloud service calls.

---

## 35. Engineering Analytics

Monitor development performance metrics inside the vault:
- Cycle time of tickets.
- Build/Compilation duration.
- Regression rates (number of bugs found after releases).
- Mean Time to Repair (MTTR) and Mean Time Between Failures (MTBF).

---

## 36. Incident Management

When a system error impacts normal operation:
- Log incident entry containing: severity (Critical/High/Medium), timeline of events, and mitigations applied.
- Trigger automatic fallback to safe modes (e.g. read-only mode).
- Schedule the creation of a postmortem report with action items.

---

## 37. Root Cause Analysis (RCA) Framework

No bug is resolved without completing the RCA workflow:
1. **Symptoms**: describe the visible error.
2. **Evidence**: collect stacktraces and event timeline captures.
3. **5 Whys Analysis**: drill down to identify the root systemic flaw.
4. **Fix & Regression Test**: implement the fix and add a matching test case.
5. **ADR Update**: modify architectural decision records if structural rules were violated.

---

## 38. Engineering Knowledge Base

Maintain a living graph wiki containing:
- API references.
- Schema definitions.
- Active ADR nodes.
- Incident history and troubleshooting runbooks.

---

## 39. AI Governance

Define the autonomy limits of the local AI agent:
- **Requesting human approval**: Mandatory for git push, Docker service stops, local database drops, or files deletions outside the workspace.
- **Auditable actions**: Log all background agent tool invocations to a permanent ledger file.

---

## 40. Human Approval Workflow

Every high-risk agent action prompts the UI overlay:
```
[Approval Request]
Action: Delete file '/vault/Projetos/ObsoleteProject.md'
Reason: Classified as dead code by the evolution scanner.
Risk: Medium (impacts 2 wiki-links)
[ Approve Action ]  [ Reject Action ]
```

---

## 41. Continuous Benchmarking

Run weekly performance assessments comparing different model releases:
- Evaluate Ollama `qwen3:14b` vs `qwen3:4b` under standard RAG query loads, comparing retrieval latency, token rates, and summary accuracy.

---

## 42. Autonomous Engineering Runtime (AER)

The ultimate operational runtime of the K.A.O.S platform ties all components into a self-maintaining loop:

```
┌────────────────────────────────────────────────────────┐
│           Autonomous Engineering Runtime               │
├────────────────────────────────────────────────────────┤
│ 1. Observe (Listen to EventBus, logs, and telemetry)    │
│ 2. Detect (Spot performance drops, exceptions, smells)  │
│ 3. Analyze (Evaluate impact and trace dependencies)    │
│ 4. Plan (Scaffold tests and code refactoring steps)    │
│ 5. Approve (Prompt human authorization for execution)  │
│ 6. Execute (Apply code fixes, compile, and run tests)  │
│ 7. Learn (Record decisions to ADR and update graphs)   │
└────────────────────────────────────────────────────────┘
```

---

## 43. Spec-Driven Development (SDD) Execution Flow

```
   Spec Kit Workflow Loop (governed by specify-cli)
┌───────────────────────────────────────────────────────┐
│ 1. Read Constitution (.specify/memory/constitution.md)│
│ 2. Read Specification (.specify/memory/specification.md)│
│ 3. Review Tech Plan (.specify/memory/plan.md)         │
│ 4. Execute Tasks sequentially (.specify/memory/tasks.md)│
│ 5. Validate outcomes against Quality Gates & DoD      │
└───────────────────────────────────────────────────────┘
```
All feature development must follow the lifecycle dictated by the Spec Kit templates initialized in `.specify/memory/`. Development tickets must check off tasks in `tasks.md` sequentially to maintain trace history and preserve architecture compliance.
