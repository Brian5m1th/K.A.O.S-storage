# ADR-005: Permission Model

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

MCP servers can execute powerful operations: reading/writing files, executing shell commands, making network requests, accessing databases, and managing containers. Without a robust permission model, a compromised or malicious MCP server could:

- Read or delete files outside the workspace.
- Exfiltrate secrets to external servers.
- Execute arbitrary commands on the host.
- Modify or destroy infrastructure resources.

The permission model must be:

- **Granular** — control at the agent, server, tool, and parameter level.
- **Context-aware** — evaluate risk based on agent identity, tool sensitivity, server trust, and workspace.
- **Auditable** — every permission decision is logged.
- **Override-able** — the user can approve or deny specific operations in real time.
- **Profile-driven** — different engineering profiles (backend, frontend, DevOps) have different default permissions.
- **Extensible** — support for future policy engines (e.g., OPA/Rego).

## Decision

### Multi-Dimensional Permission Model

Permission decisions are based on the combination of **six dimensions**:

```
Agent Identity
      │
      ▼
Permission Profile ──► Authorization Engine ──► Allow / Deny / Require Approval
      ▲                              ▲
      │                              │
Tool Risk Level ───────────── Server Trust Level
      │                              │
      ▼                              ▼
Workspace Context ────────── Approval Policy
```

### Authorization Engine

The authorization engine evaluates every tool call against the permission matrix:

```python
class AuthorizationEngine:
    def authorize(
        self,
        agent_id: str,
        server_id: str,
        tool_name: str,
        tool_args: dict,
        workspace: str,
    ) -> AuthorizationDecision:
        # 1. Load permission profile for the agent
        profile = self.profile_registry.get_profile_for_agent(agent_id)

        # 2. Evaluate server trust level
        server_trust = self.trust_registry.get_trust_level(server_id)

        # 3. Evaluate tool risk level
        tool_risk = self.risk_registry.get_tool_risk(server_id, tool_name)

        # 4. Check workspace boundaries
        workspace_check = self.workspace_checker.validate(workspace, tool_args)

        # 5. Apply approval policy
        if profile.requires_approval(server_id, tool_name, tool_args):
            return AuthorizationDecision.PENDING_APPROVAL

        # 6. Final decision
        if profile.allows(server_id, tool_name):
            if server_trust == "high" and tool_risk == "low":
                return AuthorizationDecision.ALLOW
            elif server_trust == "low" or tool_risk == "high":
                if profile.requires_approval_for_high_risk:
                    return AuthorizationDecision.PENDING_APPROVAL
                return AuthorizationDecision.DENY

        return AuthorizationDecision.DENY
```

### Dimension 1: Agent Identity

Each agent has a unique identity and belongs to one or more profiles:

| Agent | Default Profile | Trust Level |
|-------|----------------|-------------|
| Claude Code | full-stack | trusted |
| OpenCode | full-stack | trusted |
| Antigravity | full-stack | trusted |
| Cursor | full-stack | trusted |
| VS Code AI | full-stack | trusted |
| Custom Agent | restricted | untrusted |

### Dimension 2: Permission Profile

Profiles define which servers and tools an agent can access:

```yaml
# $MCP_HOME/profiles/backend.yaml
name: "Backend Engineering"
allowed_servers:
  - id: context7
    tools: "*"                                          # All tools allowed
  - id: github
    tools: "*"
  - id: postgres
    tools: "*"
  - id: docker
    tools:                                              # Whitelist specific tools
      - docker_list_containers
      - docker_logs
      - docker_compose_ps
    denied_tools:
      - docker_destroy                                  # Never allow
  - id: filesystem
    workspace_bound: true                               # Restricted to workspace
    allowed_paths:
      - "{{workspace}}/**"
    denied_paths:
      - "{{workspace}}/.git/**"
      - "{{workspace}}/node_modules/**"
  - id: sequential-thinking
    tools: "*"
```

### Dimension 3: Tool Risk Level

Each tool is classified by risk:

| Risk Level | Description | Example Tools | Default Action |
|------------|-------------|---------------|----------------|
| **none** | No side effects | `sequential_thinking`, `filesystem_search` | Allow |
| **low** | Read-only, safe | `github_list_issues`, `postgres_query` (SELECT) | Allow |
| **medium** | Write operations, config changes | `github_create_pr`, `filesystem_write` | Allow (if profile allows) |
| **high** | Destructive operations | `docker_rm`, `filesystem_delete`, `postgres_drop_table` | Require approval |
| **critical** | Security-sensitive | `docker_destroy_all`, `shell_exec` | Deny by default |

