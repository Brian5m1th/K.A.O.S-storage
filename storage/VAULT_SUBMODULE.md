---
id: vault_submodule
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Vault Submodule — K.A.O.S-storage

## Visão Geral

O diretório `docs/vault/` é um **git submodule** apontando para o repositório privado `Brian5m1th/K.A.O.S-storage`.

Todo o conteúdo documental (SDDs, manuais, backlog, diagramas) reside **exclusivamente** no submodule. O repositório principal (`K.A.O.S`) contém apenas código-fonte e CI.

## Repositório

- **URL:** `https://github.com/Brian5m1th/K.A.O.S-storage.git`
- **Privacidade:** Privado
- **Acesso:** PAT com escopo `repo`

## Clonagem

### Primeira vez

```bash
git clone --recurse-submodules https://github.com/Brian5m1th/K.A.O.S.git
```

### Se já clonou sem submodules

```bash
git submodule update --init --recursive
```

## Autenticação

O `GITHUB_TOKEN` padrão **não** tem acesso a repositórios privados. Para CI, use um **PAT** (Personal Access Token) com escopo `repo`.

O PAT é configurado como **Repository secret** (`PAT`) — não como Environment secret.

No workflow:

```yaml
- name: Checkout with submodule
  uses: actions/checkout@v4
  with:
    submodules: recursive
    token: ${{ secrets.PAT }}
```

## Fluxo de Trabalho

1. Alterações de documentação são feitas diretamente em `docs/vault/`
2. Commit e push para o submodule separadamente
3. Depois commit no repositório principal atualizando o ponteiro do submodule

```bash
cd docs/vault
git add .
git commit -m "docs: update XYZ"
git push origin main
cd ../..
git add docs/vault
git commit -m "chore: update vault submodule pointer"
git push
```

## .gitignore

O arquivo `data/provider_config.json` está em `.gitignore` para evitar vazar API keys.

## Atenção

- **Nunca** crie documentação no repositório principal — sempre em `docs/vault/`
- O submodule é **privado**: builds de terceiros ou forks não terão acesso
- Sempre use `git submodule update --init --recursive` em novos ambientes

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
