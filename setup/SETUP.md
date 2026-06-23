---
id: setup
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Setup — K.A.O.S

## Pré-requisitos

| Ferramenta | Versão Mínima | Instalação |
|------------|--------------|------------|
| Python | 3.12+ | `winget install Python.Python.3.12` |
| Node.js | 20+ | `winget install OpenJS.NodeJS.LTS` |
| Rust | 1.79+ | `winget install Rustlang.Rustup` |
| uv | 0.4+ | `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` |
| Docker | 24+ | `winget install Docker.DockerDesktop` |
| Git | 2.40+ | `winget install Git.Git` |

## Clonagem

```bash
git clone --recurse-submodules https://github.com/Brian5m1th/K.A.O.S.git
cd K.A.O.S
```

> O submodule `docs/vault/` (K.A.O.S-storage) é **privado**. Certifique-se de ter um PAT com escopo `repo` configurado no seu ambiente.

Se já clonou sem `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Backend (FastAPI)

```bash
cd assistant
uv venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\Activate.ps1  # Windows
uv sync
```

### Variáveis de Ambiente

Copie `.env.example` para `.env` e ajuste:

```env
APP_ENV=development
DATABASE_URL=postgresql+asyncpg://kaos:kaos@localhost:5432/kaos
OPENAI_API_KEY=sk-...          # opcional
ANTHROPIC_API_KEY=sk-ant-...   # opcional
GOOGLE_API_KEY=AIza...         # opcional
OLLAMA_BASE_URL=http://localhost:11434
LOG_LEVEL=INFO
API_KEY=kaos-dev-key           # chave para autenticação X-API-Key
```

### Executar

```bash
uv run uvicorn assistant.app.main:app --reload --port 8000
```

Acessar: `http://localhost:8000/docs`

## Desktop (Tauri + React)

```bash
cd src
npm install
```

### Executar em Desenvolvimento

```bash
npm run tauri dev
```

Isso inicia o Vite dev server + janela Tauri com hot reload.

### Build de Produção

```bash
npm run tauri build
```

O instalador será gerado em `src/src-tauri/target/release/bundle/`.

## Docker (Stack Completa)

```bash
cd infra/docker
docker compose up -d
```

Isso sobe:
- `kaos-api` (FastAPI na porta 8000)
- `prometheus` (9090)
- `loki` (3100)
- `promtail`
- `grafana` (3001 — admin/admin)

## Infraestrutura Adicional

### Qdrant (Vetorial)

```bash
docker run -d -p 6333:6333 qdrant/qdrant
```

### PostgreSQL

Via Docker:

```bash
docker run -d -p 5432:5432 \
  -e POSTGRES_USER=kaos \
  -e POSTGRES_PASSWORD=kaos \
  -e POSTGRES_DB=kaos \
  postgres:16
```

### Ollama

```bash
docker run -d -p 11434:11434 ollama/ollama
```

Baixar modelo padrão:

```bash
docker exec -it ollama ollama pull llama3.1:8b
```

## Verificação

Após iniciar tudo, execute:

```bash
# Healthcheck do backend
curl http://localhost:8000/health

# Verificar providers configurados
curl -H "X-API-Key: kaos-dev-key" http://localhost:8000/api/setup/provider

# Verificar métricas
curl http://localhost:8000/metrics

# Verificar Grafana
start http://localhost:3001  # ou open no Linux/macOS
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
