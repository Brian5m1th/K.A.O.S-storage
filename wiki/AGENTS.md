---
type: knowledge
domain: obsidian
status: active
---

# ConfiguraçÃes de Agente
*K.A.O.S Knowledge Wiki - Agent Schema*

> Contrato de regras, convencoes de nomenclatura e fluxos que o LLM deve ler e seguir ao manipular a wiki do vault.

## Parent
- [[MemÓria do Obsidian]]

## Children
- [[index]]

## Related
- [[Estrutura da Wiki]]

## Tags
#kaos #obsidian #agent #schema

---

## Conteudo
# K.A.O.S Knowledge Wiki — Agent Schema

This file defines the conventions, workflows, and rules you must follow when maintaining the wiki. Consult it before every ingest, query, or maintenance operation.

---

## Directory Structure

```
wiki/
├── AGENTS.md              # This file — schema and conventions
├── AGENTS.pt-BR.md        # Portuguese version
├── index.md               # Live catalog of all wiki pages
├── log.md                 # Append-only timeline of changes
│
├── entities/              # Concrete objects: people, projects, technologies
├── concepts/              # Abstractions: RAG, embeddings, LangGraph
├── sources/               # Summaries of each ingested source
└── synthesis/             # Derived knowledge: analyses, comparisons, theses
```

---

## Frontmatter (Required)

Every wiki page MUST have YAML frontmatter:

```yaml
---
title: Page Name
type: entity | concept | source | synthesis
  - tag1
  - tag2
sources:
  - source_file_name
created: 2026-06-18
updated: 2026-06-18
---
```

- `type` must match the subdirectory (entities → entity, concepts → concept)
- `sources` lists the source pages the content is derived from
- `updated` is always the current date when modifying

---

## Naming Conventions

| Type       | Filename pattern              | Example                      |
|------------|-------------------------------|------------------------------|
| entity     | `entities/{kebab-case}.md`   | `entities/brian-smith.md`    |
| concept    | `concepts/{kebab-case}.md`   | `concepts/retrieval-augmented-generation.md` |
| source     | `sources/YYYY-MM-DD_slug.md` | `sources/2026-06-18_llm-wiki.md` |
| synthesis  | `synthesis/{kebab-case}.md`  | `synthesis/comparison-mamba-vs-rwkv.md` |

---

## Workflows

### Ingest

1. User provides a source or says "ingest this source"
2. Read the source completely from `raw/`
3. Discuss key takeaways with the user (ask for emphasis guidance)
4. Create/update pages **as drafts** (`.draft.md`):
   - One source page in `sources/`
   - Entity pages in `entities/` (new or updated)
   - Concept pages in `concepts/` (new or updated)
5. Present the drafts to the user for approval
6. On approval: rename `.draft.md` → `.md`, update `index.md`, append to `log.md`
7. Optionally reindex in Qdrant

### Query

1. Read `index.md` to find relevant pages
2. Read matching entity, concept, and synthesis pages
3. If context is insufficient, search Qdrant as fallback
4. Synthesize answer with citations to wiki pages
5. If the answer is substantive, suggest creating a synthesis page

### Draft Approval

- `approve_draft(path)`: renames `.draft.md` → `.md`, updates index and log
- `reject_draft(path)`: deletes `.draft.md`
- `list_drafts()`: shows all pending drafts

---

## Cross-Reference Rules

- Every entity or concept mentioned in a page should use `[[wiki/entities/slug|Name]]` format
- When creating a page, check if related pages need updating (backlinks)
- If a concept is mentioned 3+ times across the wiki but has no page, flag it
- If two pages contradict each other, note the contradiction explicitly

---

## Draft Mode

**No structural change is made without explicit user approval.**

All creation and update operations first create a `.draft.md` file. The user reviews and either approves (which finalizes) or rejects (which deletes). Only after approval do `index.md` and `log.md` get updated.

Exception: `append_log` can be called directly (it's append-only and non-destructive).

---

## Lint Checks

Periodically (or on demand) run `lint_wiki()` to check:
- **Contradictions**: pages making conflicting claims
- **Orphans**: pages with no inbound links
- **Missing concepts**: concepts mentioned often but undocumented
- **Broken links**: `[[links]]` to non-existent pages
- **Stale pages**: `updated` date too old relative to last ingest


