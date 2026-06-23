---
id: fases-4-5---pipeline-rag-e-watcher
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

# Fases 4-5 - Pipeline RAG e Watcher
*RAG Pipeline & Auto-Update*

> Documento orquestrador descrevendo o pipeline RAG e a sincronizacao automatica do vault Obsidian com o banco Qdrant.

## Parent
- [[Roadmap Geral]]

## Children
- [[Gerador de Embeddings]]
- [[Divisao de Texto (Chunking)]]
- [[Indexador do Vault]]
- [[Recuperador Semantico]]
- [[Monitoramento do Vault (Watcher)]]

## Related
- [[Busca Vetorial e RAG]]
- [[Obsidian Watcher]]

## Tags
#kaos #ia #rag #qdrant #watcher #roadmap

---

## Conteudo
## Source: Antigravity AI
Tags: #sdd #python #rag #qdrant #embeddings #watchdog #fase4 #fase5 #fase6
Related: [[index]] [[Backlog do Projeto]] [[Fase 3 - Servico Obsidian]] [[Busca Vetorial e RAG]] [[Obsidian Watcher]] [[Fases 6-7 - Watcher LangGraph e Memoria]]

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
| Embedder BGE-M3 | ✅ | `BAAI/bge-m3` (1024-dim), **Singleton** via `get_embedder()` |
| Chunking | ✅ | `MarkdownSplitter` (800 chars, 150 overlap, header-aware) |
| Indexer | ✅ | `VaultIndexer` upsert com ID determinístico (MD5 path+index) |
| Retriever | ✅ | `SemanticRetriever` com `score_threshold=0.3`, folder filter |
| Watcher | ✅ | `VaultWatcher` (watchdog) auto-reindex create/modify/delete/move |
| **Diagnostics** | ✅ | Logs: query, vector_size, scores, paths, payload keys |
| **Warmup** | ✅ | `warmup_embedder()` no lifespan do FastAPI |

---



## Tarefas — Fase 4 (RAG) ✅

- [x] Subir Qdrant via Docker Compose
- [x] Configurar modelo de embeddings (`BAAI/bge-m3`)
- [x] Implementar chunking de documentos (`app/rag/chunking/`)
- [x] Indexar todas as notas existentes (indexação inicial)
- [x] Criar retriever semântico (`app/rag/retriever/`)
- [x] Testar consultas contextuais



## Tarefas — Fase 5 (Atualização Automática) ✅

- [x] Adicionar `watchdog` como dependência
- [x] Detectar eventos de `CREATE`, `MODIFY` e `DELETE`
- [x] Disparar reindexação automática no Qdrant



## Tarefas — Otimizações (Fase 8) ✅

- [x] **Singleton Embedder** — `get_embedder()` evita múltiplas instâncias
- [x] **Score Threshold** — `settings.RAG_SCORE_THRESHOLD=0.3` no `query_points`
- [x] **Logs de Diagnóstico** — Query, vector_size, scores, paths, payload keys
- [x] **Folder Filter** — Validação strip/empty, ignora se vazio
- [x] **Warmup Embedder** — Carregamento antecipado no startup

---



## 1. Estrutura de Módulos

```text
app/
├── rag/
│   ├── __init__.py
│   ├── embeddings/
│   │   └── embedder.py         # Geração de vetores (Sentence Transformers)
│   ├── chunking/
│   │   └── text_splitter.py    # Divisão de Markdown em chunks
│   ├── retriever/
│   │   └── semantic_retriever.py  # Busca no Qdrant por similaridade
│   └── indexer/
│       └── vault_indexer.py    # Orquestra leitura + chunk + embed + upsert
└── obsidian/
    └── watcher/
        └── vault_watcher.py    # Watchdog + disparo de reindexação
```

---



## 6. File Watcher (`obsidian/watcher/vault_watcher.py`)

```python
import asyncio
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileSystemEvent
from loguru import logger
from app.rag.indexer.vault_indexer import VaultIndexer
from app.config.settings import settings

class _VaultEventHandler(FileSystemEventHandler):
    def __init__(self, indexer: VaultIndexer) -> None:
        self._indexer = indexer
        self._debounce: dict[str, asyncio.Task] = {}

    def _is_markdown(self, path: str) -> bool:
        return path.endswith(".md") and not Path(path).name.startswith(".")

    def on_created(self, event: FileSystemEvent) -> None:
        if not event.is_directory and self._is_markdown(event.src_path):
            logger.debug(f"[Watcher] CREATE: {event.src_path}")
            self._indexer.index_file(event.src_path)

    def on_modified(self, event: FileSystemEvent) -> None:
        if not event.is_directory and self._is_markdown(event.src_path):
            logger.debug(f"[Watcher] MODIFY: {event.src_path}")
            self._indexer.index_file(event.src_path)

    def on_deleted(self, event: FileSystemEvent) -> None:
        if not event.is_directory and self._is_markdown(event.src_path):
            vault = Path(settings.OBSIDIAN_VAULT_PATH)
            relative = str(Path(event.src_path).relative_to(vault))
            logger.debug(f"[Watcher] DELETE: {relative}")
            self._indexer.remove_file(relative)

    def on_moved(self, event: FileSystemEvent) -> None:
        if not event.is_directory:
            vault = Path(settings.OBSIDIAN_VAULT_PATH)
            if self._is_markdown(str(event.src_path)):
                old_relative = str(Path(event.src_path).relative_to(vault))
                self._indexer.remove_file(old_relative)
            if self._is_markdown(str(event.dest_path)):
                self._indexer.index_file(str(event.dest_path))


class VaultWatcher:
    """Inicia o monitoramento do Vault e dispara reindexações automaticamente."""

    def __init__(self) -> None:
        self._indexer = VaultIndexer()
        self._observer = Observer()

    def start(self) -> None:
        handler = _VaultEventHandler(self._indexer)
        self._observer.schedule(handler, path=settings.OBSIDIAN_VAULT_PATH, recursive=True)
        self._observer.start()
        logger.info(f"VaultWatcher iniciado em: {settings.OBSIDIAN_VAULT_PATH}")

    def stop(self) -> None:
        self._observer.stop()
        self._observer.join()
        logger.info("VaultWatcher encerrado.")
```

### Integração no `main.py`

```python
# Em main.py — iniciar o watcher junto com a aplicação FastAPI
from app.obsidian.watcher.vault_watcher import VaultWatcher

watcher = VaultWatcher()

@app.on_event("startup")
async def startup_event() -> None:
    watcher.start()

@app.on_event("shutdown")
async def shutdown_event() -> None:
    watcher.stop()
```

---



## 7. Endpoint de Indexação Manual (`api/`)

```python
@router.post("/indexing/full")
async def full_reindex(indexer: VaultIndexer = Depends()) -> dict:
    """Dispara a reindexação completa do Vault via API."""
    return indexer.index_vault()
```

---



## Dependências Desta Fase

- [[Fase 3 - Servico Obsidian]] — ObsidianService para leitura de arquivos



## Desbloqueia

- [[Fases 6-7 - Watcher LangGraph e Memoria]] — O LangGraph usará o `SemanticRetriever` como primeira etapa do grafo

## Resumo
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

## Ultima Atualizacao
- Informações pendentes de validação ou auto-geração.
