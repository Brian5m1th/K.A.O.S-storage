# ADR-003: MCP Registry Schema

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

The MCP Platform needs a **central, versioned catalog** of all known MCP servers. This catalog serves as the single source of truth for:

- Which servers exist and where to find them.
- What permissions and risks each server requires.
- Which agents and platforms each server supports.
- How to install, update, and configure each server.

Without a schema, server metadata would be scattered across multiple config files, READMEs, and scripts — making it impossible to automate installation, health checks, updates, and compatibility validation.

## Decision

### Registry File Format

The registry lives at `$MCP_HOME/registry.yaml` in YAML format (human-readable, diffable, version-controllable).

### Schema (Version 1.0)

```yaml
# registry.yaml — MCP Server Catalog
registry_version: "1.0"
updated: "2026-07-12"

servers:
  - id: context7                                            # Unique identifier
    name: "Context7"                                         # Human-readable name
    version: "1.2.0"                                         # Current known stable version
    category: documentation                                  # Category grouping
    description: "Live documentation for frameworks and libraries, eliminating outdated examples"

    maintainer:                                              # Source information
      name: "Context7 Inc."
      url: "https://context7.com"
      github: "context7/mcp-server"

    license: "MIT"
    maturity: stable                                         # experimental | stable | deprecated

    protocol:                                                # Transport information
      default: stdio
      transports:
        - type: stdio
          command: "npx"
          args: ["-y", "@context7/mcp-server"]
          env: {}
        - type: docker                                       # Optional containerized version
          image: "ghcr.io/context7/mcp-server:latest"
          tag: "latest"
          ports: []

    permissions:                                             # Security model
      filesystem: none                                       # none | read | write | full
      network: https-outbound                                # none | https-outbound | full
      shell: false
      secrets: []                                            # List of required secret keys
      risks:
        - level: low
          description: "Network egress to context7.com for documentation fetching"

    requirements:                                            # Prerequisites
      node: ">=18"
      npm: true
      python: null
      docker: false

    agents: [claude-code, opencode, antigravity, cursor, vscode]
    platforms: [linux, macos, windows, wsl]

    tags: [docs, api, frameworks, hallucination-reduction]

    install:
      method: npx                                            # npx | uvx | pip | npm | docker | binary
      command: "npx @context7/mcp-server@1.2.0"
      auto_update: true
      backup_before_update: true

    health:
      check_method: tools/list                               # How to verify the server is working
      expected_startup_ms: 8000
      expected_latency_ms: 500
      expected_ram_mb: 100

    benchmark:
      startup_ms: 800
      ram_mb: 45
      latency_ms: 120
      stability: 0.99                                        # Uptime ratio (0-1)

    config_template:
      command: "npx"
      args: ["-y", "@context7/mcp-server"]
      env:
        CONTEXT7_API_KEY: "${secrets.context7.api_key}"
```

### Categories

| Category | Description | Example Servers |
|----------|-------------|-----------------|
| `documentation` | Live docs, API references | Context7 |
| `code-understanding` | Semantic code analysis | Serena |
| `source-control` | Git, GitHub, GitLab | GitHub, Git |
| `browser-automation` | UI testing, screenshots | Playwright |
| `filesystem` | File read/write/search | Filesystem |
| `reasoning` | Structured thinking, planning | Sequential Thinking |
| `database` | SQL, schema, migrations | PostgreSQL, MySQL, SQLite, MongoDB |
| `container` | Docker, Kubernetes | Docker |
| `cloud-infrastructure` | Cloud providers, IaC | Cloudflare, Terraform, AWS, Azure, GCP |
| `knowledge-management` | Notes, vectors, RAG | Obsidian, Qdrant |
| `automation` | Workflows, CI/CD | n8n, GitHub Actions |
| `web-research` | Web fetching, search | Fetch, Tavily |
| `memory` | Persistent agent memory | Memory |
| `observability` | Monitoring, logging, tracing | Prometheus, Grafana, Loki |
| `custom` | K.A.O.S-specific servers | Graphify, KIRL, kaos-n8n, kaos-obsidian |

### Profile Definitions

Profiles are defined in `$MCP_HOME/profiles/<name>.yaml`:

```yaml
# $MCP_HOME/profiles/backend.yaml
name: "Backend Engineering"
description: "Servers relevant for backend development"
enabled_servers:
  - context7
  - github
  - postgres
  - docker
  - sequential-thinking
  - filesystem
  - fetch
  - memory
disabled_servers: []
agent_config:
  claude-code:
    max_tools: 30
  opencode:
    max_tools: 25
```

### Profile Catalog

| Profile | Focus | Default Servers |
|---------|-------|-----------------|
| `backend` | Backend development | Context7, GitHub, PostgreSQL, Docker, Sequential Thinking, Filesystem, Fetch, Memory |
| `frontend` | Frontend/UI development | Context7, GitHub, Playwright, Filesystem, Sequential Thinking, Fetch, Memory |
| `devops` | Infrastructure & DevOps | GitHub, Docker, Terraform, Kubernetes, Cloudflare, Prometheus, Grafana |
| `ai-llm` | AI/LLM engineering | Context7, Serena, GitHub, Qdrant, Sequential Thinking, Memory, Fetch |
| `security` | Security auditing | GitHub, Filesystem, Sequential Thinking, Docker |
| `documentation` | Technical writing | Context7, Filesystem, Obsidian, GitHub, Memory |
| `data-engineering` | Data pipelines | PostgreSQL, Docker, GitHub, Qdrant, Fetch |

## Evidence Supporting This Decision

1. YAML is the de facto standard for configuration in the MCP ecosystem (Claude Code, OpenCode, VS Code MCP).
2. A versioned registry enables deterministic, reproducible installations.
3. Explicit permission declarations enable automated security reviews.

## Consequences

### Positive

- Fully automated installation from a single catalog.
- Compatibility validation before installation.
- Automated health checks with known baselines.
- Clear upgrade path with version tracking.

### Negative

- Registry must be kept up-to-date with each server release.
- Schema evolution requires version migration.

### Risks & Mitigations

- **Risk:** Registry becomes stale → **Mitigation:** `mcp update` command detects new server versions and updates registry.
- **Risk:** Schema changes break compatibility → **Mitigation:** Use `registry_version` field for migration support.

## Implementation Plan

1. Implement `registry.yaml` schema validation (JSON Schema or YAML Schema).
2. Create initial catalog with all Tier 1 servers.
3. Implement `mcp registry list`, `mcp registry search`, `mcp registry info <server>` commands.
4. Implement `mcp registry update` to refresh version information.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| JSON instead of YAML | Strict validation | Less human-readable for diffs | YAML is preferred for config |
| Database-backed registry | Queryable | Requires DB dependency, harder to version-control | File-based is simpler and version-controllable |
| No registry (manual config) | Simple | Error-prone, not reproducible | Automation is essential |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
