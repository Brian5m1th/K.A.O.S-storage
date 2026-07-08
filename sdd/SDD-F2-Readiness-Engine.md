---
type: sdd
domain: audit
status: approved
version: 2.0
date: 2026-06-23
author: kaos-architect
phase: Fase 1.3
---

# SDD-F2-Readiness-Engine
*Graph Runtime & Audit Foundation — Normalized Check Registry*

> Spec formal do motor de validacao de readiness para Fase 2 (Graphify Explorer, AI Vault Analyzer, Drift Heatmap).

## Parent
- [[Roadmap Geral]]

## Children
- [[SDD-KIRL]]
- [[SDD-Desktop-Stabilization-F1]]

## Related
- [[SDD-Graphify]]
- [[SDD-AI-Vault-Analyzer]]
- [[Feature Registry]]

## Tags
#kaos #f2 #readiness #audit #graph #runtime #sdd

---

## 1. Objective

Criar um motor de validacao deterministica que avalia se a infraestrutura do K.A.O.S esta pronta para iniciar a Fase 2 (AI Vault Analyzer, Drift Heatmap, Graphify Explorer, Knowledge Graph Explorer).

O Readiness Engine deve:
- Executar 12 checks estruturais e semanticos
- Retornar score numerico (0-100)
- Impedir inicio da Fase 2 se hard blockers falharem
- Ser reproduzivel (input fingerprint)
- Nao ter dependencias circulares

---

## 2. Check Registry — Schema Unico

```python
@dataclass
class CheckDefinition:
    id: str                # "graph_json"
    version: str           # "V1"
    layer: str             # "structural" | "semantic"
    blocker: bool          # hard blocker?
    category: str          # "runtime" | "source" | "registry"
    dependencies: list[str]  # IDs dos checks que este depende
    validator: str         # nome da funcao validadora
```

### 2.1 Os 12 Checks

| id | version | layer | blocker | category | dependencies | validator |
|-|-|-|-|-|-|-|
| `graph_json` | V1 | structural | ✅ | runtime | — | `validate_graph_json()` |
| `knowledge_graph_json` | V2 | structural | ✅ | runtime | — | `validate_knowledge_graph_json()` |
| `graph_api` | V3 | semantic | ❌ | runtime | `graph_json` | `validate_graph_api()` |
| `heatmap_api` | V4 | semantic | ❌ | registry | `features_index` | `validate_heatmap_api()` |
| `graph_summary` | V5 | semantic | ❌ | registry | `graph_json`, `snapshot_json` | `validate_graph_summary()` |
| `docs_source` | V6 | structural | ✅ | source | — | `validate_docs_source()` |
| `arch_page` | V7 | semantic | ❌ | runtime | `graph_api` | `validate_arch_page()` |
| `reactflow` | V8 | semantic | ❌ | source | — | `validate_reactflow()` |
| `snapshot_json` | V9a | structural | ✅ | registry | — | `validate_snapshot_json()` |
| `features_index` | V9b | structural | ✅ | registry | `snapshot_json` | `validate_features_index()` |
| `commit_map` | V9c | structural | ✅ | registry | — | `validate_commit_map()` |
| `heatmap_data` | V10 | semantic | ❌ | registry | `heatmap_api`, `features_index` | `validate_heatmap_data()` |

---

## 3. Anti-Circularidade — DAG de Dependencias

```
graph_json ──────── graph_api ──────── arch_page
                        │
                        └────────────── graph_summary ◄── snapshot_json
                                                                 │
knowledge_graph_json                                            │
                                                                │
snapshot_json ──────── features_index ── heatmap_api ── heatmap_data
                                                                │
commit_map ─────────────────────────────────────────────────────┘

docs_source (independente)
reactflow (independente)
```

**Regra:** Nenhum check depende de outro que ele mesmo valida.

---

## 4. Feature `done` — Regra Rigida

```
done = commit_mapeado(commit_map)      # git: rastreavel
     + endpoint_existe(endpoint_list)   # codigo: implementado
     + graph_reference(graph_json)      # arquitetura: mapeado
     + (opcional) teste_passando

audit = APENAS valida consistencia entre os 3
      = NAO "autoriza" status
      = NAO modifica features-index
```

**Fonte da verdade:** `features-index.json` e escrito manualmente via `POST /api/audit/register-feature`. Audit apenas **le** e **valida**.

---

## 5. Fingerprint — Separado por Camada

