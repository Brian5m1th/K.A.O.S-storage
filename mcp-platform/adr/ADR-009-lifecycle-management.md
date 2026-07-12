# ADR-009: Lifecycle Management (Server, Plugin, Agent)

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

The MCP platform manages three distinct lifecycles:

1. **Server Lifecycle** — MCP servers are external processes that must be started, monitored, and stopped.
2. **Plugin Lifecycle** — The platform itself will support plugins (future expansion: custom transports, permission policies, health monitors).
3. **Agent Lifecycle** — AI agents connect to the platform, discover tools, and eventually disconnect.

Each lifecycle has distinct states, transitions, and error handling requirements. Without formal lifecycle definitions:

- Resources (processes, ports, memory) may leak.
- Failed servers may not be properly restarted.
- Graceful shutdown is not guaranteed.
- Dependencies between servers are not managed.

## Decision

### Server Lifecycle

```
                      ┌──────────────┐
                      │   REGISTERED │  (Loaded from registry.yaml)
                      └──────┬───────┘
                             │
                      ┌──────▼───────┐
                      │  INSTALLING  │  (mcp install <server>)
                      └──────┬───────┘
                             │ success / failure
                      ┌──────▼───────┐
               ┌──────│  INSTALLED   │──────┐
               │      └──────┬───────┘      │
               │             │               │
               │      ┌──────▼───────┐      │
               │      │   STARTING   │      │
               │      └──────┬───────┘      │
               │             │ success/fail │
               │      ┌──────▼───────┐      │
               │  ┌───│   RUNNING    │───┐  │
               │  │   └──────┬───────┘   │  │
               │  │          │            │  │
               │  │   ┌──────▼───────┐   │  │
               │  │   │   HEALTHY    │   │  │
               │  │   └──────┬───────┘   │  │
               │  │          │            │  │
               │  │   ┌──────▼───────┐   │  │
               │  └───│  DEGRADED    │───┘  │
               │      └──────┬───────┘      │
               │             │               │
               │      ┌──────▼───────┐      │
               │      │   STOPPING   │      │
               │      └──────┬───────┘      │
               │             │               │
               │      ┌──────▼───────┐      │
               └──────│   STOPPED    │◄─────┘
                      └──────┬───────┘
                             │
                      ┌──────▼───────┐
                      │  UNINSTALLED │  (mcp uninstall <server>)
                      └──────────────┘
```

| State | Description | Entry Action | Exit Action |
|-------|-------------|-------------|-------------|
| `REGISTERED` | Server is known in the registry but not installed | None | — |
| `INSTALLING` | Downloading and installing server binaries | Create temp dir, download, verify checksum | Clean up on failure |
| `INSTALLED` | Binaries are on disk, ready to start | Record version in registry | — |
| `STARTING` | Initializing the server process | Spawn subprocess, perform handshake | Kill process on failure |
| `RUNNING` | Server process is active | — | — |
| `HEALTHY` | Server responded to health check successfully | Update health cache | — |
| `DEGRADED` | Server is running but health check failed | Log warning, trigger recovery | — |
| `STOPPING` | Gracefully shutting down | Send shutdown, wait for exit | Force kill on timeout |
| `STOPPED` | Server process is not running | Release resources | — |
| `UNINSTALLED` | Server binaries are removed from disk | Clean up config, cache, logs | — |

### Server Lifecycle Commands

```bash
mcp server install <id>         # REGISTERED → INSTALLED
mcp server start <id>           # INSTALLED → STARTING → HEALTHY
mcp server stop <id>            # HEALTHY → STOPPING → STOPPED
mcp server restart <id>         # HEALTHY → STOPPING → STOPPED → STARTING → HEALTHY
mcp server uninstall <id>       # STOPPED → UNINSTALLED
mcp server status <id>          # Current state + health info
mcp server logs <id>            # Tail server logs
mcp server reset <id>           # UNINSTALLED → REGISTERED (factory reset)
```

### Server Health Classification

