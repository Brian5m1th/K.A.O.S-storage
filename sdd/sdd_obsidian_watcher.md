Source: Notas no ClickUp
Tags: #sdd #obsidian #watcher #indexer #watchdog
Related: [[sdd_obsidian_memoria]] [[sdd_obsidian_rag]] [[sdd_obsidian_tools]]

# SDD Componente — File Watcher & Indexer Service

Este documento detalha o funcionamento interno do **File Watcher** (Monitor de Arquivos) e do **Indexer Service** (Serviço de Indexação). Juntos, eles garantem que o banco de dados de vetores (Qdrant) esteja sempre em sincronia com o estado físico das notas Markdown no Vault Obsidian.

---

## File Watcher (Monitor de Arquivos)

O File Watcher é um serviço em segundo plano executado via biblioteca `watchdog` (Python). Ele monitora recursivamente o diretório raiz do Vault Obsidian definido no `.env` (`OBSIDIAN_VAULT_PATH`).

### Fluxo de Eventos

O monitor escuta eventos nativos do sistema operacional e mapeia-os para ações específicas do Indexer.

```python
from watchdog.events import FileSystemEventHandler

class ObsidianVaultHandler(FileSystemEventHandler):
    def __init__(self, indexer_service):
        self.indexer = indexer_service

    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            self.indexer.queue_indexing(event.src_path)

    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            self.indexer.queue_reindexing(event.src_path)

    def on_deleted(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            self.indexer.queue_deletion(event.src_path)

    def on_moved(self, event):
        if not event.is_directory and event.dest_path.endswith('.md'):
            self.indexer.queue_move(event.src_path, event.dest_path)
```

---

## Indexer Service (Serviço de Indexação)

### Processo de Indexação

1. **Leitura e Parsing**: Lê o arquivo `.md` do disco, extrai YAML Frontmatter.
2. **Chunking Semântico**: `RecursiveCharacterTextSplitter` (500-1000 chars, overlap 100-200).
3. **Geração de Embeddings**: Envia chunk ao `Vector Search Service`.
4. **Upsert no Qdrant**: Payload inclui path, chunk_index, text, tags, updated_at.

### Robustez

- **Fila com Debounce**: 1-2s antes de executar indexação física.
- **Processamento Assíncrono**: Leitura do disco e chamadas Qdrant sem bloquear a thread principal.
- **Transações no Qdrant**: Remoção em massa de vetores antigos antes de inserir novos chunks.
