---
id: documentation_governance_sdd
type: sdd
phase: Fase 1
status: approved
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Governance de Documentação — K.A.O.S

## Pipeline de Documentação

Toda feature ou mudança segue este fluxo obrigatório:

```
Feature PR → SDD → Implementação → Documentação → Merge
```

### 1. SDD (Software Design Document)

Antes de implementar qualquer feature, um SDD deve ser criado em `docs/vault/sdd/`.

O SDD cobre:
- Objetivo e contexto
- Decisões arquiteturais
- Interface proposta (API, componentes)
- Segurança e considerações

### 2. Implementação

Código segue a branch da feature com PR para `main`.

Revisão obrigatória via `pr-agent.yml`.

### 3. Documentação

Após implementação, documentar em `docs/vault/` na categoria apropriada:
- `architecture/` — Decisões arquiteturais
- `security/` — Autenticação, autorização, secrets
- `monitoring/` — Métricas, logs, dashboards
- `providers/` — Configuração de LLM providers
- `setup/` — Instalação e configuração
- `ci-cd/` — Workflows e pipelines
- `storage/` — Submodule e persistência
- `observability/` — Grafana, Loki, queries
- `troubleshooting/` — Problemas comuns e soluções
- `governance/` — Este documento e regras

### 4. Merge

O PR só é merged quando:
- Código revisado e aprovado
- Testes passando (80/80)
- Documentação correspondente criada/atualizada
- SDD referenciado no PR

## Regras

1. **Nunca** documentar no repositório principal (`K.A.O.S`)
2. Toda documentação vai para `docs/vault/` (submodule K.A.O.S-storage)
3. Máximo 1500 linhas por execução de edição
4. SDDs são versionados no submodule, não no repo principal
5. Mudanças de documentação seguem commit separado no submodule

## Padrão de Commits

Todo commit **deve** seguir Conventional Commits conforme definido em
[SDD-Commit-Governance.md](../sdd/SDD-Commit-Governance.md).

Resumo:
- Formato: `<tipo>(<escopo>): <descrição>`
- Tipos válidos: `feat`, `fix`, `refactor`, `test`, `docs`, `ci`, `chore`, `style`, `perf`
- ⛙ Proibido: `feat/fix:`, `feat+fix:`, commits sem tipo
- Merge: Squash & merge obrigatório

## SDD Deduplication

Os arquivos `docs/sdd_*.md` que eventualmente existam no repositório principal devem ser migrados para `docs/vault/sdd/` e removidos do principal.

Após migração, atualizar `docs/index.md` para refletir a nova localização.

## Resumo

Este documento define o fluxo obrigatório de documentação para toda
feature ou mudança no K.A.O.S. O pipeline é: **Feature PR → SDD →
Implementação → Documentação → Merge**.

## Objetivo

Garantir que toda mudança no K.A.O.S seja documentada antes de ser
integrada, mantendo rastreabilidade entre código, documentação e
decisões arquiteturais. Este documento serve como guia para
contribuidores e IA agents que manipulam documentação.

## Responsabilidades

| Ator | Responsabilidade |
|------|-----------------|
| Desenvolvedor | Criar SDD antes de implementar, atualizar docs após implementar |
| AI Agent (OpenCode) | Seguir as regras deste documento ao criar/editar documentação |
| Reviewer | Verificar checklist de documentação no PR antes de aprovar |
| KIRL Audit | Validar que docs correspondem ao código real (drift check) |

## Dependencias

- `docs/sdd/` — Diretório de SDDs
- `docs/vault/` — Submodule K.A.O.S-storage com documentação detalhada
- `.github/workflows/ci.yml` — CI com validação de lint e testes
- `.github/PULL_REQUEST_TEMPLATE.md` — Template de PR com checklist

## Fluxos

### Fluxo Normal

```
Feature PR → SDD → Implementação → Documentação → Merge
```

1. Criar SDD em `docs/sdd/` (antes de implementar)
2. Implementar em branch feature
3. Documentar em `docs/vault/` na categoria apropriada
4. Abrir PR com checklist completo
5. Merge após aprovação

### Fluxo de Correção (bugfix)

```
Bug → Branch fix → Implementação → Documentação (se aplicável) → Merge
```

SDD é opcional para bugfixes simples. Documentação é obrigatória se
houver mudança de comportamento público (API, env vars, etc).

## Integracoes

| Sistema | Integração |
|---------|-----------|
| GitHub Actions | CI executa lint, testes, e drift check |
| OpenCode (IDE) | AI agent usa estas regras ao manipular documentação |
| KIRL Audit Engine | Valida periodicamente cobertura documental |

## Arquivos Relacionados

- `docs/sdd/SDD-Commit-Governance.md` — Padronização de commits e PRs
- `.commitlintrc.json` — Regras de commitlint
- `.github/PULL_REQUEST_TEMPLATE.md` — Template de PR
- `docs/guides/DEVELOPER_GUIDE.md` — Guia do desenvolvedor

## Referencias KIRL

- KIRL Rule: `documentation_governance`
- KIRL Snapshot: O DRL Snapshot referencia este documento como
  regra de governança documental
- Audit Check: `documentation_governance_sdd` — valida que
  documentação segue o fluxo definido aqui

## Status

**Aprovado** — vigente a partir de 2026-06-24.

## Ultima Atualizacao

2026-06-24 — Seções pendentes preenchidas, regra de "2 arquivos markdown"
removida (obsoleta para AI agents).
