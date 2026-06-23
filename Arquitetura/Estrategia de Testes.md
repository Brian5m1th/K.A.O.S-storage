---
id: estrategia-de-testes
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

﻿---
type: knowledge
domain: arquitetura
status: active
---

# EstratÉgia de Testes
*Testing Strategy*

> Define a politica de cobertura de testes unitarios e de integracao minimos no pipeline de build.

## Parent
- [[Arquitetura Geral]]

## Children
- [[Guia de Testes e Uso]]

## Related
- [[Guia de Testes e Uso]]
- [[Padroes de Projeto]]

## Tags
#kaos #arquitetura #testing #pytest #coverage

---

## Conteudo
# Estratégia de Testes — K.A.O.S

---

## Pirâmide

```
      /\
     /E2E\         → fluxos completos (Open WebUI → API → RAG)
    /------\
   /Integration\   → interação entre camadas (API → Serviço → Qdrant)
  /--------------\
 /   Unit Tests   \ → lógica isolada (tools, chunking, serviços sem IO)
/------------------\
```

---

## Cobertura Mínima

| Camada | Cobertura | Obrigatório |
|:-------|:---------:|:-----------:|
| Unit | ≥ 80% | ✅ Sim |
| Integration | ≥ 60% | ✅ Sim |
| E2E | ≥ 30% | 🟡 Desejável |

---

## Diretrizes

1. **Sem rede externa** — testes não dependem de Ollama, Qdrant ou internet
2. **Fixtures locais** — vault de teste em `tests/fixtures/vault/`
3. **Mock para serviços externos** — `LLMService`, `QdrantClient`, `httpx`
4. **Isolamento** — cada teste limpa seu estado
5. **Legíveis** — nome do teste descreve cenário e resultado esperado

---

## Comandos

```bash
# Todos os testes
pytest

# Com cobertura
pytest --cov=app --cov-report=term-missing

# Apenas unitários
pytest tests/unit/

# Apenas integração
pytest tests/integration/
```