### Dimension 4: Server Trust Level

| Trust Level | Description | Examples | Policy |
|-------------|-------------|----------|--------|
| **high** | Well-known, audited, official | Context7, GitHub, Filesystem | All tools allowed per profile |
| **medium** | Community-maintained, stable | Serena, n8n | Read-only tools allowed; write requires approval |
| **low** | Experimental, unverified | Custom scripts, unknown sources | Deny by default; explicit approval required |
| **untrusted** | Known security risks | None | Always deny |

### Dimension 5: Workspace Boundaries

For filesystem-related tools, operations are scoped to the current workspace:

```yaml
# Workspace boundary configuration
workspace_boundaries:
  allowed_directories:
    - "{{workspace}}"                                   # Current project directory
    - "{{workspace}}/../shared"                         # Adjacent shared directory
    - "{{mcp_home}}"                                    # Platform config directory
  denied_directories:
    - "/etc"
    - "/usr"
    - "/sys"
    - "/proc"
    - "~/.ssh"
    - "{{workspace}}/.git"
```

### Dimension 6: Approval Policy

Three levels of approval:

| Level | Behavior | Use Case |
|-------|----------|----------|
| **auto** | Automatically allowed | Low-risk, trusted server, known tool |
| **confirm** | User must confirm via UI/CLI | Medium-risk, first-time tool call, high-risk tool |
| **deny** | Never allowed | Critical risk, untrusted server |

### Audit Logging

Every authorization decision is logged:

```yaml
# $MCP_HOME/logs/authorization.log
timestamp: "2026-07-12T14:30:00Z"
decision_id: "auth_d2f4a1b8"
agent_id: "opencode"
server_id: "docker"
tool_name: "docker_list_containers"
tool_args: {}
workspace: "/home/user/projects/kaos"
decision: ALLOW
dimensions:
  profile: "backend"
  server_trust: "high"
  tool_risk: "low"
  workspace_bound: true
```

### Override Mechanism

The user can override a permission decision in real time:

1. **CLI prompt**: `Allow <agent> to call <tool> on <server> with <args>? [y/n/a/d]`
2. **Desktop UI**: Approval dialog with server, tool, args, and risk level.
3. **Config override**: Pre-approved rules in `config.yaml`:

```yaml
# $MCP_HOME/config.yaml
permission_overrides:
  - agent: "opencode"
    server: "docker"
    tool: "docker_restart"
    decision: "allow"
    reason: "Development requires restarting containers"
```

## Evidence Supporting This Decision

1. The existing K.A.O.S permission system in the codebase is minimal (no multi-dimensional evaluation).
2. Docker MCP servers can execute destructive commands — without permission control, a single prompt injection could destroy infrastructure.
3. The Filesystem MCP server requires explicit path boundaries to prevent reading sensitive files.
4. Industry practices (OPA, AWS IAM, Kubernetes RBAC) demonstrate that multi-dimensional authorization is more secure than simple role-based access.

## Consequences

### Positive

- Fine-grained control over every tool call.
- Safe by default — high-risk tools require explicit approval.
- Audit trail for every authorization decision.
- Flexible — policies can evolve without code changes.
- Workspace isolation prevents accidental modification outside the project.

### Negative

- Increased complexity in the authorization engine.
- Approval prompts can interrupt workflow (mitigated by persistent overrides).

### Risks & Mitigations

- **Risk:** Users approve dangerous operations out of convenience → **Mitigation:** High-risk tools always require confirmation, even if previously approved.
- **Risk:** Permission config becomes complex → **Mitigation:** Sensible defaults for each profile; most users never need to customize.

## Implementation Plan

1. Define `AuthorizationDecision` enum and `AuthorizationEngine` interface.
2. Implement permission profile schema and loading.
3. Implement tool risk classification.
4. Implement server trust level evaluation.
5. Implement workspace boundary validation.
6. Implement approval policy (auto + confirm + deny levels).
7. Implement audit logging.
8. Integrate with the MCP Gateway (Phase 2).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Role-based only (RBAC) | Simple | Cannot distinguish between read/write/destroy | Must support fine-grained control |
| Allow all (no permissions) | Simple | Extremely insecure | Insecure by default |
| OPA/Rego | Powerful, standardized | Overkill for initial version; can be added later | Start with custom engine; OPA integration is future work |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
