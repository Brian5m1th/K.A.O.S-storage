# ADR-006: Profile System Design

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

Different engineering workflows require different sets of MCP servers. A backend developer needs PostgreSQL and Docker but may never use Playwright. A frontend developer needs Playwright and Context7 but may never use Terraform.

Without profiles, users would:

1. Install all available servers — wasting resources and increasing attack surface.
2. Manually enable/disable servers when switching contexts.
3. Have a cluttered tool registry that degrades AI agent performance (too many tools = worse quality).

A profile system solves this by grouping servers into logical workflow bundles that can be activated on demand.

## Decision

### Profile Definition

Profiles are YAML files in `$MCP_HOME/profiles/`:

```yaml
# $MCP_HOME/profiles/ai-llm.yaml
name: "AI / LLM Engineering"
description: "Servers relevant for AI model development, RAG, and LLM engineering"
icon: "brain"
priority: 50                                                    # Higher = more preferred when multiple profiles match

enabled_servers:
  - id: context7
    tools: "*"
  - id: serena
    tools: "*"
  - id: github
    tools: "*"
  - id: filesystem
    workspace_bound: true
  - id: sequential-thinking
    tools: "*"
  - id: memory
    tools: "*"
  - id: fetch
    tools: "*"
  - id: qdrant
    tools: "*"
  - id: postgres
    tools:
      - postgres_list_tables
      - postgres_describe_table
      - postgres_query

disabled_servers: []

agent_config_overrides:
  max_tools_per_server: 5
  max_total_tools: 30
```

### Profile Catalog (Initial)

| Profile ID | Name | Focus | Count | Core Servers |
|------------|------|-------|-------|-------------|
| `backend` | Backend Engineering | Server-side, APIs, databases | 8 | Context7, GitHub, PostgreSQL, Docker, Sequential Thinking, Filesystem, Fetch, Memory |
| `frontend` | Frontend Engineering | UI, browser, design systems | 7 | Context7, GitHub, Playwright, Filesystem, Sequential Thinking, Fetch, Memory |
| `devops` | Infrastructure & DevOps | Cloud, containers, monitoring | 9 | GitHub, Docker, Terraform, Kubernetes, Cloudflare, AWS, Prometheus, Grafana, Sequential Thinking |
| `ai-llm` | AI / LLM Engineering | Models, RAG, embeddings | 9 | Context7, Serena, GitHub, Qdrant, Sequential Thinking, Memory, Fetch, PostgreSQL, Filesystem |
| `security` | Security Engineering | Audits, compliance, scanning | 5 | GitHub, Filesystem, Sequential Thinking, Docker, Fetch |
| `documentation` | Documentation / Technical Writing | Docs, knowledge management | 5 | Context7, Filesystem, Obsidian, GitHub, Memory |
| `data-engineering` | Data Engineering | Pipelines, ETL, analytics | 6 | PostgreSQL, Docker, GitHub, Qdrant, Fetch, Filesystem |
| `full-stack` | Full Stack (default) | All disciplines | 12 | All servers with sensible limits |
| `minimal` | Minimal / Lightweight | Quick coding sessions | 3 | Filesystem, GitHub, Sequential Thinking |

### Profile Activation

Profiles can be activated in multiple ways (priority order):

1. **Environment variable**: `MCP_PROFILE=backend mcp start`
2. **Workspace detection**: Auto-detect based on project type (e.g., `package.json` → frontend profile)
3. **Manual switch**: `mcp profile set backend`
4. **CLI flag**: `mcp start --profile backend`
5. **Editor integration**: VS Code picks profile based on workspace

### Auto-Detection Rules

```yaml
# $MCP_HOME/config.yaml
profile_auto_detection:
  enabled: true
  rules:
    - match: "**/Cargo.toml"
      profile: "backend"
    - match: "**/package.json"
      profile: "frontend"
    - match: "**/pyproject.toml"
      profile: "ai-llm"
    - match: "**/Dockerfile"
      profile: "devops"
    - match: "**/docker-compose.yml"
      profile: "devops"
    - match: "**/*.tf"
      profile: "devops"
    - match: "**/*.md"
      profile: "documentation"
```

### Profile Merging

Multiple profiles can be active simultaneously. The merge strategy:

1. Start with `minimal` as base.
2. Apply all matched/selected profiles in priority order.
3. Later profiles override earlier profiles on conflicts.
4. `disabled_servers` always takes precedence over `enabled_servers`.

### Active Profile State

The current active profile set is stored in:

```yaml
# $MCP_HOME/active_profile.yaml
active_profiles:
  - backend
  - ai-llm
workspace: "/home/user/projects/kaos"
activated_at: "2026-07-12T14:30:00Z"
auto_detected: true
```

## Evidence Supporting This Decision

1. The user's original specification lists 7 distinct engineering profiles.
2. AI agent performance degrades with too many tools — limiting tools per profile improves response quality.
3. Workspace auto-detection reduces friction — no manual switching needed.

## Consequences

### Positive

- Servers are only loaded when relevant — reducing memory and startup time.
- AI agents receive a focused tool set, improving response quality.
- Security surface is reduced — dangerous servers are only available in the appropriate profile.
- Profiles are version-controllable — shareable across machines.

### Negative

- Profile maintenance overhead — each profile must be kept up-to-date.
- Auto-detection may not match user intent in all cases (mitigated by explicit override).

### Risks & Mitigations

- **Risk:** User forgets to switch profile → **Mitigation:** Auto-detection handles most cases; fallback to full-stack profile.
- **Risk:** Profile definitions become stale → **Mitigation:** `mcp profile check` validates all servers in a profile are still functional.

## Implementation Plan

1. Define profile schema and validation.
2. Implement profile loading and merging.
3. Implement workspace auto-detection.
4. Implement `mcp profile list`, `mcp profile set`, `mcp profile current` commands.
5. Integrate profiles with server initialization (only start servers in active profile).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Single global config | Simple | One-size-fits-all, cluttered | Profiles are essential for focus |
| Per-project config only | Flexible | Duplication across projects | Profiles provide logical grouping without duplication |
| No auto-detection | Simple, predictable | Manual switching required | Auto-detection reduces friction |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
