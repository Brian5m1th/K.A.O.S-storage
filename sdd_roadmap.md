Source: Notas no ClickUp
Tags: #sdd #roadmap #ia-pessoal #obsidian #langgraph #fases
Related: [[index]] [[backlog]] [[00_visao_geral]] [[sdd_obsidian_memoria]] [[sdd_obsidian_rag]] [[sdd_obsidian_tools]] [[sdd_obsidian_watcher]] [[estrategia_repositorios]]

# SDD — Roadmap Inicial da IA Offline com Obsidian

## Objetivo

Construir uma assistente de IA pessoal capaz de operar offline utilizando conhecimento armazenado em um Vault Obsidian e executar integrações externas através do N8N.

---

## Arquitetura Alvo

```text
Usuário
 ↓
Open WebUI
 ↓
FastAPI
 ↓
LangGraph
 ↓
Obsidian
 ↓
Qdrant
 ↓
N8N
```

---

## Fase 1 — Fundação

### Entregáveis
* Python 3.13
* FastAPI
* Docker
* Open WebUI

### Critério de Sucesso
Projeto base rodando localmente com testes passando e endpoint `/health` respondendo `200 OK`.

---

## Fase 2 — IA Local

### Entregáveis
* Ollama
* Qwen3 14B
* `LLMService`

### Critério de Sucesso
Usuário consegue conversar com a IA localmente, via streaming, sem internet.

---

## Fase 3 — Integração Obsidian

### Entregáveis
* `ObsidianService`
* `ReadNoteTool`
* `SearchNotesTool`
* `CreateNoteTool`
* `UpdateNoteTool`
* `DeleteNoteTool`

### Critério de Sucesso
A IA (via código Python) consegue ler, criar, atualizar e excluir notas e fazer busca textual local.

---

## Fase 4 — Organização do Vault

### Estrutura
* `Projetos`, `Arquitetura`, `SDD`, `Estudos`, `IA`, `Java`, `Python`, `AWS`, `CI-CD`, `Diário`

### Critério de Sucesso
A IA categoriza conteúdos automaticamente nas pastas corretas.

---

## Fase 5 — RAG

### Tecnologias
* Qdrant
* Sentence Transformers (`bge-m3`)

### Critério de Sucesso
A IA encontra informações no Vault por significado e intenção, recuperando o contexto para enriquecer o prompt do LLM.

---

## Fase 6 — Atualização Automática

### Tecnologias
* Watchdog (`VaultWatcher`)

### Critério de Sucesso
Criações e alterações realizadas diretamente no Obsidian são imediatamente detectadas e reindexadas no Qdrant.

---

## Fase 7 — Agente Inteligente

### Tecnologias
* LangGraph (`agent_graph`)

### Critério de Sucesso
O agente recebe a query do usuário, busca contexto, planeja se precisa de ferramentas (tools) e as executa autonomamente antes de responder.

---

## Fase 8 — Memória de Longo Prazo

### Funcionalidades
* Preferências, Projetos, Estudos
* Comando "salve esta conversa"

### Critério de Sucesso
A IA adapta respostas proativamente com base no histórico armazenado, mantendo a continuidade do conhecimento.

---

## Fase 9 — Integrações Online

### Tecnologias
* N8N, GitHub, Email, AWS

### Critério de Sucesso
A IA executa ações reais em sistemas externos por meio de webhooks do N8N.

---

## Fase 10 — Produção

### Entregáveis
* Autenticação
* Backups
* CI/CD
* Monitoramento

### Critério de Sucesso
Plataforma estável, segura e monitorável, pronta para uso contínuo e diário.

---

## Próximas Tarefas (Visão Imediata)

- [ ] Configurar caminho do Vault
- [ ] Implementar `ObsidianService`
- [ ] Ler primeira nota
- [ ] Criar primeira nota
- [ ] Implementar busca textual

---

## Visão Final

A plataforma deverá funcionar como um sistema de memória pessoal inteligente onde:
* **Obsidian** armazena conhecimento estruturado.
* **Qdrant** armazena contexto semântico.
* **LangGraph** coordena decisões do agente.
* **Ollama** executa inteligência localmente offline.
* **N8N** executa ações externas.
* **FastAPI** concentra e orquestra regras de negócio.
