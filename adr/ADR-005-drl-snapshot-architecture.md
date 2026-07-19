# ADR-005: DRL Snapshot Architecture

- **Status:** Accepted
- **Decision Owner:** KAOS Architect
- **Review Date:** 2027-01-19
- **Date:** 2026-07-19
- **Supersedes:** N/A
- **Superseded By:** N/A

---

## Context

O K.A.O.S possui uma camada de documentação viva (DRL — Documentation Runtime Layer) que precisa refletir com precisão o estado real do sistema. O problema central: documentação inline (SDDs, docstrings, comentários) frequentemente diverge do código de produção, gerando drift arquitetural não detectado.

A solução proposta — DRL Snapshot — é um mecanismo que periodicamente extrai a documentação do código-fonte, compara com a baseline arquivada e emite alertas quando o drift ultrapassa thresholds definidos.

### Fatores técnicos

1. O projeto tem 4+ linguagens (Python, TypeScript, YAML, Dockerfile)
2. Cada módulo pode ter 0..N SDDs associados
3. Drift é medido em 3 níveis: **low**, **medium**, **high**
4. O sistema precisa ser reexecutável e não destrutivo

## Decision

Adotar o **DRL Snapshot** como um pipeline de 3 estágios:

```
Código-fonte → Estágio 1: Extração → `drl_state.json`
                                    → Estágio 2: Comparação → `drl_diff.json`
                                                             → Estágio 3: Notificação
```

### Estágio 1 — Extração (drl_snapshot.py)

- Varre recursivamente módulos de `assistant/` e `desktop/src/`
- Extrai docstrings de módulos, classes e funções públicas
- Extrai blocos SDD (`""" <sdd:...`) do código-fonte
- Extrai `@router` e `@app.` de endpoints
- Gera `drl_state.json` com timestamp, módulos, cobertura

### Estágio 2 — Comparação (readiness_engine.py)

- Carrega o `drl_state.json` anterior do arquivo `.kaos/drl/baseline/`
- Compara módulo a módulo: existência, docstring coverage, SDD coverage
- Calcula **drift score** por módulo (0.0 a 1.0)
- Classifica: `low` (<0.2), `medium` (0.2-0.5), `high` (>0.5)

### Estágio 3 — Notificação

- Se drift ≥ **medium**: loga warning + salva em `drl_diff.json`
- Se drift ≥ **high**: emite alerta no sistema de observabilidade
- Sempre atualiza a baseline

### Integração CI/CD

```yaml
# Acionado após graphify update .
# Se DRL drift passou de medium → warning no PR
# Se passou de high → CI falha
```

## Evidence Supporting This Decision

1. **Métrica baseline:** 3 módulos com SDDs órfãos (sem código correspondente) detectados na auditoria
2. **Métrica baseline:** Coverage documental < 90% em 2 módulos core
3. **Experimento:** Teste manual mostrou drift invisível em PRs por 3 semanas até ser descoberto

## Consequences

### Positive

- Drift arquitetural é detectado automaticamente, não em retrospectiva
- Cobertura documental vira métrica rastreável no tempo
- Baseline versionada permite rollback de documentação
- Pipeline cabe em CI (< 5s para extração, < 2s para comparação)

### Negative

- Custo de manutenção do pipeline (~10 linhas por novo extrator)
- Falsos positivos durante refatoração intensa (mitigado pelo threshold `medium`)
- Dependência de `graphify update .` ter sido executado recentemente

### Risks & Mitigations

- **Risk:** Snapshot fica dessincronizado se CI não roda → **Mitigation:** pre-commit hook roda extração
- **Risk:** Threshold muito baixo causa noise → **Mitigation:** threshold configurável via `kaos.yaml`
- **Risk:** SDDs órfãos não detectados → **Mitigation:** validação cruzada com Graphify god nodes

## Implementation Plan

1. ✅ W0: Implementar `drl_snapshot.py` com extração básica
2. ✅ W3: Implementar `readiness_engine.py` com diff lógico
3. 🔄 CI: Adicionar etapa `drl-snapshot` no workflow
4. 🔄 pre-commit: Adicionar hook `drl-validate`
5. 📋 Dashboard: Adicionar painel de cobertura documental

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Docstring-only | Simples, sem pipeline extra | Não detecta SDDs órfãos, sem baseline histórica | Não atende requisito de drift tracking |
| Graphify-only | Já extrai relacionamentos | Não foca em documentação, sem thresholds de drift | Complementar, não substituto |
| Manual review | Sem custo de implementação | Não escala, 100% dependente de disciplina humana | Inviável para consistência contínua |

## Stakeholders

- **Consulted:** KAOS Auditors, Backend Engineers
- **Informed:** DevOps Engineers
- **Approved by:** KAOS Architect, 2026-07-19
