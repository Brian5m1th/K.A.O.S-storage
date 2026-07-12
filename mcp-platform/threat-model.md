# Threat Model — Personal AI Engineering Platform (MCP)

- **Status:** Proposed
- **Date:** 2026-07-12
- **Methodology:** STRIDE

---

## Scope

This threat model covers the Personal AI Engineering Platform described in the System Architecture. The scope includes:

- MCP Platform CLI and Core Library
- MCP Server Processes (STDIO, HTTP/SSE, Docker)
- Configuration Store (`$MCP_HOME`)
- AI Agent integration points
- Update/Rollback system

Out of scope:
- Individual MCP server implementation details (third-party code)
- Specific AI agent vulnerabilities
- Operating system security (assumed hardened)

---

## Trust Boundaries

```
            ┌──────────────────────────────┐
            │        User / Owner          │  T0 (Fully Trusted)
            └────────────┬─────────────────┘
                         │
            ┌────────────▼─────────────────┐
            │      MCP Platform CLI        │  T1 (Trusted)
            │      Core Library            │
            └────────────┬─────────────────┘
                         │
            ┌────────────▼─────────────────┐
            │      AI Agent (Client)        │  T2 (Semi-Trusted)
            └────────────┬─────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
    ▼                    ▼                    ▼
┌──────────┐      ┌──────────┐      ┌──────────────┐
│ STDIO    │      │ HTTP/SSE │      │ Docker MCP   │  T3 (Varying Trust)
│ Servers  │      │ Servers  │      │ Servers      │
└──────────┘      └──────────┘      └──────────────┘
```

### Boundary A: User ↔ Platform (T0 → T1)
- User has full control over platform configuration
- User is responsible for approving high-risk tool calls
- Threat: User approves dangerous operations without understanding risks

### Boundary B: Platform ↔ Agent (T1 → T2)
- Agent communicates via STDIO or HTTP
- Platform validates every tool call through the Authorization Engine
- Threat: Agent is compromised by prompt injection, making malicious tool calls

### Boundary C: Platform ↔ MCP Server (T1 → T3)
- STDIO servers run as subprocesses with user permissions
- HTTP/SSE servers connect over network
- Docker servers run in containers with varying isolation
- Threat: Malicious or compromised server exploits platform trust

---

## STRIDE Analysis

### Spoofing

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| S1 | Attacker spoofs an MCP server endpoint (HTTP/SSE MITM) | High | SSE Transport | TLS for all network transports; certificate pinning for known servers |
| S2 | Attacker spoofs the platform CLI (replacement binary) | High | CLI | Binary signing; checksum verification; `shasum -c` on install |
| S3 | Attacker spoofs registry entries (fake server config) | High | Registry | GPG signing of registry.yaml; trusted key import |
| S4 | Attacker spoofs an agent connection (fake agent) | Medium | Platform API | API key authentication for HTTP connections; STDIO only from trusted processes |

### Tampering

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| T1 | Attacker modifies MCP server binary | Critical | Server binaries | Checksum verification before execution; read-only permissions after install |
| T2 | Attacker modifies registry.yaml | High | Registry | File integrity monitoring; `chmod 644`; Git tracking |
| T3 | Attacker modifies permission policies | High | Authorization Engine | Permission configs are read-only after profile activation; change audit logged |
| T4 | Attacker modifies secret files | Critical | Secrets Manager | Encrypted at rest (age); tamper-evident via checksum; OS file permissions (600) |
| T5 | Attacker modifies log files to hide tracks | Medium | Audit Logger | Append-only log files; remote log shipping (future) |

### Repudiation

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| R1 | Server denies executing a dangerous tool | Medium | Audit Logger | Every tool call logged with agent_id, server_id, tool_name, args, timestamp, decision_id |
| R2 | Agent denies making a tool call | Medium | Audit Logger | Agent authentication before session; all requests logged with agent identity |
| R3 | User denies approving a dangerous operation | Low | Approval System | Approval decisions logged with user identity and timestamp |

### Information Disclosure

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| I1 | Secrets leaked via MCP server error messages | High | Server output | Secrets redaction in log output; env vars never serialized |
| I2 | Secrets leaked via audit logs | High | Audit Logger | Secrets are never logged; parameter values are sanitized |
| I3 | Filesystem MCP server reads sensitive files | High | Filesystem Server | Workspace boundaries; path allowlist/denylist; no access to home directory |
| I4 | Network MCP server exfiltrates data | High | Fetch, Browser servers | Network policies restrict domains; proxy for monitoring (future) |
| I5 | Configuration files exposed via world-readable permissions | Medium | Config Store | `$MCP_HOME` permissions: 755 for dirs, 644 for non-secret files, 600 for secrets |
| I6 | Memory MCP server exposes sensitive project data | Medium | Memory Server | Knowledge base stored in workspace; no global scope |

