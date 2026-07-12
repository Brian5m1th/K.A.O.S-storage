# ADR-008: Security Model & Trust Boundaries

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

The MCP platform manages external servers that can execute arbitrary operations on the host system. Each server has a different trust profile — official Model Context Protocol servers are audited and well-maintained, while community servers may have unknown security properties.

A security breach could occur through:

1. **Malicious MCP server** — intentionally harmful code.
2. **Compromised MCP server** — legitimate server with a vulnerability.
3. **Prompt injection** — attacker manipulates the AI agent into invoking dangerous tools.
4. **Supply chain attack** — dependency of an MCP server is compromised.
5. **Configuration leakage** — secrets in config files are exposed.
6. **Man-in-the-middle** — HTTP/SSE transport intercepted.

## Decision

### Trust Model

```
                        ┌──────────────────────────┐
                        │      User / Owner          │
                        │  (Fully Trusted)           │
                        └──────────┬────────────────┘
                                   │
                        ┌──────────▼────────────────┐
                        │    AI Agent (Agent)         │
                        │  (Trusted with restrictions) │
                        └──────────┬────────────────┘
                                   │
            ┌──────────────────────┼──────────────────────┐
            │                      │                      │
            ▼                      ▼                      ▼
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│  Trusted Server     │  │  Community Server  │  │  Untrusted Server   │
│  (Official MCPs)    │  │  (Verified)         │  │  (Unknown Source)   │
│  - Context7         │  │  - Serena           │  │  - Custom scripts   │
│  - GitHub           │  │  - n8n             │  │  - Experimental     │
│  - Playwright       │  │  - Qdrant          │  │  - Third-party      │
│  - PostgreSQL       │  │  - Obsidian        │  │                     │
│  - Filesystem       │  │                    │  │                     │
│  - Docker           │  │                    │  │                     │
└──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘
           │                        │                        │
           ▼                        ▼                        ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                    Security Controls                          │
    │  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐ ┌──────┐   │
    │  │Sandbox  │ │Network   │ │Filesystem│ │Secrets │ │Audit │   │
    │  │Isolation│ │Policies  │ │Boundaries│ │Manager │ │Logs  │   │
    │  └─────────┘ └──────────┘ └─────────┘ └────────┘ └──────┘   │
    └──────────────────────────────────────────────────────────────┘
```

### Threat Model (STRIDE)

| Category | Threat | Mitigation |
|----------|--------|-----------|
| **S**poofing | Attacker impersonates a legitimate MCP server (man-in-the-middle on HTTP/SSE) | TLS for all network transports; GPG signing for registry entries |
| **T**ampering | Attacker modifies server binary or configuration | Checksum verification before execution; config file integrity monitoring |
| **R**epudiation | Server denies executing a dangerous tool | Full audit logging with agent_id, server_id, tool_name, args, timestamp |
| **I**nformation Disclosure | Secrets (tokens, passwords) leaked through logs or error messages | Secrets never logged; environment variable redaction in audit trails |
| **D**enial of Service | Malicious server consumes excessive resources (CPU, RAM, disk) | Resource limits per server (CPU quota, RAM limit, timeout); health monitoring alerts |
| **E**levation of Privilege | Server breaks out of sandbox to access unauthorized resources | Filesystem boundaries; workspace isolation; OS-level sandboxing (Docker, Firejail) |

### Trust Boundaries

```
Boundary A: Host OS vs MCP Platform
────────────────────────────────────
- The MCP platform runs as the user's process
- STDIO servers inherit the user's permissions
- Mitigation: Docker containers for untrusted servers; resource limits for all

Boundary B: MCP Platform vs AI Agent
────────────────────────────────────
- The agent communicates with the platform via STDIO or HTTP
- The agent should not have direct access to server binaries or config
- Mitigation: Platform is the sole controller of server processes

Boundary C: MCP Server vs Filesystem
─────────────────────────────────────
- Servers like Filesystem have arbitrary read/write access
- Mitigation: Workspace boundaries; allowed_paths / denied_paths configuration

Boundary D: MCP Server vs Network
──────────────────────────────────
- Servers like Fetch and Tavily make arbitrary network requests
- Mitigation: Network policies (allow/deny domains); proxy configuration

Boundary E: MCP Server vs Other Servers
────────────────────────────────────────
- Servers should not interfere with each other
- Mitigation: Each STDIO server is an isolated subprocess; Docker containers for network servers
```

