---
id: installation
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Guia de Instalação — K.A.O.S

> [!TIP]
> **Instalação Automática no Windows:** Para facilitar o setup do ambiente completo de desenvolvimento, execute o script `.\setup.ps1` no PowerShell como Administrador na raiz do projeto. Ele fará o download automático de todas as ferramentas e dependências descritas abaixo de forma automatizada.

## Requisitos Mínimos

| Componente | Versão | Obrigatório |
|-----------|--------|:-----------:|
| Python | 3.13 | ✅ |
| Node.js | 18+ | ✅ |
| Docker | 24+ | ✅ |
| Docker Compose | 2.20+ | ✅ |
| Ollama | 0.3+ | ✅ |
| Rust (Tauri) | 1.70+ | ✅ (para build desktop) |

### Verificação Inicial

```bash
python --version     # >= 3.13
node --version       # >= 18
docker --version     # >= 24
docker compose version  # >= 2.20
ollama --version     # >= 0.3
```

---

## 1. Clonar o Repositório

```bash
git clone https://github.com/Brian5m1th/K.A.O.S.git
cd K.A.O.S
git checkout dev
```

O projeto possui um submódulo para o vault do Obsidian:

```bash
git submodule init
git submodule update
```

---

## 2. Backend (Python / FastAPI)

### 2.1 Instalar Python 3.13

**Windows:**
```bash
# Baixe o instalador em https://python.org
# Ou via winget
winget install Python.Python.3.13
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3.13 python3.13-venv
```

### 2.2 Instalar UV (Package Manager)

```bash
# Windows (PowerShell)
powershell -ExecutionMethod Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2.3 Configurar Ambiente

```bash
cd assistant
uv sync
```

Isso cria o ambiente virtual e instala todas as dependências.

### 2.4 Configurar Variáveis de Ambiente

```bash
# Copie o arquivo de exemplo
cp .env.example .env
# Edite conforme necessário
```

Variáveis principais no `.env`:

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `APP_ENV` | `development` | Ambiente |
| `APP_PORT` | `8000` | Porta do backend |
| `LOG_LEVEL` | `INFO` | Nível de log |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | URL do Ollama |
| `QDRANT_HOST` | `localhost` | Host do Qdrant |
| `QDRANT_PORT` | `6333` | Porta do Qdrant |
| `DATABASE_URL` | `postgresql+asyncpg://...` | URL do PostgreSQL |

### 2.5 Executar Backend

```bash
uv run uvicorn app.main:app --reload --port 8000
```

Acesse `http://localhost:8000/docs` para o Swagger UI.

---

## 3. Desktop (Tauri + React + TypeScript)

### 3.1 Instalar Rust

**Windows:**
```bash
# Baixe o instalador em https://rustup.rs
# Ou via winget
winget install Rustlang.Rustup
```

**Linux/macOS:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 3.2 Instalar Dependências

```bash
cd desktop
npm install
```

### 3.3 Executar em Modo Desenvolvimento

```bash
npm run dev
```

Acesse `http://localhost:1420`.

### 3.4 Build de Produção

```bash
npm run build
```

O instalador será gerado em `desktop/src-tauri/target/release/bundle/`.

---

## 4. Infraestrutura (Docker)

### 4.1 Subir Serviços

```bash
cd infra/docker
docker compose up -d
```

### 4.2 Serviços Disponíveis

| Serviço | Porta | Acesso |
|---------|-------|--------|
| PostgreSQL | 5432 | `localhost:5432` |
| Qdrant | 6333 | `localhost:6333` |
| Ollama | 11434 | `localhost:11434` |
| n8n | 5678 | `http://localhost:5678` |
| Prometheus | 9090 | `http://localhost:9090` |
| Loki | 3100 | `http://localhost:3100` |
| Grafana | 3000 | `http://localhost:3000` |
| Open WebUI | 3000 | `http://localhost:3000` |
| K.A.O.S API | 8000 | `http://localhost:8000` |

### 4.3 Verificar Status

```bash
docker compose ps
```

