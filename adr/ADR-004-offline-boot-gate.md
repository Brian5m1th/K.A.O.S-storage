# ADR-004: Offline Boot Gate and Readiness Handling

**Status**: Accepted  
**Date**: 2026-07-11  
**Decision Maker**: KAOS Architect  

## Context

The previous boot pipeline would always proceed to "done" even when the backend was unreachable after a 30-second timeout. This meant the user could navigate to pages that would immediately fail with `Failed to fetch` errors. There was no dedicated offline experience.

## Decision

### 1. Offline Gate in AuthGate

The `AuthGate` component now checks `useSystemStore.getState().status` after auth resolution. If the status is `"offline"`, it renders a full-screen overlay instead of children:

- Title: "Servidor K.A.O.S Offline"  
- Server URL display (from `useAuthStore.serverUrl`)  
- "Tentar Novamente" button → `window.location.reload()`  

This gate runs **after** auth checks (`checking`, `configured`, `accessToken`) but **before** any protected route renders.

### 2. Boot Pipeline Error Handling

The `runBootstrapPipeline` in `use-init.ts` was updated:

- If `wait_backend_health` times out (30s / 15 polls):
  - Sets `useSystemStore.status = "offline"`
  - Emits `progress("error", ...)` — does NOT proceed to `"done"`
  - The offline gate activates on next AuthGate render
- Previously: would `progress("done", ...)` and let pages fail silently

### 3. Timing Tracking

Each bootstrap stage now records `performance.now()` timestamps:

```ts
interface BootstrapProgress {
  step: BootstrapStep;
  message: string;
  error?: string;
  timings?: Record<string, number>;  // e.g., { "Backend": 3200, "Auth": 420 }
}
```

Stage timings are logged to console for debugging startup performance.

## Consequences

- **Positive**: Users never see broken pages with `Failed to fetch` errors during boot.
- **Positive**: Clear user feedback — the offline overlay explicitly tells the user what's wrong and how to retry.
- **Positive**: Boot timing data enables future performance optimization.
- **Risk**: If system store is incorrectly set to `"offline"`, users are locked out. Mitigated by the retry button + `setStatus("online")` being called on first successful dashboard fetch.
