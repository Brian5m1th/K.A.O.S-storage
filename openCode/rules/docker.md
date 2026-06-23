---
description: Regras Docker para o K.A.O.S
globs: ["**/Dockerfile*", "**/docker-compose*", "**/Dockerfile.*"]
---
# Docker Rules

- Multi-stage builds: `builder` + `runtime` stages
- Nao use `root` como usuario — crie usuario nao-root
- `HEALTHCHECK` obrigatorio em servicos de producao
- Use `--no-cache` ou `--frozen` para reproducibilidade
- Variaveis sensiveis via arquivo `.env`, nunca hardcoded
- Named volumes para dados persistentes
- Servicos no docker-compose com `depends_on` e `healthcheck`
- Portas mapeadas explicitamente (sem `ports: "8000"`)
- Redes separadas para backend e frontend quando aplicavel

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
