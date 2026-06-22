Source: Antigravity AI
Tags: #sdd #python #rag #qdrant #embeddings #watchdog #fase4 #fase5 #fase6
Related: [[index]] [[backlog]] [[sdd_fase3_obsidian_service]] [[sdd_obsidian_rag]] [[sdd_obsidian_watcher]] [[sdd_fase5_watcher_langgraph]]

# SDD — Fases 4 e 5: RAG Pipeline + Atualização Automática

## Objetivo

Transformar o Vault Obsidian em um banco de conhecimento semântico consultável. A IA recupera contexto relevante das notas antes de gerar respostas. O `watchdog` mantém o índice vetorial sincronizado automaticamente com qualquer alteração no Vault.

---

## Critério de Sucesso

> O usuário faz uma pergunta sobre um tema que está em uma nota do Vault. A IA responde usando informações da nota sem que a nota tenha sido citada explicitamente na conversa. Ao editar a nota e perguntar novamente, a resposta reflete o conteúdo atualizado.

---

## Status Atual: ✅ CONCLUÍDO (Fases 4-5 + Otimizações)

| Componente | Status | Detalhes |
|------------|--------|----------|
| Qdrant | ✅ | Coleção `obsidian_memory`, COSINE distance, 1024-dim |
| Embedder BGE-M3 | ✅ | `BAAI/bge-m3` (1024-dim), Singleton via `get_embedder()` |
| Chunking | ✅ | `MarkdownSplitter` (800 chars, 150 overlap, header-aware) |
| Indexer | ✅ | `VaultIndexer` upsert com ID determinístico (MD5 path+index) |
| Retriever | ✅ | `SemanticRetriever` com `score_threshold=0.3`, folder filter |
| Watcher | ✅ | `VaultWatcher` (watchdog) auto-reindex create/modify/delete/move |
| Diagnostics | ✅ | Logs: query, vector_size, scores, paths, payload keys |
| Warmup | ✅ | `warmup_embedder()` no lifespan do FastAPI |

---

## 1. Estrutura de Módulos

```text
app/
├── rag/
│   ├── __init__.py
│   ├── embeddings/
│   │   └── embedder.py
│   ├── chunking/
│   │   └── text_splitter.py
│   ├── retriever/
│   │   └── semantic_retriever.py
│   └── indexer/
│       └── vault_indexer.py
└── obsidian/
    └── watcher/
        └── vault_watcher.py
```

---

## 2. Embedder (`rag/embeddings/embedder.py`)

```python
from sentence_transformers import SentenceTransformer
from app.config.settings import settings

_embedder_instance: "Embedder | None" = None

class Embedder:
    MODEL_CONFIGS = {
        "bge-m3": {"name": "BAAI/bge-m3", "dim": 1024},
        "nomic": {"name": "nomic-ai/nomic-embed-text-v1.5", "dim": 768},
    }

    def __init__(self, model_key: str = "bge-m3") -> None:
        config = self.MODEL_CONFIGS[model_key]
        self._dim = config["dim"]
        self._model = SentenceTransformer(config["name"], trust_remote_code=True)

    @property
    def dimension(self) -> int:
        return self._dim

    def embed(self, texts: list[str]) -> list[list[float]]:
        vectors = self._model.encode(texts, normalize_embeddings=True)
        return vectors.tolist()

    def embed_single(self, text: str) -> list[float]:
        return self.embed([text])[0]

def get_embedder(model_key: str = "bge-m3") -> Embedder:
    global _embedder_instance
    if _embedder_instance is None:
        _embedder_instance = Embedder(model_key)
    return _embedder_instance

def warmup_embedder(model_key: str = "bge-m3") -> None:
    embedder = get_embedder(model_key)
    _ = embedder.embed_single("warmup")
```

---

## 3. Text Splitter (`rag/chunking/text_splitter.py`)

```python
import re
from dataclasses import dataclass

@dataclass
class TextChunk:
    content: str
    chunk_index: int
    source_path: str

class MarkdownSplitter:
    def __init__(self, chunk_size: int = 800, overlap: int = 150) -> None:
        self._chunk_size = chunk_size
        self._overlap = overlap

    def split(self, text: str, source_path: str) -> list[TextChunk]:
        sections = re.split(r'\n(?=#{1,3} )', text)
        chunks = []
        index = 0
        for section in sections:
            section = section.strip()
            if not section:
                continue
            if len(section) <= self._chunk_size:
                chunks.append(TextChunk(content=section, chunk_index=index, source_path=source_path))
                index += 1
            else:
                paragraphs = section.split("\n\n")
                buffer = ""
                for para in paragraphs:
                    if len(buffer) + len(para) > self._chunk_size and buffer:
                        chunks.append(TextChunk(content=buffer.strip(), chunk_index=index, source_path=source_path))
                        index += 1
                        buffer = buffer[-self._overlap:] + "\n\n" + para
                    else:
                        buffer += "\n\n" + para if buffer else para
                if buffer.strip():
                    chunks.append(TextChunk(content=buffer.strip(), chunk_index=index, source_path=source_path))
                    index += 1
        return chunks
```

---

## 4. Semantic Retriever (`rag/retriever/semantic_retriever.py`)

```python
from qdrant_client import QdrantClient
from qdrant_client.models import FieldCondition, Filter, MatchValue
from app.config.settings import settings
from app.domain.document import SearchResult
from app.rag.embeddings.embedder import get_embedder

class SemanticRetriever:
    def __init__(self) -> None:
        self._client = QdrantClient(host=settings.QDRANT_HOST, port=settings.QDRANT_PORT)
        self._embedder = get_embedder("bge-m3")

    def search(self, query: str, limit: int = 5, folder_filter: str | None = None) -> list[SearchResult]:
        query_vector = self._embedder.embed_single(query)
        search_filter = None
        if folder_filter and folder_filter.strip():
            search_filter = Filter(must=[FieldCondition(key="folder", match=MatchValue(value=folder_filter.strip()))])
        response = self._client.query_points(
            collection_name=settings.QDRANT_COLLECTION,
            query=query_vector,
            query_filter=search_filter,
            limit=limit,
            score_threshold=settings.RAG_SCORE_THRESHOLD,
            with_payload=True,
        )
        return [
            SearchResult(path=hit.payload["path"], score=hit.score, excerpt=hit.payload["content"][:300])
            for hit in response.points
        ]
```

---

## Dependências

- [[sdd_fase3_obsidian_service]] — ObsidianService para leitura de arquivos

## Desbloqueia

- [[sdd_fase5_watcher_langgraph]] — O LangGraph usará o `SemanticRetriever` como primeira etapa do grafo
