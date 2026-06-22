# Guia Obsidian — K.A.O.S

## Visão Geral

O Obsidian é o sistema de conhecimento do K.A.O.S. O vault armazena toda a documentação do projeto e é a fonte para:
- **RAG**: Consulta semântica via Qdrant
- **Graph View**: Navegação visual entre documentos
- **KIRL**: Auditoria documental
- **Graphify**: Grafo da arquitetura
- **Wiki**: Conhecimento incremental

---

## Estrutura do Vault

```
docs/vault/
├── 00-index/               ← Páginas de índice
├── 01-features/            ← Features do sistema
├── 02-systems/             ← Módulos e subsistemas
├── 03-runtime/             ← Estado runtime do KIRL
├── 04-architecture/        ← Decisões arquiteturais
├── 05-auto-generated/      ← SDDs gerados automaticamente
└── _templates/             ← Templates para novas notas
```

---

## Schema Oficial de Frontmatter

Toda nota no vault **deve** ter frontmatter YAML:

```yaml
---
id: feature-chat-streaming
title: Chat Streaming Feature
type: feature              # Obrigatório
owner: frontend            # Obrigatório
status: implemented        # Obrigatório
tags: [chat, sse]          # Opcional
links:                     # Opcional
  - system.event-bus
  - tool.schema
created: 2026-06-22        # Opcional
updated: 2026-06-22        # Opcional
drift: low                 # Opcional (preenchido pelo KIRL)
---
```

### Tipos Permitidos

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `feature` | Funcionalidade do sistema | Chat Streaming |
| `sdd` | Software Design Document | SDD-040 |
| `agent` | Agente de IA | Meu Agente |
| `workflow` | Workflow executável | Chat Workflow |
| `service` | Serviço interno | LLM Service |
| `store` | Zustand store | Chat Store |
| `event` | Evento do Event Bus | request_started |
| `api` | Endpoint de API | POST /api/chat |
| `page` | Página do frontend | Documentation Page |
| `integration` | Integração externa | N8N Integration |
| `system` | Subsistema do K.A.O.S | Event Bus |
| `generated` | SDD auto-gerado pelo KIRL | AUTO-SDD-feature |

### Owners Permitidos

| Owner | Descrição |
|-------|-----------|
| `backend` | Módulo Python/FastAPI |
| `frontend` | Módulo React/TypeScript |
| `shared` | Compartilhado entre camadas |
| `infrastructure` | Docker, CI/CD, deploy |

### Status Permitidos

| Status | Descrição |
|--------|-----------|
| `planned` | Planejado, não iniciado |
| `in-progress` | Em desenvolvimento |
| `implemented` | Implementado e funcional |
| `deprecated` | Substituído ou removido |

---

## Wikilinks

Use `[[id-da-nota]]` para criar links entre notas:

```markdown
O [[chat-streaming]] depende do [[event-bus]] e do [[tool-schema]].
```

Isso alimenta tanto o Graph View do Obsidian quanto o Graphify do K.A.O.S.

### Links no YAML

Além dos wikilinks no corpo do texto, declare links no frontmatter:

```yaml
links:
  - system.event-bus
  - tool.schema
  - agent.runtime
```

---

## Tags

Use tags para categorizar e filtrar:

```yaml
tags: [chat, streaming, sse, tool-calls]
```

Tags comuns do K.A.O.S:

| Tag | Quando usar |
|-----|-------------|
| `#chat` | Funcionalidades de chat |
| `#sse` | Streaming |
| `#tool` | Ferramentas LangGraph |
| `#agent` | Agentes |
| `#workflow` | Workflows |
| `#provider` | Provedores LLM |
| `#rag` | RAG pipeline |
| `#observability` | Métricas, logs |
| `#security` | Segurança |
| `#kirl` | Documentação Runtime Layer |
| `#graph` | Graphify |
| `#auto-generated` | SDD gerado automaticamente |

---

