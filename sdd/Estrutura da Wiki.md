---
type: knowledge
domain: obsidian
status: active
---

# Estrutura da Wiki
*Wiki Structure & Schemas*

> Regras de organizacao e metadados das pastas de entidades, conceitos, fontes e sinteses na wiki.

## Parent
- [[Camada Wiki de Conhecimento]]

## Children
- [[index]]
- [[Agente de Ingestao de Conhecimento]]
- [[Memoria do Obsidian]]
- [[AGENTS]]
- [[AGENTS.pt-BR]]

## Related
- [[ConfiguraçAes de Agente MemÓria do Obsidian]]

## Tags
#kaos #obsidian #wiki #schema #vault

---

## Conteudo
## Estrutura do Vault

```
{vault}/
├── raw/                          # Fontes imutáveis (somente leitura)
│   ├── artigo_mamba2.md
│   ├── podcast_transcricao.md
│   └── assets/                   # Imagens baixadas
│
└── wiki/                         # Conhecimento sintetizado
    ├── AGENTS.md                 # Schema — o LLM consulta antes de agir
    ├── AGENTS.pt-BR.md           # Versão em português
    ├── index.md                  # Catálogo vivo de todas as páginas
    ├── log.md                    # Timeline append-only
    │
    ├── entities/                 # Objetos concretos
    │   ├── brian.md
    │   ├── kaos.md
    │   └── qdrant.md
    │
    ├── concepts/                 # Abstrações
    │   ├── rag.md
    │   ├── embeddings.md
    │   └── langgraph.md
    │
    ├── sources/                  # Resumo de cada fonte ingerida
    │   └── 2026-06-18_artigo_llm_wiki.md
    │
    └── synthesis/                # Conhecimento derivado
        ├── comparacao_mamba_vs_rwkv.md
        └── arquitetura_rag_hibrido.md
```

---





