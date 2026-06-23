---
id: github_actions
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# GitHub Actions — K.A.O.S

## Workflows

### `ci.yml` — Backend CI

**Trigger:** Push e PR para `main` (exceto `*.md`)

| Job | Runner | Descrição |
|-----|--------|-----------|
| `test` | ubuntu-latest | Lint (ruff), testes (pytest 80/80), build check |
| `docker` | ubuntu-latest | Build, push, Cosign sign, trivy scan |

**Cosign:** Assina imagem Docker com keyless (não requer chave privada).
Usa `${GITHUB_REPOSITORY,,}` para lowercase do nome da imagem.

**Healthcheck Pós-Build:**
```yaml
- run: |
    docker run -d -p 8000:8000 ghcr.io/...:latest
    sleep 10
    curl -f http://localhost:8000/health
```

### `desktop-ci.yml` — Desktop CI

**Trigger:** Push e PR para `main` (paths: `src/**`)

| Job | Runner | Descrição |
|-----|--------|-----------|
| `build` | ubuntu-latest | Build React + Tauri, Vite cache, lint |

**Otimizações:**
- Vite cache: `~/.npm`, `src/node_modules`, `src/src-tauri/target`
- `paths-ignore` com `!` negation patterns (GH não permite `paths` + `paths-ignore` juntos)
- Build metrics report

### `release.yml` — Release

**Trigger:** Tag `v*`

| Job | Runner | Descrição |
|-----|--------|-----------|
| `release` | ubuntu-latest | Cria GitHub Release com changelog |
| `docker` | ubuntu-latest | Build, push (latest + tag), Cosign sign, healthcheck |

**Assets:** Imagem Docker assinada + binários Tauri (Windows/MSI, Linux/deb, macOS/dmg).

### `pr-agent.yml` — PR Review

**Trigger:** PRs para `main`

- Auto-review com IA
- Gera resumo de mudanças e sugestões

## Segredos Utilizados

| Segredo | Escopo | Uso |
|---------|--------|-----|
| `PAT` | Repository | Checkout com submodule privado |
| `GHCR_TOKEN` | Repository | Push para ghcr.io |
| `TAURI_PRIVATE_KEY` | Environment (release) | Assinatura do updater Tauri |
| `TAURI_KEY_PASSWORD` | Environment (release) | Senha da chave Tauri |

> PAT é Repository secret desde PR #41 — disponível em todos workflows, sem depender de environment.

## Submodule em CI

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
    token: ${{ secrets.PAT }}
```

Crítico: sem o PAT, o checkout do submodule privado falha com 404.

## Boas Práticas

- Nunca use `paths` + `paths-ignore` no mesmo trigger
- Sempre use `${GITHUB_REPOSITORY,,}` para lowercase em nomes de imagem
- Healthcheck obrigatório após build Docker
- Testes precisam de `app.state.api_key` + header `X-API-Key` nas fixtures HTTP

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