## Graph View

O Obsidian possui Graph View nativo (Ctrl+G).

### Configuração Recomendada

```json
// .obsidian/graph.json
{
  "collapse-filter": false,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": false,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    {"query": "path:01-features", "color": {"a": 1, "rgb": 5980671}},
    {"query": "path:02-systems", "color": {"a": 1, "rgb": 10921504}},
    {"query": "path:04-architecture", "color": {"a": 1, "rgb": 16750848}}
  ]
}
```

### Grupos de Cor por Diretório

| Diretório | Cor | Tipo |
|-----------|-----|------|
| `01-features/` | 🔵 Azul | Features |
| `02-systems/` | 🟢 Verde | Sistemas |
| `03-runtime/` | 🟡 Amarelo | Runtime/KIRL |
| `04-architecture/` | 🟠 Laranja | Arquitetura |
| `05-auto-generated/` | ⚪ Cinza | Auto-gerados |

---

## Drift Heatmap

O KIRL analisa o vault e produz heatmaps de drift arquitetural.

### Cores do Heatmap

| Cor | Significado |
|-----|-------------|
| 🟢 Verde | Documentado e consistente |
| 🟡 Amarelo | Documentado mas desatualizado |
| 🔴 Vermelho | Sem documentação ou inconsistente |
| ⚫ Preto | Feature órfã (sem dono) |

### Como Interpretar

```
[Feature]        [Código]  [SDD]     [Drift]
Chat Streaming   ✅        ✅        🟢
Memory Workflow  ✅        ❌        🔴
Event Bus        ✅        🟡        🟡
```

---

## Sincronização com K.A.O.S

### Fluxo de Sincronização

```
Obsidian Vault (edição manual)
    ↓
VaultWatcher (detecta mudanças)
    ↓
VaultIndexer (indexa no Qdrant)
    ↓
KIRL (audita documentação)
    ↓
Graphify (atualiza grafo)
    ↓
Dashboard (atualiza UI)
```

### Automática

O `SDDWatcher` no backend monitora mudanças a cada 10 segundos e:
1. Detecta arquivos novos/modificados
2. Sincroniza com o vault
3. Atualiza o DRL Snapshot
4. Emite eventos no Event Bus

### Manual

```bash
# Forçar sincronização do vault
# Acesse /documentation e clique em "Sync Documentation"
```

---

## Templates

### Template de Feature

```markdown
---
id: minha-feature
title: Minha Feature
type: feature
owner: frontend
status: planned
tags: []
links: []
---

# Minha Feature

## Descrição
...

## Responsabilidades
- ...

## Emits
- ...

## Used By
- ...
```

### Template de Sistema

```markdown
---
id: meu-sistema
title: Meu Sistema
type: system
owner: backend
status: planned
tags: []
links: []
---

# Meu Sistema

## Descrição
...

## Eventos
- ...

## Dependências
- ...
```

---

## Boas Práticas

1. **Sempre inclua frontmatter** — sem frontmatter, o nó não existe para o KIRL
2. **Use IDs únicos** — evite colisão entre nomes de nota
3. **Declare links nos dois lugares** — frontmatter (para Graphify) e wikilinks (para Obsidian)
4. **Mantenha tags consistentes** — use as tags padronizadas do K.A.O.S
5. **Atualize o status** — mantenha `status` sempre refletindo a realidade
6. **Nunca edite `05-auto-generated/`** — arquivos gerados pelo KIRL serão sobrescritos
7. **Use o template correto** — feature para features, system para sistemas, etc.

---

## Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| Nó não aparece no Graph View | Falta frontmatter `id` | Adicione `id: ...` |
| Wikilink quebrado | ID não encontrado | Verifique se o ID existe em outra nota |
| Drift vermelho inesperado | Feature sem SDD | Crie SDD ou registre no FeatureRegistry |
| Sincronização não funciona | VaultWatcher não iniciado | Verifique logs do backend |