### Denial of Service

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| D1 | MCP server consumes excessive CPU/RAM | High | Server processes | Process-level resource limits (ulimit, cgroups); health monitoring alerts |
| D2 | MCP server spawns infinite subprocesses | High | Server Manager | Maximum process count limit; zombie process cleanup |
| D3 | Network server floods disk with logs | Medium | Log system | Log rotation (max size, max age); rate limiting for log writes |
| D4 | Authorization engine bypass attempt flood | Low | Authorization Engine | Rate limiting on auth requests; fail-closed on overload |

### Elevation of Privilege

| # | Threat | Risk | Affected Component | Mitigation |
|---|--------|------|-------------------|------------|
| E1 | MCP server breaks out of filesystem boundaries | Critical | Filesystem Server | Workspace boundaries enforced at application level; path canonicalization; symlink attack prevention |
| E2 | MCP server escapes Docker container | Critical | Docker Servers | Run with least-privilege user; no privileged mode; read-only rootfs |
| E3 | Agent bypasses authorization engine | Critical | Authorization Engine | Server-side enforcement (not client-side); all tool calls go through gateway |
| E4 | Plugin system allows arbitrary code execution | High | Plugin System (future) | Sandboxed plugin execution; restricted API surface; signed plugins only |
| E5 | Update mechanism allows installation of malicious version | Critical | Update Manager | GPG signature verification for updates; checksum validation; staged rollout |

---

## Risk Assessment Matrix

| Threat | Impact | Likelihood | Risk Level | Priority |
|--------|--------|------------|------------|----------|
| E1: Filesystem breakout | Critical | Low | High | P0 |
| E2: Docker escape | Critical | Low | High | P0 |
| E3: Auth bypass | Critical | Medium | Critical | P0 |
| E4: Plugin RCE | High | Low | Medium | P1 |
| E5: Malicious update | Critical | Low | High | P0 |
| T1: Binary tampering | Critical | Medium | Critical | P0 |
| S3: Registry spoofing | High | Low | Medium | P1 |
| I3: Sensitive file read | High | Medium | High | P1 |
| I1: Secret leakage | Critical | Medium | Critical | P0 |
| D1: Resource exhaustion | Medium | Medium | Medium | P2 |

### Risk Definitions

- **P0 (Critical):** Must be mitigated before Phase 1 deployment.
- **P1 (High):** Must be mitigated before Phase 2 deployment.
- **P2 (Medium):** Should be mitigated within 6 months of deployment.
- **P3 (Low):** Nice to have; mitigated when convenient.

---

## Mitigation Prioritization

### P0 — Must Fix Before Phase 1

| # | Threat | Mitigation | Implementation |
|---|--------|------------|----------------|
| E3 | Auth bypass | Server-side enforcement; all tool calls through gateway | Phase 1 + Phase 2 |
| T1 | Binary tampering | Checksum verification before execution | Phase 1 installer |
| I1 | Secret leakage | Secrets redaction in logs; env var sanitization | Phase 1 |
| E5 | Malicious update | GPG signature verification; checksum validation | Phase 1 updater |

### P1 — Must Fix Before Phase 2

| # | Threat | Mitigation | Implementation |
|---|--------|------------|----------------|
| E1 | Filesystem breakout | Path canonicalization; symlink prevention | Phase 1 |
| I3 | Sensitive file read | Workspace boundaries; path allowlist/denylist | Phase 1 |
| S1 | Transport MITM | TLS for all network transports | Phase 1 |
| S2 | CLI spoofing | Binary signing | Phase 2 |
| D1 | Resource exhaustion | Process resource limits; health monitoring | Phase 1 |

### P2 — Within 6 Months

| # | Threat | Mitigation | Implementation |
|---|--------|------------|----------------|
| S4 | Fake agent | API key authentication for HTTP | Phase 2 |
| R3 | User approval repudiation | Approval logging | Phase 1 |
| D3 | Log flooding | Log rotation; rate limiting | Phase 1 |
| E4 | Plugin RCE | Sandboxed execution | Phase 2+ |

---

## Security Controls Checklist

