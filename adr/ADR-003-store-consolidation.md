# ADR-003: Store Consolidation and FSD Architecture Cleanup

**Status**: Accepted  
**Date**: 2026-07-11  
**Decision Maker**: KAOS Architect  

## Context

The K.A.O.S Desktop project uses Feature-Sliced Design (FSD) architecture. Stores (Zustand state management) were duplicated across two locations:

```
desktop/src/
├── shared/lib/stores/      ← DUPLICATE (8 identical files)
│   ├── agent-store.ts
│   ├── auth-store.ts
│   ├── chat-store.ts
│   ├── conversation-store.ts
│   ├── system-store.ts
│   ├── theme-store.ts
│   ├── ui-store.ts
│   └── update-store.ts
└── application/stores/     ← CANONICAL
    └── (same 8 files)
```

The `shared/lib/stores/index.ts` was already a backward-compatibility shim re-exporting from `application/stores/`. Additionally, `useSystemMetrics` hook was duplicated in both `application/hooks/` and `features/dashboard/hooks/`.

## Decision

1. **Delete all 8 store files** from `shared/lib/stores/` — the canonical location is `application/stores/`
2. **Retarget all imports** to `@/application/stores` or `@/application`
3. **Keep the barrel shim** at `shared/lib/stores/index.ts` unchanged (it already re-exports from application)
4. **Delete dead `application/hooks/useSystemMetrics.ts`** — only `features/dashboard/hooks/useSystemMetrics.ts` is consumed

### Files Retargeted

| File | Old Import | New Import |
|---|---|---|
| `pages/documentation/index.tsx` | `../../shared/lib/stores/system-store` | `@/application` |
| 7 test files under `__tests__/shared/lib/stores/` | `@/shared/lib/stores/*` | `@/application/stores/*` |
| `__tests__/integration/auth-chat-flow.test.ts` | `@/shared/lib/stores/*` | `@/application/stores/*` |

## Consequences

- **Positive**: Single source of truth for all stores. No risk of drift between copies.
- **Positive**: Clean FSD layer separation — `shared/` no longer contains state management.
- **Positive**: Smaller bundle (8 dead files removed).
- **Risk**: Import paths in documentation/guides may reference old locations — addressed via barrel shim.
