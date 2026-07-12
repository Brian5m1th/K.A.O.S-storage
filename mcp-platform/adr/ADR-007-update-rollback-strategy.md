# ADR-007: Update & Rollback Strategy

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

MCP servers are external software that evolves independently. New versions may:

- Add or remove tools.
- Change tool signatures or behavior.
- Fix security vulnerabilities or introduce new ones.
- Break API compatibility.
- Deprecate in favor of alternative servers.

Without a structured update system:

- Users may miss critical security patches.
- Breaking changes can silently break workflows.
- There is no way to revert a bad update.
- Compatibility between servers and agents is not validated.

## Decision

### Update Architecture

```
┌────────────────────────────────────────────────────────────┐
│                     Update Manager                           │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Version       │  │ Compatibility│  │ Backup &          │   │
│  │ Checker      │  │ Validator   │  │ Rollback Engine   │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                 │                    │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌────────▼─────────┐   │
│  │ Registry     │  │ Agent Config │  │ Snapshot         │   │
│  │ Updater      │  │ Verifier    │  │ Manager          │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### Version Tracking

The registry tracks the **current known stable version** for each server:

```yaml
# registry.yaml
servers:
  - id: github
    name: "GitHub MCP"
    version: "1.5.2"                     # Current installed/known version
    latest_version: "1.6.0"              # Latest available version (detected by update check)
    auto_update: true                     # Allow automatic minor/patch updates
    update_policy: "minor"                # "major" | "minor" | "patch" | "none"
    changelog_url: "https://github.com/modelcontextprotocol/server-github/releases"
    backup_before_update: true
```

### Update Commands

```bash
# Check all servers for updates
mcp update check

# Check specific server
mcp update check github

# Apply all pending updates
mcp update apply

# Apply specific server update
mcp update apply github

# List update history
mcp update history

# Rollback the last update
mcp update rollback github

# Rollback to a specific version
mcp update rollback github --version 1.5.2
```

### Update Strategies

| Strategy | Scope | Behavior | When to Use |
|----------|-------|----------|-------------|
| **patch** | `x.y.Z` | Auto-apply without confirmation | Bug fixes, security patches |
| **minor** | `x.Y.z` | Auto-apply; notify after | New features, non-breaking changes |
| **major** | `X.y.z` | Require explicit confirmation | Breaking changes, new major version |
| **manual** | — | Never auto-update; user must trigger | Servers requiring careful validation |
| **pinned** | — | Never update; version is locked | Servers with incompatible dependencies |

### Compatibility Validation

Before applying any update, the system validates compatibility:

```yaml
# Validation steps
validation_steps:
  - step: registry_schema_check
    description: "Verify registry.yaml schema is compatible"

  - step: agent_config_generation
    description: "Generate agent configs with new server version"

  - step: tool_list_check
    description: "Verify tools/list returns expected structure"

  - step: known_tools_check
    description: "Verify previously known tools still exist"

  - step: health_check
    description: "Verify server starts and passes health check"

  - step: benchmark_run
    description: "Verify performance metrics within acceptable range"
```

### Backup System

Before any update, a snapshot is created:

```yaml
# $MCP_HOME/backups/manifest.yaml
backups:
  - id: "bk_20260712_143000"
    date: "2026-07-12T14:30:00Z"
    server: "github"
    from_version: "1.5.2"
    to_version: "1.6.0"
    files:
      - "servers/github.yaml"
      - "cache/tools/github_1.5.2.json"
    checksum: "sha256:a1b2c3d4..."
    status: completed                                               # completed | failed | rolled_back
```

### Rollback Process

```python
async def rollback(server_id: str, target_version: str | None = None):
    # 1. Find the backup snapshot
    backup = find_backup(server_id, target_version)

    # 2. Stop the current server
    await stop_server(server_id)

    # 3. Restore configuration files
    for file_path in backup.files:
        restore_file(file_path, backup.id)

    # 4. Reinstall the previous version
    await install_server(server_id, backup.from_version)

    # 5. Restart and verify
    await start_server(server_id)
    health = await health_check(server_id)
    if health.status != "healthy":
        # If rollback fails, attempt to restore the NEW version
        await restore_new_version(server_id, backup)
        raise RollbackError("Rollback failed, restored to pre-rollback version")

    # 6. Mark rollback in history
    record_rollback(server_id, backup)
```

### Disaster Recovery

For catastrophic failures (server won't start, config corrupted):

```yaml
# $MCP_HOME/disaster-recovery.yaml
recovery_procedures:
  - scenario: "server_wont_start"
    steps:
      - "mcp update rollback <server> --force"
      - "mcp server reset <server> --factory-defaults"
      - "mcp server reinstall <server>"

  - scenario: "registry_corrupted"
    steps:
      - "mcp registry restore --latest-backup"
      - "mcp registry restore --version 1.0"

  - scenario: "all_servers_down"
    steps:
      - "mcp emergency stop"
      - "mcp emergency restore --last-known-good"
      - "mcp start --safe-mode"
```

### Update Notifications

The user is notified of updates via:

1. **CLI prompt** on next command: `Updates available: github (1.6.0), postgres (2.1.0). Run 'mcp update check' for details.`
2. **Desktop notification** (Phase 2) in the K.A.O.S Desktop UI.
3. **Scheduled check** — daily automatic version check (configurable interval).

## Evidence Supporting This Decision

1. The user explicitly requested: "update manager capable of detecting new versions, validating compatibility, creating backups, and rolling back failed updates."
2. The registry schema (ADR-003) already includes version tracking fields.
3. Industry standard practice for package managers (apt, npm, pip, brew) — all support update, rollback, and backup.

## Consequences

### Positive

- Safe, reversible updates — no fear of breaking changes.
- Automatic security patches with zero user intervention.
- Full audit trail of all version changes.
- Disaster recovery procedures for worst-case scenarios.

### Negative

- Backup storage consumes disk space.
- Compatibility validation adds time to each update.

### Risks & Mitigations

- **Risk:** Rollback fails → **Mitigation:** Two-phase rollback (restore target → verify → if failed, restore original).
- **Risk:** Backup storage grows unbounded → **Mitigation:** Keep only last 3 snapshots per server; `mcp update prune` command.

## Implementation Plan

1. Implement version tracking in registry.
2. Implement update check (query package registries for latest versions).
3. Implement compatibility validation steps.
4. Implement backup/restore module.
5. Implement rollback logic.
6. Implement `mcp update` CLI commands.
7. Implement scheduled update check.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Manual updates only | Simple | No automation, user must track versions | Automation is essential for security |
| Reinstall from scratch on update | Simple | No version history, no rollback | Rollback must be supported |
| Git-based version control of config | Free versioning | Does not handle binary server versions | Registry-based is more explicit |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