| Control | Status | Phase |
|---------|--------|-------|
| TLS for all network transports | Planned | 1 |
| GPG signing for registry | Planned | 1 |
| Checksum verification for binaries | Planned | 1 |
| Secrets encryption at rest (age) | Planned | 1 |
| Secrets redaction in logs | Planned | 1 |
| Workspace filesystem boundaries | Planned | 1 |
| Process resource limits | Planned | 1 |
| Authorization engine (multi-dimension) | Planned | 1 |
| Audit logging (all tool calls) | Planned | 1 |
| Update signature verification | Planned | 1 |
| Rollback with integrity check | Planned | 1 |
| Incident response procedures | Planned | 1 |
| API key auth for HTTP transport | Planned | 2 |
| Docker sandboxing (non-root, read-only) | Planned | 2 |
| Path canonicalization | Planned | 1 |
| Binary signing | Planned | 2 |
| OS keychain integration (future) | Planned | 2+ |

---

## Assumptions

1. The user's workstation is trusted and has up-to-date security patches.
2. Network connections to MCP servers use TLS 1.3 when possible.
3. Docker is configured with secure defaults (no privileged containers).
4. AI agents run on the same machine as the platform (no remote agent access in Phase 1).
5. The user reviews and approves high-risk tool calls when prompted.

---

## Data Flow Diagrams

### Level 0 (System Context)

```
                                ┌─────────────┐
                                │   User      │
                                └──────┬──────┘
                                       │ Commands / Approvals
                                       ▼
┌──────────┐  STDIO        ┌──────────────────────┐   HTTP/SSE    ┌──────────┐
│  Agent   │◄─────────────►│   MCP Platform       │◄─────────────►│  Remote  │
│ (Process)│               │   (CLI + CoreLib)    │               │  Server  │
└──────────┘               └──────────┬───────────┘               └──────────┘
                                       │
                          ┌────────────▼───────────┐
                          │   $MCP_HOME Store      │
                          │  (Config, Secrets,     │
                          │   Cache, Logs)         │
                          └────────────────────────┘
```

### Level 1 — Tool Call Data Flow

```
┌────────┐    1. Call Tool      ┌────────────────┐    2. Auth Request    ┌────────────┐
│ Agent  │─────────────────────►│   MCP Gateway   │─────────────────────►│  AuthZ     │
│        │                      │   (Platform)    │                      │  Engine    │
└────────┘                      └───────┬─────────┘                      └────────────┘
                                         │                                     │
                                         │ 3. Auth Decision                     │
                                         │◄─────────────────────────────────────┘
                                         │
                            ┌────────────▼──────────┐
                            │  ALLOW / DENY / APPROVE│
                            └────────────┬──────────┘
                                         │
                            ┌────────────▼──────────┐
                            │  4. Transport Layer    │
                            │  (STDIO/HTTP/SSE)      │
                            └────────────┬──────────┘
                                         │
        5. JSON-RPC Request (tools/call) │
                                         ▼
                                  ┌──────────────┐
                                  │   MCP Server  │
                                  └──────────────┘
                                         │
        6. JSON-RPC Response             │
         (tool result)                   │
                                         │
                            ┌────────────▼──────────┐
                            │  7. Audit Logger       │
                            │  (Log decision +      │
                            │   request + response)  │
                            └────────────────────────┘
                                         │
                            ┌────────────▼──────────┐
                            │  8. Return result     │
                            │     to Agent          │
                            └────────────────────────┘
```

---

## Incident Response Quick Reference

```yaml
severity_critical:
  - symptom: "Unknown process exfiltrating data"
    action: "mcp emergency stop"
    recovery: "Revoke tokens, restore from backup, audit logs"

  - symptom: "Secrets file accessed by unauthorized process"
    action: "mcp secrets rotate --all"
    recovery: "Generate new tokens, update all configs"

  - symptom: "Malicious server binary detected"
    action: "mcp server uninstall <id>"
    recovery: "Reinstall from verified source, verify checksum"

severity_high:
  - symptom: "Server crash loop (update regression)"
    action: "mcp update rollback <id>"
    recovery: "Verify health, pin version"

  - symptom: "Resource exhaustion by server"
    action: "mcp server stop <id>"
    recovery: "Review server configuration, set resource limits"

severity_medium:
  - symptom: "Permission denied too frequently"
    action: "mcp profile check"
    recovery: "Review profile permissions, adjust if needed"

  - symptom: "Health check failures"
    action: "mcp server restart <id>"
    recovery: "If persistent, investigate server logs"
```
