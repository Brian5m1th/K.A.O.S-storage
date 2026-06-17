Source: Antigravity AI
Tags: #qa #testes #uso #features
Related: [[index]] [[BackLog]]

# 🧪 Guia de Testes e Uso das Features

> Este documento é atualizado a cada nova funcionalidade desenvolvida. Ele centraliza os passos exatos para executar, testar e validar cada componente do sistema na ordem em que as Fases do [[BackLog]] são concluídas.

---

## 🚦 Tabela de Validação de Features

| Fase | Feature | Status do Teste | Comando / Método de Validação |
| :---: | :--- | :---: | :--- |
| **1** | Fundação (FastAPI & Docker) | 🟡 Parcial | `curl http://localhost:8000/health` |
| **2** | IA Local (Ollama) | ⬜ A fazer | Chat no Open WebUI (Local) |
| **3** | Obsidian Tools (CRUD local) | ⬜ A fazer | Executar Pytest nas Tools |
| **4** | Organização do Vault | ⬜ A fazer | Verificação visual das pastas |
| **5** | RAG (Embeddings & Qdrant) | ⬜ A fazer | Teste de similaridade no Qdrant API |
| **6** | Watchdog (Auto-sync) | ⬜ A fazer | Criar `.md` e checar logs de reindex |
| **7** | Agente (LangGraph) | ⬜ A fazer | Prompt que engatilha o uso de tools |
| **8** | Memória LP | ⬜ A fazer | Comando "salve esta conversa" |

---

## Fase 1 — Fundação do Projeto

### 1.1 Testando a Inicialização
**Objetivo:** Garantir que o ambiente Python e as dependências estão funcionando.
```bash
# Sincronizar o ambiente
uv sync

# Iniciar o servidor de desenvolvimento
uv run uvicorn app.main:app --reload --port 8000
```
**Resultado esperado:** Servidor rodando sem erros de importação.

### 1.2 Testando o Endpoint de Health
**Objetivo:** Validar que o FastAPI está escutando na porta correta.
```bash
# Em outro terminal:
curl -X GET http://localhost:8000/health
```
**Resultado esperado:**
```json
{"status": "ok", "version": "0.1.0"}
```

---

## Fase 2 — IA Local com Ollama

*(A fazer: Os testes reais ocorrerão quando esta fase for implementada)*

### 2.1 Testando o Ollama Nativo
**Objetivo:** Validar que o modelo `qwen3:14b` foi baixado e responde localmente.
```bash
ollama run qwen3:14b "Responda apenas 'Estou online'."
```

### 2.2 Testando a Interface Open WebUI
**Objetivo:** Garantir que o container do WebUI se comunica com o host (Ollama).
1. Subir o docker: `docker compose up -d open-webui`
2. Acessar `http://localhost:3000`
3. Selecionar o modelo `qwen3:14b` e enviar uma mensagem.

---

## Fase 3 — Integração Obsidian (Próxima Prioridade)

*(A fazer: Documentação de teste para quando a Fase 3 for desenvolvida)*

### 3.1 Testando Leitura e Criação de Notas
**Objetivo:** Validar o `ObsidianService`.
```bash
# Rodar os testes automatizados da camada de serviço
uv run pytest tests/unit/obsidian/
```
**Validação Manual via API/Script:**
1. Rodar um script de teste Python que chame `ObsidianService.create_note()`.
2. Abrir o Obsidian e verificar se o arquivo apareceu na pasta `Inbox/`.
3. Chamar `ObsidianService.search_text("palavra")` e verificar o log de retorno.

---

## Fases Futuras (A preencher conforme o desenvolvimento avança)

- **Fase 4 (Organização)**: Passos para rodar o script de setup das pastas iniciais do Vault.
- **Fase 5 (RAG)**: Passos para acessar o Dashboard do Qdrant (`http://localhost:6333/dashboard`) e validar os pontos (vectors) criados.
- **Fase 6 (Watchdog)**: Teste prático de criar, alterar e excluir uma nota no Obsidian enquanto se observa os logs do terminal do FastAPI (`[Watcher] CREATE`, etc.).
- **Fase 7 (LangGraph)**: Testes de unidade do grafo e testes de prompt (ex: "Pesquise no meu vault o que é Docker e me responda").
- **Fase 8 (Memória)**: Validação end-to-end de comandos naturais como "Me lembre disso amanhã".

---
*Este documento será incrementado com os scripts e prompts exatos à medida que o código for entregue.*
