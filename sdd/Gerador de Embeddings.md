---
id: gerador-de-embeddings
type: sdd
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

﻿---
type: knowledge
domain: ia
status: active
---

# Gerador de Embeddings
*Local Embeddings Generator*

> Componente responsavel pela geracao offline de vetores de embeddings usando SentenceTransformers localmente.

## Parent
- [[Fases 4-5 - Pipeline RAG e Watcher]]

## Children
- [[index]]
- [[Busca Vetorial e RAG]]

## Related
- [[Busca Vetorial e RAG]]
- [[Provedor Hibrido de LLM]]

## Tags
#kaos #ia #embeddings #bge-m3 #python

---

## Conteudo
## 2. Embedder (`rag/embeddings/embedder.py`)

```python
from sentence_transformers import SentenceTransformer
from loguru import logger
from app.config.settings import settings

_embedder_instance: "Embedder | None" = None


class Embedder:
    """Gera embeddings de texto usando Sentence Transformers (local, offline)."""

    MODEL_CONFIGS = {
        "bge-m3": {"name": "BAAI/bge-m3", "dim": 1024},
        "nomic": {"name": "nomic-ai/nomic-embed-text-v1.5", "dim": 768},
    }

    def __init__(self, model_key: str = "bge-m3") -> None:
        config = self.MODEL_CONFIGS[model_key]
        self._dim = config["dim"]
        logger.info(f"Carregando modelo de embedding: {config['name']}")
        self._model = SentenceTransformer(config["name"], trust_remote_code=True)

    @property
    def dimension(self) -> int:
        return self._dim

    def embed(self, texts: list[str]) -> list[list[float]]:
        """Gera embeddings para uma lista de textos."""
        vectors = self._model.encode(texts, normalize_embeddings=True)
        return vectors.tolist()

    def embed_single(self, text: str) -> list[float]:
        return self.embed([text])[0]


def get_embedder(model_key: str = "bge-m3") -> Embedder:
    """Retorna instância singleton do Embedder (evita reloads caros)."""
    global _embedder_instance
    if _embedder_instance is None:
        _embedder_instance = Embedder(model_key)
    return _embedder_instance


def warmup_embedder(model_key: str = "bge-m3") -> None:
    """Pré-carrega o modelo para evitar cold start na primeira query."""
    embedder = get_embedder(model_key)
    logger.info("[info] Embedder - warmup")
    _ = embedder.embed_single("warmup")
    logger.debug("[finish] Embedder - warmup")
```

---

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
