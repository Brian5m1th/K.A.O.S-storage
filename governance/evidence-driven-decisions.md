# Evidence-Driven Decisions — K.A.O.S Process

## Principle

> No architectural decision is made without verifiable evidence.

## The 10-Step Scientific Method

```
1. Inventory      — Map current state & capabilities (Graphify + Evidence Engine)
2. Identify       — Gaps, overlaps, pain points (with concrete examples)
3. Formulate      — Hypothesis: "Change X will improve Y by Z%"
4. Research       — README, issues, papers, benchmarks, community health
5. Compare        — Capability matrix, not popularity matrix
6. Experiment     — Run in kaos-research/, controlled dataset
7. Measure        — Performance, quality, cost, architectural impact
8. Validate       — Hypothesis confirmed or rejected (with evidence)
9. Decide         — ADR + Incremental plan + Rollback strategy
10. Integrate     — Via adapters + ports. Never direct coupling.
```

## Evidence Sources

All decisions must cite at least ONE evidence source:

| Source | What It Provides | Tool |
|---|---|---|
| **Graphify** | Code structure, cycles, dependencies, god objects | `graphify explain/path/query` |
| **Git History** | Commit frequency, churn, ownership, regressions | `git log --since=...` |
| **Test Results** | Coverage, mutation score, pass/fail rates | `pytest --cov`, `vitest` |
| **Benchmarks** | Latency, throughput, memory, quality scores | `kaos-research/benchmarks/` |
| **ADRs** | Decision history, rationale, precedents | `docs/adr/` |
| **Runtime Metrics** | Service health, uptime, P95/P99 latency | Prometheus, system metrics |
| **Community Health** | Stars, forks, issues, maintainer activity | Technology Observatory |
| **Experiments** | Controlled A/B comparisons | `kaos-research/experiments/` |

## Anti-Patterns (Rejected)

❌ "Framework X is popular, let's use it."
❌ "I saw this on Hacker News."
❌ "Company Y uses it."
❌ "The README looks good."
❌ "It has more stars."

## Valid Patterns (Required)

✅ "Graphify query confirmed 41 connections for CodeScanner."
✅ "Benchmarks show Mem0 latency < 50ms for 10k entries."
✅ "ADR-002 established the Capability-First pattern."
✅ "Technology Observatory shows GraphRAG has 3 breaking changes this month."
✅ "Experimental results show Qdrant outperforms FalkorDB by 30% on our dataset."

## Decision Template

Every decision proposal must fill:

```markdown
## Decision: [Title]

### Hypothesis
[Specific, measurable prediction]

### Evidence Collected
1. [Source: Graphify/Git/Tests/Benchmarks]
2. ...

### Trade-offs
| Factor | Current | Proposed | Delta |
|---|---|---|---|
| Performance | ... | ... | ... |
| Complexity | ... | ... | ... |
| Cost | ... | ... | ... |
| Risk | ... | ... | ... |

### Validation Method
[How will we confirm this decision was correct?]

### Rollback Plan
[How do we undo this if wrong?]
```