| Health Status | Criteria | Recovery Action |
|---------------|----------|-----------------|
| `healthy` | Responds to `tools/list` within expected latency | None |
| `degraded` | Responds but latency > 2x expected | Log warning |
| `unhealthy` | Responds with errors or partial data | Attempt restart (max 3 times) |
| `down` | No response, process exited | Attempt restart (max 3 times); if persistent, mark as `failed` |
| `failed` | All restart attempts exhausted | Set state to `stopped`; notify user |

### Server Dependency Management

Some servers depend on other services (e.g., PostgreSQL depends on a running database):

```yaml
# registry.yaml
servers:
  - id: postgres
    name: "PostgreSQL MCP"
    dependencies:
      - service: postgresql
        type: docker
        compose_file: "docker-compose.yml"
        service_name: "postgres"
        health_check: "pg_isready"
    start_order: 2
```

Servers are started in dependency order. If a dependency is not available, the server waits or fails with a clear error.

### Plugin Lifecycle (Future)

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  DISCOVERED  │─────►│   LOADED     │─────►│  INITIALIZED │
└──────────────┘      └──────────────┘      └──────┬───────┘
                                                    │
                                             ┌──────▼───────┐
                                             │   ACTIVE     │
                                             └──────┬───────┘
                                                    │
                                             ┌──────▼───────┐
                                             │  DISABLED    │
                                             └──────────────┘
```

Plugins extend the platform itself:

- Custom transport implementations
- Custom permission policies
- Custom health check providers
- Custom log processors

### Agent Lifecycle

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  DISCOVERED  │─────►│ CONNECTED    │─────►│ TOOLS_LOADED │
└──────────────┘      └──────────────┘      └──────┬───────┘
                                                    │
                                             ┌──────▼───────┐
                                             │   ACTIVE     │
                                             └──────┬───────┘
                                                    │
                                             ┌──────▼───────┐
                                             │ DISCONNECTED │
                                             └──────────────┘
```

| State | Description |
|-------|-------------|
| `DISCOVERED` | Agent has announced itself via the platform |
| `CONNECTED` | Agent has authenticated and established a session |
| `TOOLS_LOADED` | Agent has received the list of available tools |
| `ACTIVE` | Agent is making tool calls |
| `DISCONNECTED` | Agent has ended the session |

## Evidence Supporting This Decision

1. The existing `_MCPServerProcess` class in `app/core/mcp_manager.py` implements a subset of these states (initialize, running, shutdown).
2. Process lifecycle management is a well-understood pattern (Docker, systemd, Kubernetes).
3. Health checks (already implemented in `mcp_health.py`) are a standard pattern for service monitoring.

## Consequences

### Positive

- Clear, predictable server behavior — no zombie processes.
- Automated recovery from failures.
- Proper resource cleanup on shutdown.
- Dependency ordering prevents startup race conditions.
- Extensible plugin architecture for future needs.

### Negative

- State machine adds complexity to the server manager.
- Dependency management can complicate startup ordering.

### Risks & Mitigations

- **Risk:** State machine becomes inconsistent (e.g., process crashes but state says `healthy`) → **Mitigation:** Periodic reconciliation (health check detects and corrects state).
- **Risk:** Cyclic dependencies between servers → **Mitigation:** Dependency graph validation at registration time.

## Implementation Plan

1. Formalize server state machine in `MCPServer` base class.
2. Implement state transitions with guard conditions.
3. Implement automatic restart with exponential backoff.
4. Implement dependency ordering for server startup.
5. Implement plugin lifecycle (future phase).
6. Implement agent session lifecycle (Phase 2).
7. Update `mcp server` CLI commands to reflect states.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Stateless (start/stop only) | Simple | No recovery, no health tracking | Must have automated recovery |
| Use systemd to manage servers | Robust lifecycle | Not cross-platform (Windows) | Must support all platforms |
| Docker for all servers | Good isolation | Overhead for simple STDIO servers | STDIO is preferred for local tools |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
