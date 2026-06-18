# K.A.O.S Knowledge Wiki — Schema do Agente

Este arquivo define as convenções, fluxos de trabalho e regras que você deve seguir ao manter a wiki. Consulte-o antes de toda ingestão, consulta ou operação de manutenção.

---

## Estrutura de Diretórios

```
wiki/
├── AGENTS.md              # Versão em inglês — schema e convenções
├── AGENTS.pt-BR.md        # Este arquivo — versão em português
├── index.md               # Catálogo vivo de todas as páginas wiki
├── log.md                 # Timeline append-only de alterações
│
├── entities/              # Objetos concretos: pessoas, projetos, tecnologias
├── concepts/              # Abstrações: RAG, embeddings, LangGraph
├── sources/               # Resumos de cada fonte ingerida
└── synthesis/             # Conhecimento derivado: análises, comparações, teses
```

---

## Frontmatter (Obrigatório)

Toda página wiki DEVE ter frontmatter YAML:

```yaml
---
title: Nome da Página
type: entity | concept | source | synthesis
tags:
  - tag1
  - tag2
sources:
  - nome_do_arquivo_fonte
created: 2026-06-18
updated: 2026-06-18
---
```

- `type` deve corresponder ao subdiretório (entities → entity, concepts → concept)
- `sources` lista as páginas de origem das quais o conteúdo é derivado
- `updated` é sempre a data atual ao modificar

---

## Convenções de Nomenclatura

| Tipo      | Padrão de nome                    | Exemplo                              |
|-----------|-----------------------------------|--------------------------------------|
| entity    | `entities/{kebab-case}.md`       | `entities/brian-smith.md`           |
| concept   | `concepts/{kebab-case}.md`       | `concepts/retrieval-augmented-generation.md` |
| source    | `sources/YYYY-MM-DD_slug.md`     | `sources/2026-06-18_llm-wiki.md`    |
| synthesis | `synthesis/{kebab-case}.md`      | `synthesis/comparacao-mamba-vs-rwkv.md` |

---

## Fluxos de Trabalho

### Ingestão

1. Usuário fornece uma fonte ou diz "ingira esta fonte"
2. Leia a fonte completamente de `raw/`
3. Discuta os principais pontos com o usuário (peça orientação sobre ênfase)
4. Crie/atualize páginas **como drafts** (`.draft.md`):
   - Uma página de source em `sources/`
   - Páginas de entidade em `entities/` (nova ou atualizada)
   - Páginas de conceito em `concepts/` (nova ou atualizada)
5. Apresente os drafts para aprovação do usuário
6. Após aprovação: renomeie `.draft.md` → `.md`, atualize `index.md`, adicione ao `log.md`
7. Opcionalmente, reindexe no Qdrant

### Consulta

1. Leia `index.md` para encontrar páginas relevantes
2. Leia as páginas de entidade, conceito e síntese correspondentes
3. Se o contexto for insuficiente, busque no Qdrant como fallback
4. Sintetize a resposta com citações para as páginas wiki
5. Se a resposta for substantiva, sugira criar uma página de síntese

### Aprovação de Draft

- `approve_draft(path)`: renomeia `.draft.md` → `.md`, atualiza index e log
- `reject_draft(path)`: deleta `.draft.md`
- `list_drafts()`: mostra todos os drafts pendentes

---

## Regras de Cross-Reference

- Toda entidade ou conceito mencionado em uma página deve usar o formato `[[wiki/entities/slug|Nome]]`
- Ao criar uma página, verifique se páginas relacionadas precisam de atualização (backlinks)
- Se um conceito for mencionado 3+ vezes na wiki mas não tiver página, sinalize
- Se duas páginas se contradizerem, anote a contradição explicitamente

---

## Modo Draft

**Nenhuma alteração estrutural é feita sem aprovação explícita do usuário.**

Todas as operações de criação e atualização primeiro criam um arquivo `.draft.md`. O usuário revisa e aprova (que finaliza) ou rejeita (que deleta). Apenas após a aprovação o `index.md` e `log.md` são atualizados.

Exceção: `append_log` pode ser chamado diretamente (é append-only e não destrutivo).

---

## Verificações de Lint

Periodicamente (ou sob demanda) execute `lint_wiki()` para verificar:
- **Contradições**: páginas com afirmações conflitantes
- **Órfãos**: páginas sem links de entrada
- **Conceitos ausentes**: conceitos mencionados frequentemente mas sem documentação
- **Links quebrados**: `[[links]]` para páginas inexistentes
- **Páginas desatualizadas**: data `updated` muito antiga relativa à última ingestão
