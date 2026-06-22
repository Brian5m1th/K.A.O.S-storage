# Guia KIRL — K.A.O.S Intelligence Runtime Layer

## O que é o KIRL?

O KIRL (K.A.O.S Intelligence Runtime Layer) é a camada de auditoria documental do sistema. Ele garante que toda feature implementada tenha documentação associada, detecta drift arquitetural e mantém a consistência entre código, commits e SDDs.

### Componentes Principais

```
FeatureRegistry (fonte da verdade)
    ↓
CodeScanner → detecta features no código
    ↓
CommitMapper → mapeia commits para features
    ↓
SDDResolver → verifica SDDs existentes
    ↓
AuditEngine → compara código vs documentação
    ↓
DRLSnapshot → estado unificado do sistema
    ↓
Graphify → grafo visual da arquitetura
    ↓
AutoDoc → geração automática de SDDs
```

---

## Feature Registry

O Feature Registry é a fonte da verdade. Toda feature do sistema precisa estar registrada aqui.

### Listar Features

```bash
curl http://localhost:8000/api/audit/features \
  -H "x-api-key: $API_KEY"
```

### Registrar uma Feature

```bash
curl -X POST http://localhost:8000/api/audit/register-feature \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "id": "minha-feature",
    "name": "Minha Feature",
    "phase": "fase-1",
    "status": "in-progress",
    "docs": ["SDD-MINHA-FEATURE.md"],
    "codeRefs": ["src/app/minha_feature.py"]
  }'
```

### Status Possíveis

| Status | Significado |
|--------|-------------|
| `planned` | Planejado, não iniciado |
| `in-progress` | Em desenvolvimento |
| `done` | Implementado e documentado |

---

## Executar Auditoria

### Manual (via API)

```bash
curl -X POST http://localhost:8000/api/audit/run \
  -H "x-api-key: $API_KEY"
```

**Resposta:**
```json
{
  "coverage": 87.5,
  "driftLevel": "medium",
  "missingFeatures": ["feature-1"],
  "outdatedDocs": ["SDD-OLD.md"],
  "timestamp": "2026-06-22T10:30:00"
}
```

### Manual (via UI)

1. Acesse `/documentation`
2. Clique em "Run Audit"
3. Aguarde o scan
4. Veja os resultados nos cards e abas

### Automática

O audit é executado automaticamente a cada 30 segundos pelo `AuditScheduler`.

Eventos emitidos:
- `audit.started` — início do ciclo
- `audit.completed` — resultados disponíveis
- `drift.detected` — quando drift alto é detectado

---

## Interpretar Resultados

### Drift Report

| Campo | Descrição |
|-------|-----------|
| `coverage` | % de features com documentação |
| `driftLevel` | low (>85%), medium (70-85%), high (<70%) |
| `missingFeatures` | Features sem SDD |
| `outdatedDocs` | SDDs desatualizados vs código |
| `inconsistentPhases` | Features com status inconsistente |
| `orphanedSDDs` | SDDs sem feature correspondente |
| `undocumentedCode` | Código sem entrada no registry |

### Drift Levels

| Level | Coverage | Ação Recomendada |
|-------|----------|------------------|
| 🟢 Low | >85% | Monitorar |
| 🟡 Medium | 70-85% | Revisar docs pendentes |
| 🔴 High | <70% | Auditoria urgente |

---

## DRL Snapshot

O snapshot é o estado unificado do sistema, consumido por UI, Graphify e AutoDoc.

```bash
curl http://localhost:8000/api/audit/snapshot \
  -H "x-api-key: $API_KEY"
```

```json
{
  "features": [...],
  "coverage": 87.5,
  "driftLevel": "medium",
  "lastCommit": "abc123",
  "missingCount": 6,
  "outdatedCount": 3,
  "graphSummary": {"totalNodes": 42, "totalEdges": 68}
}
```

---

## Code Scanner

O scanner detecta features no código analisando:

| Categoria | O que escaneia |
|-----------|---------------|
| stores | Zustand stores (`create(`) |
| routes | Páginas e rotas (`export default`) |
| tools | Ferramentas LangGraph |
| events | EventBus + EventSubscriber |
| agents | Classes Agent + AgentState |
| workflows | BaseWorkflow + registries |
| providers | Chat, Embedding, Vector, Memory |
| components | Widgets e UI components |
| hooks | Custom hooks (`use*`) |

```bash
curl -X POST http://localhost:8000/api/audit/scan-code \
  -H "x-api-key: $API_KEY"
```

