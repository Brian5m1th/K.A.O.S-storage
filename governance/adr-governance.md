# ADR Governance Rules

## Lifecycle

Every ADR file must declare a `Status` key with one of:

| Status | Meaning |
|---|---|
| `Draft` | Under discussion, not yet approved |
| `Proposed` | Submitted for review |
| `Accepted` | Approved and in effect |
| `Deprecated` | No longer applicable (replaced by new approach) |
| `Superseded` | Replaced by a newer ADR (must reference successor) |
| `Rejected` | Explicitly rejected with rationale |

## Ownership

- Each ADR must have a single **Decision Owner**.
- Each ADR must have a **Review Date** — default 6 months from entry.
- ADRs past their review date must be revalidated or marked Superseded.

## Merge Block (CI)

The CI pipeline **rejects** any PR that:
1. Changes configuration variables (`settings.py`, `.env`)
2. Changes database schemas (`models/`, `alembic/versions/`)
3. Changes dependency layers (`pyproject.toml`, `package.json`)
4. Changes API contracts significantly

...unless a matching new or updated ADR is included in the same PR.

## Storage

All ADRs live in `docs/adr/`. Format: `ADR-NNN-title-in-kebab-case.md`.

## ADR Registry

Current ADRs:

| ID | Title | Status | Owner | Review |
|---|---|---|---|---|
| ADR-001 | Graphify as Evidence Engine Source | Accepted | KAOS Architect | 2027-01-11 |
| ADR-002 | Capability-First Architecture with Ports & Adapters | Accepted | KAOS Architect | 2027-01-11 |
| ADR-003 | Technology Observatory as Continuous Monitoring | Accepted | KAOS Architect | 2027-01-11 |
