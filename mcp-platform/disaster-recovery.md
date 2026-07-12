# Disaster Recovery Procedures — Personal AI Engineering Platform (MCP)

## Emergency Stop

```bash
# Immediately stop ALL MCP server processes
mcp emergency stop

# Restart in safe mode (only core servers: filesystem)
mcp start --safe-mode

# Full restart
mcp start
```

## Recovery Scenarios

### Scenario 1: Server Won't Start After Update

```yaml
symptoms:
  - Server process exits immediately after start
  - Health check times out
  - Error logs indicate dependency issue

steps:
  1. "mcp update rollback <server> --force"
  2. "mcp server start <server>"
  3. "mcp server logs <server>"           # Verify health
  4. If still failing: "mcp server reinstall <server> --version <last-known-good>"

rollback_if_failed:
  - Restore from backup snapshot
  - Notify user of incompatible version
```

### Scenario 2: Registry Corrupted

```yaml
symptoms:
  - "mcp registry list" returns errors
  - Schema validation fails
  - Missing server entries

steps:
  1. "mcp registry restore --latest-backup"
  2. "mcp registry validate"
  3. If backup unavailable: "mcp registry restore --default"

prevention:
  - Version-controlled registry.yaml (recommended)
  - Daily automated backups
  - Schema validation before every write
```

### Scenario 3: Secrets Compromised

```yaml
symptoms:
  - Unauthorized API calls detected
  - Token leaked in logs or error messages
  - Suspicious activity on GitHub/Cloudflare/etc.

steps:
  1. "mcp secrets rotate --all"
  2. Revoke compromised tokens at their source (GitHub, Cloudflare, etc.)
  3. "mcp secrets verify"                # Check all secrets resolve correctly
  4. "mcp server restart --all"           # Restart servers with new tokens

prevention:
  - Secrets never stored in plaintext
  - Environment variables preferred
  - Encrypted file storage with strict permissions (600)
```

### Scenario 4: All Servers Down (Platform Failure)

```yaml
symptoms:
  - "mcp" command fails or returns errors
  - No servers respond
  - Configuration files missing or corrupted

steps:
  1. "mcp emergency restore --last-known-good"
  2. "mcp start --safe-mode"
  3. "mcp health check --all"
  4. "mcp server start --all --sequential"

if_not_resolved:
  - Reinstall platform from backup
  - Restore $MCP_HOME from version control
  - Run "mcp install --all --force"
```

### Scenario 5: File System Boundary Violation

```yaml
symptoms:
  - Files modified outside workspace
  - Sensitive files accessed by MCP server
  - /etc, ~/.ssh, .git contents exposed in tool results

steps:
  1. "mcp server stop filesystem"
  2. Check for unauthorized modifications: "audit trail"
  3. Review filesystem boundary configuration
  4. If compromised: "Revoke tokens, rotate secrets"
  5. "mcp server start filesystem --with-safe-paths"

prevention:
  - Workspace boundaries configuration
  - Path allowlist/denylist
  - Symlink attack prevention
```

## Recovery Commands Reference

| Command | Description |
|---------|-------------|
| `mcp emergency stop` | Immediately stop all servers |
| `mcp emergency restore <snapshot>` | Restore platform from backup snapshot |
| `mcp start --safe-mode` | Start only core/filesystem servers |
| `mcp update rollback <server> --force` | Force rollback without validation |
| `mcp server reinstall <server> --version X.Y.Z` | Reinstall specific version |
| `mcp secrets rotate --all` | Regenerate all secret references |
| `mcp secrets verify` | Check all secrets resolve correctly |
| `mcp registry restore --latest-backup` | Restore registry from backup |
| `mcp registry validate` | Validate registry schema |
| `mcp server reset <server> --factory-defaults` | Factory reset server config |

## Contact

If recovery procedures fail, escalate to the platform owner.
