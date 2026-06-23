---
id: sdd_obsidian_rag
type: sdd
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

Source: Notas no ClickUp
Tags: #sdd #rag #qdrant #embeddings #vector-search
Related: [[sdd_obsidian_memoria]] [[sdd_obsidian_watcher]] [[sdd_obsidian_tools]]

# SDD Componente — Vector Search & RAG Service

Esta nota descreve o motor de busca semântica, as escolhas de modelos de embedding e a estratégia de Recuperação Aumentada de Geração (RAG) usada para fornecer contexto atualizado ao Assistente de IA.

---

## Estrutura do Vector Database (Qdrant)

### Configuração da Coleção

- **Métrica de Distância**: Cosseno (`Cosine`)
- **Dimensão do Vetor**: 1024 (bge-m3) ou 768 (nomic-embed-text)
- **Coleção**: `obsidian_memory`

### Esquema do Payload

```json
{
  "id": "e604f8db-...",
  "vector": [0.012, -0.045, 0.823, "..."],
  "payload": {
    "path": "Python/Padroes_Design.md",
    "chunk_index": 2,
    "content": "Padrão Singleton garante...",
    "tags": ["python", "design-patterns"],
    "folder": "Python",
    "last_modified": "2026-06-10T13:10:00Z"
  }
}
```

---

## Modelos de Embedding

1. **`BAAI/bge-m3`** (Recomendado): Multilíngue, 1024-dim, contexto longo (8192 tokens)
2. **`nomic-ai/nomic-embed-text`**: Rápido, leve, 768-dim

## Algoritmo de Recuperação

```
Prompt → Embedding → Qdrant query (com filtros opcionais de pasta/tag)
                          → Top-K chunks → Re-rank por score → Contexto injetado no LLM
```

### Exemplo de Consulta Filtrada

```python
results = client.search(
    collection_name="obsidian_memory",
    query_vector=query_embedding,
    query_filter=Filter(must=[FieldCondition(key="folder", match=MatchValue(value="Python"))]),
    limit=5,
)
```

---

## Relação com outras Notas

- [[sdd_obsidian_watcher]] — Ciclo de inserção de vetores
- [[sdd_obsidian_tools]] — Ferramenta SearchNotesTool

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
