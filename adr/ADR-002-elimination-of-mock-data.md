# ADR-002: Elimination of Mock/Simulated Data

**Status**: Accepted  
**Date**: 2026-07-11  
**Decision Maker**: KAOS Architect  

## Context

The K.A.O.S Desktop application contained multiple sources of fabricated runtime data in production code:

| Location | Mock Pattern | Type |
|---|---|---|
| `dashboard/index.tsx` | `fallbackAlerts` (3 hardcoded notifications) | UI alerts |
| `dashboard/index.tsx` | `sysLogs` initial seed (5 fake log lines) | System logs |
| `dashboard/index.tsx` | `agents` initial seed (3 hardcoded agents) | Agent status |
| `observability/index.tsx` | `simulatedLogs` initial seed (5 fake log lines) | System logs |
| `observability/index.tsx` | Static `alerts` array (never updated from backend) | Alerts |
| `agents/index.tsx` | `DEFAULT_AGENTS` fallback (3 hardcoded agents) | Agent config |
| `automation-studio.tsx` | `INITIAL_NODES`/`INITIAL_EDGES` (5 nodes + 4 edges) | Workflow graph |
| `integrations.py` | `mock_fallback` CI runs (3 hardcoded runs) | GitHub data |
| `integrations.py` | Simulated trigger success | API response |
| `system.py` | Simulated VRAM (`ram_used * 0.45`) | System metrics |

## Decision

**Zero tolerance for fabricated runtime data in production code.** All mock data must be eliminated. When backend data is unavailable:

- **Loading** (during query state): Show spinner/skeleton
- **Offline** (backend unreachable): Show full-screen offline overlay
- **Unknown / No Data** (values uninitialized/empty): Show "Unknown", "—", or "Nenhum alerta ativo"
- **Error** (with detailed messages): Show error state

### VRAM Specific Rule

When no Nvidia or AMD GPU is detected:
- Backend returns `vram: { used: null, total: null }`
- Frontend displays `VRAM: CPU Mode`
- Never output fake allocations like `1.0 / 16GB`

## Consequences

- **Positive**: Users always see truthful data. No confusion between real and simulated metrics.
- **Positive**: Production behavior is deterministic — same UI states whether backend is empty, loading, or offline.
- **Negative**: Some screens may show empty states more frequently (e.g., automation studio without workflows, agents page without backend agents).
- **Mitigation**: CI script `verify-no-mocks.ps1` runs on build to prevent mock data regression.
