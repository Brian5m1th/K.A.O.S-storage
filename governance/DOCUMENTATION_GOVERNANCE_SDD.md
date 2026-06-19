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
3. Máximo 2 arquivos markdown por execução de edição
4. Máximo 1500 linhas por execução de edição
5. SDDs são versionados no submodule, não no repo principal
6. Mudanças de documentação seguem commit separado no submodule

## SDD Deduplication

Os arquivos `docs/sdd_*.md` que eventualmente existam no repositório principal devem ser migrados para `docs/vault/sdd/` e removidos do principal.

Após migração, atualizar `docs/index.md` para refletir a nova localização.
