---
type: knowledge
domain: ia
status: active
---

# Divisao de Texto (Chunking)
*Text Chunking & Splitting*

> Estrategia de divisao de notas Markdown em chunks preservando cabecalhos e paragrafos semanticos.

## Parent
- [[Fases 4-5 - Pipeline RAG e Watcher]]

## Children


## Related
- [[Busca Vetorial e RAG]]

## Tags
#kaos #ia #rag #chunking #markdown

---

## Conteudo
## 3. Text Splitter (`rag/chunking/text_splitter.py`)

Divisão preserva estrutura de cabeçalhos Markdown para manter o contexto semântico.

```python
import re
from dataclasses import dataclass

@dataclass
class TextChunk:
    content: str
    chunk_index: int
    source_path: str

class MarkdownSplitter:
    """Divide texto Markdown em chunks respeitando cabeçalhos e parágrafos."""

    def __init__(self, chunk_size: int = 800, overlap: int = 150) -> None:
        self._chunk_size = chunk_size
        self._overlap = overlap

    def split(self, text: str, source_path: str) -> list[TextChunk]:
        # Divide por seções de cabeçalho primeiro
        sections = re.split(r'\n(?=#{1,3} )', text)
        chunks: list[TextChunk] = []
        index = 0

        for section in sections:
            section = section.strip()
            if not section:
                continue

            # Se a seção cabe em um chunk, mantém inteira
            if len(section) <= self._chunk_size:
                chunks.append(TextChunk(content=section, chunk_index=index, source_path=source_path))
                index += 1
            else:
                # Quebra por parágrafos com overlap
                paragraphs = section.split("\n\n")
                buffer = ""
                for para in paragraphs:
                    if len(buffer) + len(para) > self._chunk_size and buffer:
                        chunks.append(TextChunk(content=buffer.strip(), chunk_index=index, source_path=source_path))
                        index += 1
                        # Mantém overlap do chunk anterior
                        buffer = buffer[-self._overlap:] + "\n\n" + para
                    else:
                        buffer += "\n\n" + para if buffer else para
                if buffer.strip():
                    chunks.append(TextChunk(content=buffer.strip(), chunk_index=index, source_path=source_path))
                    index += 1

        return chunks
```

---

