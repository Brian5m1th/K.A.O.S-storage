# SDD-KIRL — K.A.O.S Documentation Runtime Layer (DRL)

**Status:** Approved
**Version:** 1.0
**Date:** 2026-06-22

---

## 1. Objective

Create a self-describing, event-driven documentation runtime layer (DRL) that continuously validates architectural consistency between code, commits, and SDDs. The DRL transforms documentation from static artifacts into a living subsystem of the K.A.O.S operating system.

---

## 2. Architecture Pillars

| # | Pillar | Description |
|---|--------|-------------|
| 1 | **Single Source of Truth** | Feature Registry as canonical feature catalog |
| 2 | **Event-Driven Documentation** | All changes flow through Event Bus |
| 3 | **Continuous Drift Detection** | Real-time code vs docs comparison |
| 4 | **Auto-Reactive Documentation** | Commits without docs trigger auto-generation |
| 5 | **Unified State Snapshot** | Single API for all consumers (UI, Graph, Auto-Doc) |

---

## 3. Core Concepts

### 3.1 Feature Registry (Source of Truth)

```python
@dataclass
class FeatureEntry:
    id: str                    # unique identifier
    name: str                  # human-readable name
    phase: str                 # e.g., "Fase 8.5", "SDD-040"
    status: Literal["planned", "in-progress", "done"]
    docs: list[str]            # relative paths to SDDs
    code_refs: list[str]       # relative paths to source files
    last_commit: str           # git commit hash
    created_at: str            # ISO timestamp
    updated_at: str            # ISO timestamp
```

Every feature in the system **must** exist here.

### 3.2 Commit → Feature Mapping

```json
{
  "commit": "feat: Fase 8 - Observability + Event Bus subscribers",
  "hash": "abc123",
  "features": ["observability", "event-bus", "metrics-system"],
  "type": "FEAT",
  "timestamp": "2026-06-21T10:30:00Z"
}
```

Connects Git history to architectural reality.

### 3.3 Documentation Coverage Engine

Responsibilities:

- Detect: Feature exists in code, missing from docs ❌
- Detect: Feature exists in docs, missing from code ❌
- Detect: Partially implemented feature ❌
- Detect: Stale SDD (commit ahead of doc) ❌

### 3.4 Drift Engine (Core Comparator)

```python
interface DriftReport:
    coverage: number           # 0-100%
    missing_features: string[] # features without docs
    undocumented_code: string[]# code without feature entry
    outdated_docs: string[]    # SDDs behind commits
    inconsistent_phases: string[] # phase mismatches
```

### 3.5 DRL State Snapshot (Unified Read Layer)

Single consolidated state for all consumers:

```python
interface DRLSnapshot:
    features: FeatureEntry[]
    coverage: number
    drift_level: "low" | "medium" | "high"
    last_commit: str
    graph_summary: GraphSummary
    generated_at: str
```

Consumed by: UI Dashboard, Architecture Graph, Auto-Doc Engine.

---

## 4. Data Layer

### 4.1 Persisted Artifacts (`docs/runtime/`)

```
docs/runtime/
├── registry/
│   ├── features-index.json    # FeatureRegistry export
│   └── commit-map.json        # Commit → Feature mappings
├── audit/
│   ├── coverage-report.json   # DriftEngine output
│   ├── undocumented-features.json
│   └── inconsistencies.json
└── snapshot.json              # DRLSnapshot (unified read)
```

### 4.2 Git Integration

- `commit_classifier.py` — Semantic commit parsing (feat/fix/test/merge)
- `commit_mapper.py` — `git log` analysis → feature impact detection
- Auto-generates `commit-map.json` on demand

---

## 5. Event Bus Integration

### 5.1 Published Events

| Event | Payload | Trigger |
|-------|---------|---------|
| `audit.started` | `{ timestamp }` | Audit cycle begins |
| `audit.completed` | `DriftReport` | Audit cycle ends |
| `drift.detected` | `{ severity, missing[], outdated[] }` | Drift threshold crossed |
| `docs.coverage_updated` | `{ coverage, missing_count }` | Coverage changes |
| `feature.registered` | `FeatureEntry` | New feature added |
| `feature.updated` | `FeatureEntry` | Feature modified |
| `sdd.generated` | `{ path, commit, features[] }` | Auto-SDD created |
| `snapshot.updated` | `DRLSnapshot` | Unified state refresh |

### 5.2 Subscribers

- `DriftSubscriber` — Logs audit events, triggers alerts
- `SnapshotUpdater` — Rebuilds `snapshot.json` on events
- `AlertSubscriber` — High drift → system alert

---

## 6. Code Scanner (Hybrid Lightweight)

Strategy: **Filesystem + Heuristic + Regex** (no AST/runtime import)

Detects:

