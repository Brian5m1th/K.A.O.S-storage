---
id: user_guide
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Guia do Usuário — K.A.O.S

## Interface Principal

Ao acessar `http://localhost:1420`, você verá a interface desktop com:

```
┌──────────┬─────────────────────────────────────────────┐
│ Sidebar  │              Conteúdo Principal              │
│          │                                             │
│ Dashboard│  <-- Página atual                            │
│ Chat     │                                             │
│ Orquest. │                                             │
│ Agents   │                                             │
│ Pipelines│                                             │
│ Knowledge│                                             │
│ Obsrvblty│                                             │
│ Doc Hlth │                                             │
│ Settings │                                             │
├──────────┴─────────────────────────────────────────────┤
│ Status: online                                        │
└────────────────────────────────────────────────────────┘
```

### Sidebar
Navegue entre as páginas clicando nos itens da sidebar à esquerda.

### Command Palette (CTRL+K)
Pressione `Ctrl+K` (ou `Cmd+K` no Mac) para abrir a paleta de comandos. Digite para buscar:

| Comando | O que faz |
|---------|-----------|
| `Go to Dashboard` | Abre o dashboard |
| `Open Chat` | Abre o chat |
| `Run Documentation Audit` | Executa auditoria |
| `Show Undocumented Features` | Mostra features sem doc |
| `Open Documentation Health` | Abre painel de saúde documental |

---

## Chat

Acesse via sidebar > **Chat** ou `Ctrl+K` > "Open Chat".

```bash
# Ou via terminal:
API_KEY=$(cat data/api_key.txt)
curl -X POST http://localhost:8000/api/chat/message \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"message": "Ola, quem e voce?"}'
```

### Funcionalidades
- Streaming de respostas em tempo real (SSE)
- Suporte a múltiplos provedores (Ollama, OpenAI, Anthropic, Gemini)
- Seleção de modelo no seletor
- Tool calls automáticos (o modelo pode usar ferramentas)
- Salvamento automático de conversas

---

## Agents

Acesse via sidebar > **Agents**.

Gerencie agentes de IA:

| Ação | Descrição |
|------|-----------|
| Listar | Visualiza todos os agentes |
| Criar | Adiciona novo agente |
| Editar | Modifica configurações |
| Remover | Exclui agente |

### Configurações de Agente

```yaml
# docs/wiki/AGENTS.md
nome: Meu Agente
modelo: llama3.2:3b
sistema: "Você é um assistente útil."
ferramentas: [read_note, search_notes]
```

---

## Workflows

Acesse via sidebar > **Orquestração**.

Workflows disponíveis:

| Workflow | Descrição | Capacidades |
|----------|-----------|-------------|
| `chat` | Chat padrão | fast_chat |
| `reasoning` | Raciocínio avançado | reasoning |
| `coding` | Geração de código | coding |
| `rag` | Chat com contexto do vault | fast_chat, rag |
| `agent` | Agente com ferramentas | fast_chat, tool_calling |

---

## Pipelines

Acesse via sidebar > **Pipelines**.

Configure e execute pipelines de CI/CD.

---

## Knowledge Vault

Acesse via sidebar > **Knowledge**.

O vault é sincronizado com um repositório Obsidian. As notas são indexadas automaticamente e ficam disponíveis para consulta via RAG.

### Como usar
1. Crie notas no seu vault Obsidian
2. O watcher detecta mudanças automaticamente
3. As notas são indexadas no Qdrant
4. O chat pode consultar o vault para contexto

### Estrutura do Vault
```
docs/vault/
├── 00-index/
├── 01-features/
├── 02-systems/
├── 03-runtime/
├── 04-architecture/
├── 05-auto-generated/
└── _templates/
```

---

## Observability

Acesse via sidebar > **Observability**.

### Métricas (Prometheus)
```bash
curl http://localhost:8000/metrics
```

### Grafana
Acesse `http://localhost:3000` (login: admin / admin).

Dashboards disponíveis:
- **K.A.O.S Overview**: Status geral do sistema
- **LLM Performance**: Latência e tokens por provedor
- **Audit Coverage**: Cobertura documental ao longo do tempo

### Logs (Loki)
Consulte logs no Grafana (datasource: Loki) ou diretamente:

