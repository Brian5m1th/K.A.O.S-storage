# ADR-002: Global Configuration Hierarchy

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

MCP server configuration must be accessible from multiple projects and multiple AI agents. The configuration system needs to support:

1. **Global defaults** — servers available in every project.
2. **Per-project overrides** — project-specific servers or settings.
3. **Profile-based selection** — only enable servers relevant to the current workflow (backend, frontend, DevOps, etc.).
4. **Agent-specific output** — generate `claude.json`, `opencode.json`, VS Code settings, etc., from a single source of truth.
5. **Overridability** — the user must be able to override the config directory via an environment variable.

The configuration must live in OS-standard locations — never in a custom/proprietary path.

## Decision

### Directory Layout

The platform root directory follows the OS convention:

| Platform | Default Path | Environment Variable |
|----------|-------------|---------------------|
| Linux | `~/.config/mcp/` | `MCP_HOME` |
| macOS | `~/Library/Application Support/mcp/` | `MCP_HOME` |
| Windows | `%APPDATA%\mcp\` | `MCP_HOME` |
| WSL | `~/.config/mcp/` | `MCP_HOME` |

The `MCP_HOME` environment variable can override the default path entirely.

### Directory Structure

```
$MCP_HOME/
├── registry.yaml              # Master catalog of all known MCP servers
├── config.yaml                # User configuration (enabled servers, profiles, preferences)
├── profiles/                  # Development profiles
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── devops.yaml
│   ├── ai-llm.yaml
│   ├── security.yaml
│   ├── documentation.yaml
│   └── data-engineering.yaml
├── servers/                   # Per-server runtime configuration
│   ├── context7.yaml
│   ├── serena.yaml
│   ├── github.yaml
│   └── ...
├── secrets/                   # Secret references (never values)
│   ├── github.yaml
│   ├── postgres.yaml
│   └── ...
├── cache/                     # Cached tool lists, schemas, health data
│   ├── tools/
│   ├── schemas/
│   └── health/
├── logs/                      # Server and platform logs
│   ├── servers/
│   └── platform/
├── downloads/                 # Downloaded server binaries
├── templates/                 # Configuration templates for AI agents
│   ├── claude.json.tmpl
│   ├── opencode.json.tmpl
│   ├── vscode.json.tmpl
│   └── antigravity.json.tmpl
└── installers/                # Installation scripts
    ├── install.ps1
    └── install.sh
```

### Configuration Resolution Order

When resolving a configuration value, the following priority applies (highest to lowest):

1. **Environment variable** (`MCP_HOME`)
2. **Per-project local config** (`$PROJECT_ROOT/.mcp/config.yaml`) — optional
3. **Active profile** (`$MCP_HOME/profiles/<active>.yaml`)
4. **Global user config** (`$MCP_HOME/config.yaml`)
5. **Platform defaults** (compiled into the tool)

### Secrets Management

Secrets are **never** stored in configuration files. Instead, configuration files reference secrets by name:

```yaml
servers:
  - id: github
    name: "GitHub MCP"
    env:
      GITHUB_TOKEN: "${secrets.github.token}"
```

The secret values are resolved from:

1. Environment variables (checked first)
2. `$MCP_HOME/secrets/<name>.yaml` (encrypted at rest, optional)
3. OS keyring (future)
4. Interactive prompt (fallback)

### Agent Configuration Generation

All AI agent configurations are **generated** from the single source of truth at `$MCP_HOME/config.yaml`. The generators are:

| Agent | Config File | Generator Command |
|-------|-------------|------------------|
| Claude Code | `~/.claude.json` | `mcp generate claude-code` |
| OpenCode | `$PROJECT_ROOT/.opencode.json` | `mcp generate opencode` |
| VS Code MCP | `$VSCODE_HOME/User/settings.json` | `mcp generate vscode` |
| Antigravity | `$HOME/.antigravity/config/mcp.json` | `mcp generate antigravity` |
| Cursor | `$HOME/.cursor/mcp.json` | `mcp generate cursor` |

## Evidence Supporting This Decision

1. XDG Base Directory Specification (`.config/`) is the Linux standard.
2. Apple's File System Basics recommends `~/Library/Application Support/`.
3. Windows `%APPDATA%` is the standard for application data.
4. Using `MCP_HOME` as override variable follows the pattern of other tools (Docker's `DOCKER_CONFIG`, Kubernetes' `KUBECONFIG`, VS Code's `VSCODE_HOME`).

## Consequences

### Positive

- OS-standard locations — no surprise to users.
- Single source of truth — all agents consume the same config.
- Secret values never leak into config files.
- Per-project overrides allow project-specific customization without breaking global setup.
- Version-controllable — the entire `$MCP_HOME` can be a dotfiles repo.

### Negative

- Slightly more complex resolution chain.
- Templates must be maintained for each supported agent.

### Risks & Mitigations

- **Risk:** Breaking changes to template format → **Mitigation:** Version templates alongside `registry.yaml`.
- **Risk:** User edits generated agent config directly → **Mitigation:** Generated files contain a header: `# DO NOT EDIT — Generated by MCP Platform. Edit $MCP_HOME/config.yaml instead.`

## Implementation Plan

1. Implement `$MCP_HOME` resolution logic in the platform CLI.
2. Create default `config.yaml` and `registry.yaml` files on first run.
3. Implement configuration resolution (priority chain).
4. Implement secret resolution (env var → file → keyring → prompt).
5. Implement agent config generators.
6. Document the hierarchy and resolution rules.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Single fixed path (e.g., `~/.mcp/`) | Simple | Proprietary, violates OS conventions | Must follow OS standards |
| No per-project override | Simple | Cannot customize per project | Per-project flexibility is essential |
| Store secrets in plaintext config | Simple | Security risk | Secrets must never be stored in config |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