```
input_fingerprint  = sha256(JSON(features + sdds + vault))
graph_fingerprint  = sha256(JSON(graph.nodes + graph.edges))
source_hash        = sha256(input_fingerprint + graph_fingerprint)
```

`graph_summary.source_hash` = combinacao dos dois. Output nunca valida input no mesmo ciclo.

---

## 6. Categorias de Hard Blockers

```
A. Runtime Integrity:   graph_json, knowledge_graph_json
B. Source Integrity:    docs_source
C. Registry Integrity:  snapshot_json, features_index, commit_map
```

---

## 7. Readiness Endpoint

```
POST /api/audit/readiness/f2

Response 200:
{
  "score": 90,
  "passed": 9,
  "failed": 1,
  "total": 12,
  "blockers_passed": true,
  "categories": {
    "runtime":  { "passed": 2, "failed": 0, "blocker": true },
    "source":   { "passed": 1, "failed": 0, "blocker": true },
    "registry": { "passed": 3, "failed": 0, "blocker": true }
  },
  "checks": {
    "graph_json":             { "status": "pass", "layer": "structural", "blocker": true, "category": "runtime" },
    "knowledge_graph_json":   { "status": "pass", "layer": "structural", "blocker": true, "category": "runtime" },
    "graph_api":              { "status": "pass", "layer": "semantic", "blocker": false, "category": "runtime" },
    "heatmap_api":            { "status": "pass", "layer": "semantic", "blocker": false, "category": "registry" },
    "graph_summary":          { "status": "pass", "layer": "semantic", "blocker": false, "category": "registry" },
    "docs_source":            { "status": "pass", "layer": "structural", "blocker": true, "category": "source" },
    "arch_page":              { "status": "pass", "layer": "semantic", "blocker": false, "category": "runtime" },
    "reactflow":              { "status": "fail", "layer": "semantic", "blocker": false, "category": "source" },
    "snapshot_json":          { "status": "pass", "layer": "structural", "blocker": true, "category": "registry" },
    "features_index":         { "status": "pass", "layer": "structural", "blocker": true, "category": "registry" },
    "commit_map":             { "status": "pass", "layer": "structural", "blocker": true, "category": "registry" },
    "heatmap_data":           { "status": "pass", "layer": "semantic", "blocker": false, "category": "registry" }
  },
  "input_fingerprint": "sha256:<hash>",
  "generated_at": "2026-06-23T..."
}
```

---

## 8. Criterio de Go/No-Go

| Condicao | Decisao |
|-|-|
| `categories.runtime.blocker && runtime.failed > 0` | ❌ No-Go |
| `categories.source.blocker && source.failed > 0` | ❌ No-Go |
| `categories.registry.blocker && registry.failed > 0` | ❌ No-Go |
| `score < 90%` | ❌ No-Go |
| `score >= 90% && todas categorias sem blocker fail` | ✅ Go |

---

## 9. Validadores — Implementacao

Cada check possui um validador com assinatura:

```python
async def validate_graph_json() -> dict:
    # Retorna {"status": "pass", "details": {...}}
    # ou {"status": "fail", "details": {"error": "..."}}
```

### 9.1 Validadores Estruturais

#### `validate_graph_json()`
- Verifica `docs/runtime/architecture/graph.json` existe
- Verifica JSON valido
- Verifica `len(nodes) > 0`
- Verifica `len(edges) > 0`
- Verifica schema dos nodes: `id`, `label`, `type`
- Verifica schema dos edges: `source`, `target`, `relation`

#### `validate_knowledge_graph_json()`
- Verifica `docs/runtime/architecture/knowledge-graph.json` existe
- Verifica `total_nodes > 0`
- Verifica `total_edges > 0`

#### `validate_docs_source()`
- Executa `git grep "workspace"` no diretorio backend + desktop
- Classifica resultados em PERMITTED / NOT PERMITTED
- Retorna fail se NOT PERMITTED > 0

#### `validate_snapshot_json()`
- Verifica `docs/runtime/snapshot.json` existe
- Verifica `coverage >= 0`

#### `validate_features_index()`
- Verifica `docs/runtime/registry/features-index.json` existe
- Verifica `total_features >= 6`
- Verifica cada feature tem `status` valido (done/in_progress/planned)

#### `validate_commit_map()`
- Verifica `docs/runtime/registry/commit-map.json` existe
- Verifica `len(commits) > 0`

### 9.2 Validadores Semanticos