```bash
tail -f logs/kaos-api.json
```

---

## Settings

Acesse via sidebar > **Settings**.

### Configurações Disponíveis
| Seção | Descrição |
|-------|-----------|
| Theme | Alternar entre claro/escuro |
| Server | URL e API Key do backend |
| Profile | Perfis de modelo do usuário |
| Providers | Configuração de provedores LLM |

---

## Documentation Health

Acesse via sidebar > **Doc Health** ou `Ctrl+K` > "Open Documentation Health".

### Visão Geral

```
Documentation Health
┌──────────┬──────────┬──────────┬──────────┐
│ Coverage │ Missing  │ Outdated │ Last Scan│
│  87.5%   │    6     │    3     │ 10:30 AM │
└──────────┴──────────┴──────────┴──────────┘

[Overview] [Missing] [Outdated] [Timeline]
```

### Ações
| Botão | Descrição |
|-------|-----------|
| Run Audit | Executa auditoria completa |
| View Undocumented Features | Mostra features sem SDD |
| View Outdated SDDs | Mostra SDDs desatualizados |
| Generate Documentation | Gera SDDs automaticamente |
| Sync Documentation | Sincroniza docs com código |
| Export Architecture | Exporta relatório JSON |

### Interpretação
- **Coverage**: % de features com documentação associada
- **Drift Level**: Baixo (>85%), Médio (70-85%), Alto (<70%)
- **Missing Features**: Features no código sem SDD
- **Outdated SDDs**: SDDs que não refletem o código atual

---

## Architecture Graph

Acesse via sidebar > **Doc Health** > (ou navegue para `/architecture`).

### Navegação
| Ação | Como fazer |
|------|------------|
| Zoom | Scroll do mouse |
| Pan | Arrastar com o mouse |
| Selecionar nó | Clique em um círculo |
| Filtrar por tipo | Painel lateral "Node Types" |
| Mudar layout | Botões "Force / Hierarchical / Radial" |

### Legendas
| Cor | Tipo |
|-----|------|
| 🔵 Azul | Feature |
| 🟢 Verde | Store |
| 🟡 Amarelo | Route |
| 🟣 Roxo | Tool |
| 🔴 Vermelho | Agent |
| 🔷 Ciano | Event |
| 🟠 Laranja | Provider |
| ⚪ Cinza | SDD |

### Exportação
| Formato | Como |
|---------|------|
| JSON | "Export JSON" no painel lateral |
| GraphML | "Export GraphML" (compatível com yEd, Gephi) |
| SVG | "Export SVG" (imagem vetorial) |

---

## Atalhos de Teclado

| Atalho | Ação |
|--------|------|
| `Ctrl+K` | Abrir Command Palette |
| `Ctrl+1` | Dashboard |
| `Ctrl+2` | Chat |
| `Ctrl+3` | Orquestração |
| `Ctrl+4` | Agents |
| `Ctrl+5` | Pipelines |
| `Ctrl+6` | Knowledge |
| `Ctrl+7` | Observability |
| `Ctrl+8` | Doc Health |
| `Ctrl+9` | Settings |
| `Esc` | Fechar modal / Command Palette |

---

## Exemplos de Uso

### 1. Conversar com IA

```
1. Clique em "Chat" na sidebar
2. Digite "Ola, mundo!" no campo de texto
3. Pressione Enter
4. Veja a resposta sendo gerada em tempo real
```

### 2. Executar Auditoria

```
1. Clique em "Doc Health" na sidebar
2. Clique em "Run Audit"
3. Aguarde o scan (alguns segundos)
4. Veja a cobertura e problemas encontrados
```

### 3. Navegar na Arquitetura

```
1. Clique em "Doc Health" > "Architecture Graph"
2. Use o scroll para zoom
3. Arraste para navegar
4. Clique em um nó para ver detalhes
5. Mude o layout para "Hierarchical"
```

### 4. Buscar no Vault

```
1. No chat, pergunte: "O que tem no vault sobre agentes?"
2. O sistema busca no Qdrant e responde com contexto
```

### 5. Usar Command Palette

```
1. Pressione Ctrl+K
2. Digite "run audit"
3. Pressione Enter
4. A auditoria começa automaticamente
```

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