- Zustand stores (`/stores/*.ts`)
- Routes/Pages (`/pages/**`, `/app/**`)
- Tool schemas (`tool-schema.ts`, SSE events)
- Event Bus usage (`event-bus.ts`, `emit/on` calls)
- Agents/Workflows (Python: `base.py`, `workflows/`)
- Providers (chat, embedding, vector, memory)

Output: `CodeSnapshot` → feeds `FeatureExtractor` → updates Registry.

---

## 7. SDD Auto-Generation Pipeline

```
Git Commit
    ↓
Commit Classifier (feat/fix/test/merge)
    ↓
Feature Detector (high impact?)
    ├─ event bus changes
    ├─ new workflows
    ├─ new providers
    ├─ model router changes
    ├─ observability changes
    └─ memory system changes
    ↓
SDD Resolver (exists?)
    ├─ YES → index in Registry
    └─ NO  → Auto-generate SDD skeleton
                ↓
         Feature Registry update
                ↓
         Event Bus emit: sdd.generated
```

Generated SDD location: `docs/sdd/AUTO-{feature-name}.md`

---

## 8. Frontend Integration (Read-Only Consumers)

### 8.1 SystemStore Extension

```typescript
documentation: {
  coverage: number;
  driftLevel: "low" | "medium" | "high";
  lastScan: number | null;
  missingCount: number;
  outdatedCount: number;
}
```

### 8.2 CTRL+K Commands

| ID | Label | Category |
|----|-------|----------|
| `go-documentation` | Open Documentation Health | navigation |
| `run-audit` | Run Documentation Audit | actions |
| `audit-undocumented` | Show Undocumented Features | actions |
| `audit-sync` | Sync Docs with Codebase | actions |

### 8.3 Documentation Page (`/documentation`)

Components:
- `CoverageChart` — Historical coverage trend
- `MissingFeaturesList` — Features without SDDs
- `OutdatedDocsList` — SDDs behind commits
- `DriftTimeline` — Drift history
- `CommitMappingView` — Commits → Features

---

## 9. Architecture Graph Layer (Graphify)

Separate engine consuming DRL Snapshot:

```
DRL Snapshot → GraphBuilder → { nodes, edges } → Event Bus → UI
```

Node types: `store`, `route`, `tool`, `agent`, `event`, `provider`
Edge relations: `uses`, `emits`, `calls`, `renders`

Update interval: 5s (configurable)

---

## 10. Auto-Documentation Engine

Separate engine consuming DRL Snapshot:

```
DRL Snapshot + Code Scanner → SDD Generator → docs/runtime/AUTO-SDD.md
```

Runs every 60s. Emits `docs.auto_updated` event.

---

## 11. Alert System

When `driftLevel === "high"`:

```python
eventBus.emit("system:alert", {
    type: "documentation-drift",
    severity: "high",
    message: "Architecture documentation is behind implementation",
    coverage: 67,
    missing: ["agent-lifecycle", "sse-reconnect"]
})
```

---

## 12. Implementation Phases

| Phase | Components | Deliverable |
|-------|------------|-------------|
| **1** | `feature_registry.py`, `SDD-KIRL.md` | Registry + SDD |
| **2** | `commit_classifier.py`, `commit_mapper.py` | Commit → Feature map |
| **3** | `code_scanner.py`, `sdd_resolver.py`, `sdd_generator.py` | Scanner + Auto-SDD |
| **4** | `audit_engine.py` (DriftEngine) | Core comparator |
| **5** | `drl_snapshot.py`, `drift_subscriber.py` | Snapshot + Event Bus |
| **6** | SystemStore, CTRL+K, `/documentation` page | Frontend visibility |
| **7** | Graphify engine + page | Architecture visualization |
| **8** | Auto-Doc engine | Self-updating SDDs |

---

## 13. Configuration

```python
# assistant/app/audit/config.py
DRL_CONFIG = {
    "scan_interval_seconds": 30,
    "snapshot_interval_seconds": 10,
    "drift_threshold_high": 30,      # % missing → high
    "drift_threshold_medium": 15,    # % missing → medium
    "auto_sdd_enabled": True,
    "graphify_enabled": True,
    "auto_doc_enabled": True,
}
```

---

## 14. Security & Governance

- Auto-generated SDDs marked with `AUTO-GENERATED - REQUIRES REVIEW`
- Human review required before `status: "done"`
- Commit-map only stores hashes + feature IDs (no sensitive data)
- Snapshot is read-only for consumers

---

## 15. Future Evolution

| Next Layer | Description |
|------------|-------------|
| **AI Architecture Reviewer** | LLM reads Graph + SDD + Code → suggests refactors |
| **Self-Healing DRL** | Auto-fix drift (update SDD status, suggest code changes) |
| **Predictive Architecture** | Predict impact of changes before merge |
| **Visual OS Mode** | Full cyber-cockpit: navigate system as living map |

---

*This SDD defines the Documentation Runtime Layer as a structural layer of K.A.O.S, equivalent in status to SDD-040.*