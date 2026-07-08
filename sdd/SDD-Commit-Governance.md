---
id: sdd_commit_governance
type: sdd
phase: Fase 1
status: approved
tags:
  - kaos
  - governance
  - commits
  - pr
---

# SDD — Commit & PR Governance

## Objetivo

Padronizar o fluxo de commits e Pull Requests no repositório K.A.O.S,
garantindo rastreabilidade, consistência histórica e conformidade com
o KIRL (Documentation Runtime Layer).

## Tipos de Commit (Conventional Commits)

Todo commit **deve** seguir o formato:

```
<tipo>(<escopo>): <descrição em minúsculas>

[body opcional com contexto]
[footer com SDD: SDD-XXX ou Fixes: #issue]
```

### Tipos Válidos

| Tipo | Quando usar | Exemplo |
|------|------------|---------|
| `feat` | Nova funcionalidade | `feat(api): add POST /api/conversations endpoint` |
| `fix` | Correção de bug | `fix(cors): replace wildcard origin with CORS_ORIGINS env var` |
| `refactor` | Refatoração sem mudança funcional | `refactor(orchestrator): extract ModelRouter selection logic` |
| `test` | Adição/modificação de testes | `test(rag): add unit tests for semantic retriever` |
| `docs` | Documentação apenas | `docs(sdd): add SDD-Commit-Governance guide` |
| `ci` | GitHub Actions / CI config | `ci(drift): add drift check workflow` |
| `chore` | Tarefas de manutenção (deps, config) | `chore(deps): update ruff to 0.9.0` |
| `style` | Formatting (ruff, prettier) apenas | `style(assistant): fix ruff formatting issues` |
| `perf` | Otimização de performance | `perf(rag): cache embeddings in SQLite` |

### ⛔ Proibido

- `feat/fix:` — barra separadora (violação do padrão)
- `feat+fix:` — tipos compostos
- Commits sem tipo (`atualiza arquivo`, `wip`, `fix`)
- Tipos fora da lista acima

### Exemplos Corretos

```
feat(api): add POST /api/conversations endpoint

Adiciona endpoint para criar nova sessão de conversa.
Inclui validação de campos obrigatórios.

SDD: SDD-Roadmap-Expansion-v2 | RF-D02
```

```
fix(cors): replace wildcard origin with CORS_ORIGINS env var

Fixes: security vulnerability — credentials + wildcard origin invalid
SDD: SDD-Roadmap-Expansion-v2 | RF-A01
```

```
docs(governance): add commitlint config and PR template

SDD: SDD-Roadmap-Expansion-v2 | TASK-001
```

## Processo de Pull Request

### Título do PR

Deve seguir o mesmo formato do commit principal:

```
<tipo>(<escopo>): <descrição>
```

### Body Obrigatório

```markdown
## O que essa PR faz
[descrição sumária]

## SDD Referenciado
- SDD: [nome do SDD] | [task ou RF]

## Checklist
- [ ] Testes passando (CI)
- [ ] Ruff lint/format passando
- [ ] Documentação atualizada em docs/
- [ ] SDD atualizado se houve mudança de contrato
```

### Labels

| Label | Uso |
|-------|-----|
| `enhancement` | Nova feature ou melhoria |
| `bugfix` | Correção de bug |
| `docs` | Documentação |
| `ci` | CI/CD |

### Merge

- **Squash & merge** é obrigatório (histório limpo)
- A mensagem do squash deve ser o título + body do PR

## Documentação Obrigatória por Tipo de PR

| Tipo de mudança | Ação obrigatória |
|----------------|-----------------|
| Novo endpoint | Atualizar `docs/api/API_REFERENCE.md` |
| Nova variável de ambiente | Atualizar `assistant/.env.example` + `docs/setup/SETUP.md` |
| Nova tabela DB | Atualizar `docs/architecture/SYSTEM_ARCHITECTURE.md` |
| Novo workflow agent | Criar SDD em `docs/sdd/` |
| Breaking change | Atualizar `docs/CHANGELOG.md` + bump version |

## Validação em CI

O workflow de CI incluirá validação de commitlint nos PRs
(ver `.github/workflows/ci.yml`).

## Arquivos Relacionados

- `.commitlintrc.json` — Regras de commitlint
- `.github/PULL_REQUEST_TEMPLATE.md` — Template de PR
- `docs/governance/DOCUMENTATION_GOVERNANCE_SDD.md` — Governance geral de documentação

## Status

**Aprovado** — vigente a partir de 2026-06-24.
