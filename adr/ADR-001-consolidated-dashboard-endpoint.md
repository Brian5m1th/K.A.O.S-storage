# ADR-001: Consolidated Dashboard Endpoint

**Status**: Accepted  
**Date**: 2026-07-11  
**Decision Maker**: KAOS Architect  

## Context

The K.A.O.S Desktop dashboard previously made 5 parallel HTTP requests on every poll cycle:

1. `GET /health` — overall system health
2. `GET /health/readiness` — Ollama readiness
3. `GET /api/system/status` — detailed service status
4. `GET /api/setup/provider/active` — active AI provider/model
5. `GET /api/system/metrics` — CPU, RAM, VRAM

The desktop also made separate requests for `/api/notifications` (alerts), `/api/observability/health` (Prometheus/Loki/Grafana), `/api/observability/costs` (token costs), and `/api/orchestrator/dlq` (dead letter queue). The `useSystemMetrics` hook polled `fetchAll()` every 5 seconds, resulting in up to 12 separate HTTP calls per cycle.

## Decision

Create a single consolidated endpoint `GET /api/system/dashboard` that returns all dashboard-relevant data in one response. The backend uses `asyncio.gather` to execute all sub-queries in parallel.

### Response Schema

```json
{
  "status": "ready",
  "services": { "backend": true, "postgres": true, "qdrant": true, "ollama": true, "n8n": false, "grafana": false, "prometheus": false },
  "runtime": { "activeModel": "qwen3:14b", "latency": 45.0, "cpu": 12.5, "ram": { "used": 8.2, "total": 32.0 }, "vram": { "used": 4.5, "total": 8.0 } },
  "metrics": { "vectorCount": 15234, "tokenRate": 42.3 },
  "costs": { "total_usd": 0.0045, "total_tokens": 2850 },
  "dlq": { "failed": [...], "count": 1 },
  "alerts": { "notifications": [...] }
}
```

### Frontend Changes

- `system-store.ts` `fetchAll()` now makes a single `GET /api/system/dashboard` call
- 3-second TTL cache prevents redundant parallel requests during rapid re-renders
- Existing independent endpoints (`/health`, `/api/system/metrics`, etc.) preserved for non-dashboard consumers

## Consequences

- **Positive**: Reduced network round-trips from 5→1 (with additional dashboard data consolidated). Lower latency, fewer open connections.
- **Positive**: Backend parallelizes sub-queries via `asyncio.gather` — no increase in server-side latency.
- **Neutral**: Other pages (login, setup, settings) continue to use independent endpoints directly.
- **Risk**: Single point of failure for dashboard data — mitigated by `return_exceptions=True` in gather and per-section fallback dicts.