#### `validate_graph_api()`
- Chama `GET /api/architecture/graph`
- Verifica `status == 200`
- Verifica retorna `{ nodes, edges }`

#### `validate_heatmap_api()`
- Chama `GET /api/architecture/heatmap`
- Verifica `status == 200`
- Verifica `score >= 0`

#### `validate_graph_summary()`
- Carrega `snapshot.json`
- Verifica `graph_summary.nodes > 0`
- Verifica `graph_summary.edges > 0`
- Verifica `graph_summary.source_hash` nao vazio

#### `validate_arch_page()`
- Verifica se o componente `ArchitecturePage` consome store real (Zustand)
- Verifica ausencia de mock data

#### `validate_reactflow()`
- Verifica `package.json` contem `reactflow` ou `@xyflow/react`
- Ignorado no score atual (Fase 1.3 permite fail)

#### `validate_heatmap_data()`
- Chama `GET /api/architecture/heatmap`
- Verifica `score > 0`

---

## 10. Feature Registry — Status Reais (Fases 0-6)

| id | phase | status | Justificativa |
|-|-|-|-|
| `kirl` | Fase 0 | done | SDD-KIRL, runtime, audit |
| `desktop-stabilization` | Fase 1 | done | PR #79 merged |
| `provider-ux` | Fase 1.5 | done | Dropdown + persistencia |
| `docs-source-refactor` | Fase 1.1 | done | RuntimePathResolver |
| `validation-audit` | Fase 1.2 | done | Zero mocks, CI passing |
| `auth-wizard` | Fase 2 | in_progress | Backend JWT existe, First Run Wizard existe, sem PostgreSQL |
| `provider-catalog` | Fase 3 | in_progress | 11 providers no backend, sem UI de catalogo |
| `observability-real` | Fase 4 | planned | Endpoints existem, sem UI |
| `opencode-layer` | Fase 5 | done | API + .opencode/ config |
| `multi-user-rbac` | Fase 6 | in_progress | Endpoints existem, UI existe, banco necessario |
| `f2-readiness-engine` | Fase 1.3 | in_progress | Este SDD |

---

## 11. Implementacao

### Arquivos

| Arquivo | Acao | Descricao |
|-|-|-|
| `assistant/app/audit/readiness_engine.py` | **CRIAR** | Motor de validacao com 12 checks |
| `assistant/app/api/audit.py` | **MODIFICAR** | Adicionar `POST /api/audit/readiness/f2` |
| `assistant/app/ai/vault_analyzer/graph_builder.py` | **MODIFICAR** | Adicionar `DRLSnapshotManager.update_graph_summary()` com fingerprint |
| `assistant/app/audit/drl_snapshot.py` | **MODIFICAR** | Expandir `update_graph_summary` com `edge_types`, `source_hash`, `graph_version` |

### Dependencias

Nenhuma nova dependencia externa. O motor usa `json`, `hashlib`, `pathlib`, `httpx` (ja existentes).

---

## 12. Acceptance Criteria

- [ ] `POST /api/audit/readiness/f2` retorna 200 com checks
- [ ] Cada check retorna status correto
- [ ] Hard blockers funcionam (1 fail = No-Go mesmo com score 90%)
- [ ] `graph_summary` contem `nodes`, `edges`, `node_types`, `edge_types`, `source_hash`, `graph_version`
- [ ] `source_hash` muda quando `features-index.json` ou `graph.json` mudam
- [ ] Nenhuma dependencia circular nos checks
- [ ] Score < 90% retorna No-Go
- [ ] Score >= 90% + blockers pass retorna Go

---

*Este SDD define o motor de readiness para Fase 2 como um sistema de validacao deterministica, eliminando decisoes subjetivas sobre quando comecar a implementacao do Graphify Explorer e AI Vault Analyzer.*

## Resumo
- Informações pendentes de validação ou auto-geração.

## Objetivo
- Informações pendentes de validação ou auto-geração.

## Responsabilidades
- Informações pendentes de validação ou auto-geração.

## Dependencias
- Informações pendentes de validação ou auto-geração.

## Fluxos
- Informações pendentes de validação ou auto-geração.

## Integracoes
- Informações pendentes de validação ou auto-geração.

## Arquivos Relacionados
- Informações pendentes de validação ou auto-geração.

## Referencias KIRL
- Informações pendentes de validação ou auto-geração.

## Status
- Informações pendentes de validação ou auto-geração.

## Ultima Atualizacao
- Informações pendentes de validação ou auto-geração.