### 4.4 Logs

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f kaos-api
```

### 4.5 Parar Serviços

```bash
docker compose down
```

Para remover volumes (dados):

```bash
docker compose down -v
```

---

## 5. Ollama

### 5.1 Instalar Ollama

**Windows:** Baixe o instalador em [ollama.com](https://ollama.com)

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 5.2 Baixar Modelos

```bash
# Modelo recomendado para começar
ollama pull llama3.2:3b

# Modelo para embeddings
ollama pull nomic-embed-text

# Modelo para código
ollama pull codellama:7b

# Listar modelos instalados
ollama list
```

### 5.3 Verificar Funcionamento

```bash
ollama run llama3.2:3b "Olá, mundo!"
```

---

## 6. PostgreSQL

### 6.1 Via Docker (Recomendado)

O PostgreSQL já está incluído no `docker-compose.yml`. Para acesso manual:

```bash
docker exec -it infra-postgres-1 psql -U ai-p -d kaos
```

### 6.2 Migrations

As migrations são executadas automaticamente na inicialização do backend:

```bash
# Manualmente, se necessário
uv run alembic upgrade head
```

---

## 7. Qdrant

### 7.1 Via Docker (Recomendado)

O Qdrant já está incluído no `docker-compose.yml`.

### 7.2 Verificar

```bash
curl http://localhost:6333/health
# Resposta esperada: {"ok":true}
```

---

## 8. n8n (Opcional)

### 8.1 Acessar

```bash
open http://localhost:5678
```

### 8.2 Configurar Webhook

O webhook do n8n é configurado via variável de ambiente:

```
N8N_WEBHOOK_URL=http://localhost:5678/webhook/kaos
```

---

## 9. Observabilidade

### 9.1 Prometheus

```bash
open http://localhost:9090
```

Métricas disponíveis em `http://localhost:8000/metrics`.

### 9.2 Grafana

```bash
open http://localhost:3000
# Login: admin / admin
```

Dashboards importados automaticamente de `infra/grafana/dashboards/`.

### 9.3 Loki

```bash
open http://localhost:3100/ready
```

Logs do backend em `logs/kaos-api.json`.

---

## 10. GitHub Actions (CI/CD)

O projeto possui workflows configurados em `.github/workflows/`:

- **CI**: Ruff lint + pytest + TypeScript typecheck
- **Release**: Build desktop + publish

Para executar manualmente:

```bash
# Lint Python
cd assistant
uv run ruff check .

# Testes
uv run pytest

# TypeScript
cd desktop
npx tsc --noEmit
```

---

## 11. Verificação Pós-Instalação

### Checklist

```bash
# 1. Backend está rodando?
curl http://localhost:8000/health
# → {"status":"ok","version":"0.1.0"}

# 2. API Key foi gerada?
cat data/api_key.txt
# → (hash de 32 caracteres)

# 3. Ollama está respondendo?
curl http://localhost:11434/api/tags
# → {"models":[...]}

# 4. Qdrant está saudável?
curl http://localhost:6333/health
# → {"ok":true}

# 5. PostgreSQL está acessível?
docker exec infra-postgres-1 pg_isready
# → /var/run/postgresql:5432 - accepting connections

# 6. Desktop está compilando?
cd desktop
npx tsc --noEmit
# → (sem erros)

# 7. Testes estão passando?
cd assistant
uv run pytest
# → (todos verdes)
```

---

## Troubleshooting Comum

| Problema | Causa | Solução |
|----------|-------|---------|
| `uv` não encontrado | UV não instalado | `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` |
| Porta 8000 ocupada | Outro processo | `npx kill-port 8000` ou mude a porta |
| Docker não encontra imagem | Docker não iniciado | Inicie Docker Desktop ou `systemctl start docker` |
| Ollama connection refused | Ollama não rodando | `ollama serve` |
| Qdrant connection refused | Qdrant não rodando | `docker compose up -d qdrant` |
| `npm install` falha | Rust não instalado | `rustup install stable` |
| `api_key.txt` não encontrado | Primeira execução | O backend gera automaticamente |

---

## Próximos Passos

Após a instalação, siga o [Guia de Primeira Execução](FIRST_RUN.md) para validar que tudo está funcionando.

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
