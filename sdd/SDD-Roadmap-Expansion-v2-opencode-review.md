# Prompt: Validação Arquitetural da Spec — K.A.O.S Roadmap Expansion v2

## Contexto

Foi gerada uma spec técnica completa via /spec-extractor cobrindo as Fases 9-14 do K.A.O.S.
A spec está em: `docs/sdd/SDD-Roadmap-Expansion-v2.md`

## Tarefa para o OpenCode (kaos-architect agent)

Analise a spec `docs/sdd/SDD-Roadmap-Expansion-v2.md` e valide os seguintes pontos:

### 1. Consistência Arquitetural
- Os contratos de interface propostos são consistentes com os padrões existentes no projeto (FastAPI routers, Pydantic models, endpoint prefixes)?
- Os modelos de dados SQL propostos são consistentes com o uso atual de SQLAlchemy async?
- A bridge MCP→LangGraph proposta é tecnicamente viável dado o `MCPManager` e `TOOL_REGISTRY` existentes?

### 2. Gaps não identificados
- Existe algum módulo no codebase atual que a spec ignora e deve ser considerado?
- Existe alguma dependência técnica não mapeada na Seção 8?

### 3. Conflitos com código existente
- Algum dos endpoints propostos já existe (mesmo que parcialmente implementado)?
- A proposta de `conversations` table conflita com alguma tabela existente em `infra/migrations/`?
- A proposta de `cost_events` table duplica algo do `CostTracker` atual?

### 4. Viabilidade dos critérios de aceite
- Os critérios de aceite são testáveis com `pytest` + fixtures?
- Existe algum critério ambíguo ou impossível de testar automaticamente?

### 5. Ordem de implementação sugerida
Dado os RFs identificados, qual a sequência ótima considerando:
- Dependências técnicas entre RFs
- Impacto no sistema em produção
- Menor risco de breaking changes

### 6. Red Flags
- Existe algum RF de alto risco de regressão?
- Existe alguma RN que contradiz o comportamento atual do sistema?

## Arquivos para consultar:
- `docs/sdd/SDD-Roadmap-Expansion-v2.md` — a spec
- `assistant/app/main.py` — routers registrados
- `assistant/app/orchestrator/universal_orchestrator.py` — RF-A02
- `assistant/app/core/mcp_manager.py` — RF-C03
- `assistant/app/ai/vault_analyzer/analyzer_engine.py` — RF-B01
- `assistant/app/observability/cost_tracker.py` — RF-F01
- `infra/migrations/` — schemas existentes
- `assistant/app/config/settings.py` — CORS_ORIGINS

## Output esperado

Relatório markdown com:
1. Status por grupo de RFs (✅ Consistente / ⚠️ Atenção / ❌ Conflito)
2. Lista de gaps não mapeados
3. Lista de conflitos encontrados
4. Sequência de implementação recomendada
5. Red flags identificados