### Security Controls by Server Category

| Category | Filesystem Access | Network Access | Shell Execution | Secret Handling |
|----------|-------------------|----------------|-----------------|-----------------|
| **Official STDIO** | Workspace only | None (or specific endpoints) | No | Token via env vars |
| **Official HTTP/SSE** | None | Specific endpoints (TLS) | No | Token via headers |
| **Community STDIO** | Workspace only (bound) | Whitelist only | No (denied by default) | Token via env vars |
| **Community HTTP/SSE** | None | Whitelist only | No | Token via headers with scope |
| **Custom/Untrusted** | None (unless explicitly allowed) | None (unless explicitly allowed) | No | Never |
| **Docker containers** | Mounted volumes only | Docker network | Within container only | Docker secrets |

### Secret Management

```
┌───────────────────────────────────────┐
│           Secrets Manager              │
│                                        │
│  Resolution Order:                     │
│  1. Environment variable               │
│  2. Encrypted secrets file             │
│     ($MCP_HOME/secrets/<name>.enc)    │
│  3. OS keyring (future)                │
│  4. Interactive prompt (fallback)      │
│                                        │
│  Storage:                              │
│  - Age encryption (age/n ago)         │
│  - Key: $MCP_HOME/secrets/key.age     │
│  - Files: $MCP_HOME/secrets/*.enc     │
└───────────────────────────────────────┘
```

### Audit Logging

All security-relevant events are logged:

```yaml
# $MCP_HOME/logs/audit.log
- timestamp: "2026-07-12T14:30:00.123Z"
  event: server_start
  server_id: github
  pid: 12345
  agent: opencode
  transport: stdio

- timestamp: "2026-07-12T14:30:01.456Z"
  event: tool_call
  server_id: filesystem
  tool: filesystem_write
  args: { path: "/workspace/src/main.py", content: "..." }
  agent: claude-code
  decision: ALLOW
  decision_id: "auth_a1b2c3d4"

- timestamp: "2026-07-12T14:30:02.789Z"
  event: permission_denied
  server_id: docker
  tool: docker_destroy
  args: { container: "production-db" }
  agent: opencode
  reason: "High-risk tool requires approval"
  decision_id: "auth_e5f6g7h8"
```

### Incident Response

```yaml
# $MCP_HOME/security/incident-response.yaml
severity_levels:
  critical:
    description: "Active breach or data exfiltration"
    actions:
      - "mcp emergency stop"
      - "revoke all tokens"
      - "restore from last known good backup"
      - "audit all logs"

  high:
    description: "Suspicious activity detected"
    actions:
      - "mcp stop <affected-server>"
      - "investigate logs"
      - "rollback if recently updated"

  medium:
    description: "Policy violation"
    actions:
      - "mcp server disable <affected-server>"
      - "review configuration"

  low:
    description: "Failed permission attempt"
    actions:
      - "log only"
      - "no automatic action"
```

## Evidence Supporting This Decision

1. The user explicitly requested a STRIDE threat model and trust boundaries.
2. Official MCP servers (Context7, modelcontextprotocol/*) follow security best practices.
3. The existing K.A.O.S codebase has a minimal security model — this ADR formalizes it.
4. Industry standards: OWASP, NIST, STRIDE.

## Consequences

### Positive

- Defense in depth — multiple layers of security controls.
- Clear trust boundaries — every server has a defined security profile.
- Comprehensive audit trail for forensics.
- Least-privilege principle — servers only access what they need.

### Negative

- Security controls add complexity and some performance overhead.
- Secret encryption requires key management.

### Risks & Mitigations

- **Risk:** Encryption key lost → **Mitigation:** Recovery procedure with printed backup key.
- **Risk:** False positives in intrusion detection → **Mitigation:** Configurable severity thresholds.

## Implementation Plan

1. Implement trust level classification for all servers in registry.
2. Implement filesystem boundary enforcement.
3. Implement network policy enforcement.
4. Implement secret manager with encryption.
5. Implement audit logging system.
6. Create incident response procedures document.

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
