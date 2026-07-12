---
id: desktop-audit-report
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Relatório de Auditoria do Desktop — K.A.O.S
Gerado em: 2026-06-23 14:55:35

## 1. Visão Geral da Estrutura
- **Total de Páginas:** 30
- **Total de Componentes UI/Widgets:** 18
- **State Stores (Zustand):** 11
- **Custom Hooks:** 7

## 2. Detecção de Mocks e Referências Sintéticas
Foram identificadas as seguintes estruturas sintéticas no frontend:
- **Mock References:** 0 arquivos
- **Math.random() occurrences (indicadores de telemetria fake):** 3 ocorrências

### Ocorrências de Math.random():
- `desktop/src/shared/lib/tool-schema.ts:L25`: `id: crypto.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,`
- `desktop/src/features/documentation-audit/graph/layout-engine.ts:L27`: `x: centerX + radius * Math.cos(angle) + (Math.random() - 0.5) * 50,`
- `desktop/src/features/documentation-audit/graph/layout-engine.ts:L28`: `y: centerY + radius * Math.sin(angle) + (Math.random() - 0.5) * 50,`

## 3. Páginas Encontradas
- `desktop/src/app/routes/pages/agents.tsx`
- `desktop/src/app/routes/pages/architecture/index.tsx`
- `desktop/src/app/routes/pages/chat.tsx`
- `desktop/src/app/routes/pages/dashboard.tsx`
- `desktop/src/app/routes/pages/documentation/index.tsx`
- `desktop/src/app/routes/pages/graphify.tsx`
- `desktop/src/app/routes/pages/knowledge-graph.tsx`
- `desktop/src/app/routes/pages/login.tsx`
- `desktop/src/app/routes/pages/observability.tsx`
- `desktop/src/app/routes/pages/orchestration.tsx`
- `desktop/src/app/routes/pages/pipelines.tsx`
- `desktop/src/app/routes/pages/settings.tsx`
- `desktop/src/app/routes/pages/setup.tsx`
- `desktop/src/app/routes/pages/users.tsx`
- `desktop/src/app/routes/pages/vault.tsx`
- `desktop/src/pages/agents/index.tsx`
- `desktop/src/pages/architecture/index.tsx`
- `desktop/src/pages/chat/index.tsx`
- `desktop/src/pages/dashboard/index.tsx`
- `desktop/src/pages/documentation/index.tsx`
- `desktop/src/pages/graphify/index.tsx`
- `desktop/src/pages/knowledge-graph/index.tsx`
- `desktop/src/pages/login/index.tsx`
- `desktop/src/pages/observability/index.tsx`
- `desktop/src/pages/orchestration/index.tsx`
- `desktop/src/pages/pipelines/index.tsx`
- `desktop/src/pages/settings/index.tsx`
- `desktop/src/pages/setup/index.tsx`
- `desktop/src/pages/users/index.tsx`
- `desktop/src/pages/vault/index.tsx`

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
