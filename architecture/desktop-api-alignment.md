---
id: desktop-api-alignment
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Alinhamento de APIs (Backend vs Desktop) — K.A.O.S
Gerado em: 2026-06-23 14:55:35

## 1. Endpoints do Backend Consumidos pelo Frontend
O frontend consome com sucesso os seguintes roteadores da FastAPI:
- `auth`: `/auth/key`, `/auth/setup-status`
- `providers`: `/api/providers`, `/api/setup/provider`
- `system`: `/api/system/status`
- `architecture`: `/api/architecture/graph`, `/api/architecture/heatmap`
- `admin`: `/api/admin/users`

## 2. Endpoints Não Consumidos ou Opcionais
- `/api/audit/readiness/f2`: Chamado nas auditorias internas e em rotinas de CI, mas opcional na UI do usuário final.
- `/api/opencode/*`: Consumido principalmente via CLI/Agentes, mas mapeado na integração do desktop.

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
