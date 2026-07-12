# ADR-001: Scope and Purpose — Personal AI Engineering Platform (MCP)

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

We are building a **Personal AI Engineering Platform** based on the Model Context Protocol (MCP). This platform must serve as a shared, reusable engineering capability across **every software project** the owner develops — not just K.A.O.S.

The platform manages MCP servers and exposes their tools to AI coding agents (Claude Code, OpenCode, Antigravity, Cursor, VS Code AI extensions, and future MCP-compatible agents).

Key constraints:

1. No vendor lock-in — any MCP-compatible agent should work.
2. Cross-platform — Windows, macOS, Linux, WSL.
3. Portable across projects — K.A.O.S, Wakanda, personal APIs, Java, Spring Boot, React, Tauri, Python, infra repos, and future projects.
4. Version-controlled — the entire platform configuration must be reproducible.
5. Secure by default — least-privilege permissions, audited tool execution.
6. Easy to maintain — modular, documented, with automated updates and rollback.

## Decision

The platform will be implemented in three sequential phases:

### Phase 0 — Architecture & Specification (current)
Produce complete architecture documentation before any code is written:

- Architecture Decision Records (ADRs)
- System architecture document
- C4 diagrams (Context, Container, Component)
- Sequence diagrams (discovery, tool call, permission, update)
- Deployment diagrams (standalone, Docker)
- Threat model (STRIDE)
- Data flow diagrams
- Security model
- Permission model
- Transport abstraction design
- Lifecycle definitions (server, plugin, agent)

### Phase 1 — Universal MCP Platform
Implement the shared infrastructure:

- Configuration registry (`~/.config/mcp/`)
- MCP server catalog with versioned `registry.yaml`
- Cross-platform installers (PowerShell, Bash)
- Docker Compose stack for containerized servers
- Auto-configuration generators for all supported agents
- Health monitoring system
- Update manager with rollback support
- Benchmark suite

### Phase 2 — K.A.O.S Integration
Integrate the platform into K.A.O.S:

- MCP Gateway — routing, fallback, circuit breaker
- Permission Engine — multi-dimensional authorization
- SSE/HTTP transport abstraction
- Capability Registry — rich tool metadata
- 7 custom K.A.O.S MCP servers (Graphify, KIRL, n8n, Obsidian, Workflows, Qdrant, GitHub Actions)
- Desktop MCP Host (Tauri sidecar)
- Observability dashboard

## Evidence Supporting This Decision

1. The existing K.A.O.S codebase already has a working `MCPManager`, `MCPRegistry`, `MCPAdapter`, and a Desktop UI for managing MCP servers — proving the viability of MCP integration.
2. The user's development workflow spans multiple AI agents (Claude Code, OpenCode, Antigravity) and multiple projects — requiring a shared, not project-specific, infrastructure.
3. Industry best practices (Model Context Protocol specification) recommend STDIO for local and HTTP/SSE for remote transports.

## Consequences

### Positive

- Single source of truth for all MCP configuration across all projects.
- Any MCP-compatible agent can use the same infrastructure.
- Fully reproducible configuration via version control.
- Clear separation between platform (Phase 0/1) and project integration (Phase 2).

### Negative

- Higher initial investment in documentation before implementation.
- Overhead of maintaining a separate platform configuration layer.

### Risks & Mitigations

- **Risk:** Scope creep in Phase 0 → **Mitigation:** Strictly limit Phase 0 to documentation; no code.
- **Risk:** Platform becomes K.A.O.S-specific despite intent → **Mitigation:** Phase 1 must be demonstrably usable without K.A.O.S.

## Implementation Plan

1. Produce ADR series (001–009) covering all architecture decisions.
2. Produce C4 diagrams (Context, Container, Component).
3. Produce sequence diagrams (discovery, tool call, permission, update).
4. Produce deployment diagrams (standalone, Docker).
5. Produce threat model (STRIDE).
6. Produce data flow diagrams.
7. Review all documents with the owner.
8. Begin Phase 1 implementation.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Skip architecture phase | Faster initial progress | Risk of wrong decisions, technical debt | Documentation is essential for long-term maintainability |
| Build directly into K.A.O.S only | Faster K.A.O.S integration | Not reusable for other projects | Must serve as a **personal** platform, not just K.A.O.S |
| Use existing community tooling (e.g., `mcp-cli`) | Less custom code | May not meet all requirements, harder to customize | Need full control over architecture |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
