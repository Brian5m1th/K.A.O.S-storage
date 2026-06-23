---
id: desktop-compatibility-report
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Relatório de Compatibilidade Desktop/Backend — K.A.O.S
Gerado em: 2026-06-23 14:55:35

## 1. Status de Compatibilidade
- **FastAPI Endpoints / Desktop API Integration:** Totalmente compatíveis.
- O cliente de rede principal (`kaosFetch` em `@/shared/api/kaos-client`) auto-injeta tokens JWT ou headers `X-API-Key` de forma transparente.

## 2. Mapeamento de Endpoints Utilizados no Desktop
Os seguintes endpoints do backend FastAPI são ativamente requisitados pelo Desktop:
- `/api/audit/scan-commits` em `desktop/src/pages/documentation/index.tsx`
- `/api/audit/scan-code` em `desktop/src/features/documentation-audit/auto-doc/code-introspector.ts`
- `/api/audit/generate-feature-node` em `desktop/src/features/documentation-audit/auto-doc/doc-sync-engine.ts`
- `/api/audit/commit-map` em `desktop/src/features/documentation-audit/engine/commit-mapper.ts`
- `/api/audit/features` em `desktop/src/features/documentation-audit/engine/feature-scanner.ts`
- `/api/audit/features/${id}` em `desktop/src/features/documentation-audit/engine/feature-scanner.ts`
- `/api/architecture/heatmap` em `desktop/src/features/documentation-audit/heatmap/heatmap-store.ts`
- `/api/architecture/analysis` em `desktop/src/features/documentation-audit/heatmap/heatmap-store.ts`
- `/api/architecture/heatmap` em `desktop/src/features/documentation-audit/heatmap/heatmap-store.ts`
- `/api/audit/run` em `desktop/src/features/documentation-audit/store/drift-store.ts`
- `/api/audit/snapshot` em `desktop/src/features/documentation-audit/store/drift-store.ts`

## 3. Discrepâncias de Tipagem e Mocks Esquecidos
- Não foram detectadas variáveis `MOCK_` em produção nas páginas de core, exceto placeholders temporários em páginas secundárias a serem finalizadas na Fase 3-6.
- A tipagem do React Flow do Graphify está perfeitamente alinhada com o DTO do `drl_snapshot.py`.

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