---

## Commit Mapping

Mapeia commits para features automaticamente.

```bash
curl -X POST "http://localhost:8000/api/audit/scan-commits?limit=50" \
  -H "x-api-key: $API_KEY"
```

**Classificação:**
- `feat:` → alta prioridade para documentação
- `fix:` → média prioridade
- `test:`, `style:` → baixa prioridade
- `merge:` → ignorado

**Impacto:**
- `high` → event bus, workflow, provider, observability, memory
- `medium` → api, store, schema, migration
- `low` → typo, readme

---

## SDD Auto-Generation

Se uma feature não tem SDD, o sistema pode gerar automaticamente:

```bash
curl -X POST http://localhost:8000/api/audit/generate-sdd \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "featureId": "minha-feature",
    "featureName": "Minha Feature",
    "commitHash": "abc123",
    "commitMessage": "feat: minha feature",
    "phase": "fase-1",
    "detectedCodeRefs": ["src/app/main.py"],
    "impactType": "high"
  }'
```

SDDs gerados vão para `docs/runtime/auto-generated/AUTO-SDD-*.md` com status `AUTO-GENERATED - REQUIRES REVIEW`.

---

## Graphify — Architecture Graph

O Graphify transforma o DRL Snapshot em um grafo interativo.

### Navegação

Acesse `/architecture` no desktop.

| Ação | Como fazer |
|------|------------|
| Zoom | Scroll do mouse |
| Pan | Arrastar |
| Selecionar nó | Clique |
| Filtrar | Painel "Node Types" |
| Layout | Force / Hierarchical / Radial |
| Export | JSON / GraphML / SVG |

### Node Types

| Cor | Tipo | Descrição |
|-----|------|-----------|
| 🔵 Azul | feature | Feature do sistema |
| 🟢 Verde | store | Zustand store |
| 🟡 Amarelo | route | Página/rota |
| 🟣 Roxo | tool | Ferramenta LangGraph |
| 🔴 Vermelho | agent | Agente de IA |
| 🔷 Ciano | event | Evento do EventBus |
| 🟠 Laranja | provider | Provedor LLM/vector |
| ⚪ Cinza | sdd | Software Design Document |

### Edge Types

| Relação | Significado |
|---------|-------------|
| `uses` | A usa B |
| `emits` | A emite eventos para B |
| `documents` | A documenta B |
| `depends_on` | A depende de B |
| `contains` | A contém B |

---

## Auto-Doc Engine

O Auto-Doc Engine executa a cada 60 segundos e:

1. Escaneia o código (via CodeScanner)
2. Extrai features (via FeatureExtractor)
3. Gera SDDs automaticamente (via SDDGenerator)
4. Emite evento `docs:auto-updated`

### Forçar Execução

```typescript
// No console do navegador (desktop aberto):
```

---

## Alertas

Quando o drift level é `high`, o sistema emite um alerta:

```json
{
  "type": "system:alert",
  "severity": "high",
  "message": "Architecture documentation is behind implementation",
  "coverage": 45,
  "missing": ["agent-lifecycle", "sse-reconnect"]
}
```

Alertas aparecem no Event Bus e podem ser consumidos por:
- Dashboard de observabilidade
- n8n workflows
- Notificações

---

## Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| Auditoria retorna 0 features | FeatureRegistry vazio | Registre features ou execute scan |
| Coverage 100% suspeito | Nenhuma feature registrada | Verifique `features-index.json` |
| Drift sempre high | Features sem SDD | Crie SDDs ou gere automáticos |
| Snapshot desatualizado | Scheduler não rodando | Verifique logs do backend |
| Graphify sem dados | DRL Snapshot vazio | Execute auditoria primeiro |

---

## API Reference (KIRL)

| Endpoint | Descrição |
|----------|-----------|
| `POST /api/audit/run` | Executa auditoria completa |
| `GET /api/audit/snapshot` | Snapshot do DRL |
| `GET /api/audit/coverage` | Cobertura rápida |
| `POST /api/audit/scan-commits` | Escaneia commits |
| `GET /api/audit/commit-map` | Commit map existente |
| `POST /api/audit/scan-code` | Escaneia código |
| `POST /api/audit/register-feature` | Registra feature |
| `GET /api/audit/features` | Lista features |
| `GET /api/audit/features/{id}` | Detalhes da feature |
| `POST /api/audit/generate-sdd` | Gera SDD |
| `POST /api/audit/generate-feature-node` | Gera feature node |
