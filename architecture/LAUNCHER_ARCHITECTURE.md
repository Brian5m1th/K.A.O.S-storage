---
type: knowledge
domain: arquitetura
status: active
---

# Arquitetura do Launcher — K.A.O.S

> Documento de arquitetura do instalador/gerenciador automatizado do K.A.O.S.

## Parent
- [[Arquitetura Geral]]

## Children
- [[DESKTOP_ARCHITECTURE]]

## Related
- [[SETUP]]
- [[DESKTOP_ARCHITECTURE]]

## Tags
#kaos #arquitetura #launcher #setup #devops

---

## 1. Visão Geral

O Launcher é uma ferramenta que automatiza o setup completo do K.A.O.S, eliminando a necessidade de instalar e configurar manualmente cada dependência (Python, Node.js, Rust, Docker, Qdrant, PostgreSQL, Ollama).

### Objetivos

- **Zero-clique**: um único comando instala tudo que é necessário
- **Cross-platform**: Windows (PowerShell), Linux/macOS (bash)
- **Idempotente**: pode ser executado múltiplas vezes sem efeitos colaterais
- **Offline-first**: baixa assets uma vez, reusa em instalações futuras
- **Auto-update**: o próprio launcher se atualiza

---

## 2. Atores

- **Usuário final** — executa o launcher para instalar/configurar o K.A.O.S
- **Sistema** — o launcher gerencia dependências, containers e configurações
- **GitHub Releases** — fonte dos assets do launcher e do desktop app

---

## 3. Fluxo Principal

```
Usuário baixa script → Launcher detecta SO →
  ├── Verifica pré-requisitos (git, Docker, Python, Node, Rust)
  ├── Instala dependências faltantes
  ├── Clona repo (ou atualiza)
  ├── Sobe infraestrutura via Docker Compose (Qdrant, PostgreSQL)
  ├── Configura ambiente (.env, API key)
  ├── Inicia backend (uv run uvicorn)
  └── Abre navegador em http://localhost:8000
```

### 3.1 Detecção de Ambiente

| Sistema | Script | Gerenciador de Pacotes |
|---------|--------|----------------------|
| Windows | `install.ps1` | `winget`, Docker Desktop |
| macOS | `install.sh` | `brew`, `colima` (Docker) |
| Linux | `install.sh` | `apt`/`dnf`/`pacman`, `docker.io` |

### 3.2 Verificação de Dependências

O launcher verifica cada dependência e instala apenas as que estão faltando:

| Dependência | Windows | macOS | Linux |
|-------------|---------|-------|-------|
| Git | `winget install Git.Git` | `brew install git` | `apt install git` |
| Python 3.12+ | `winget install Python.Python.3.12` | `brew install python@3.12` | `apt install python3.12` |
| Node.js 20+ | `winget install OpenJS.NodeJS.LTS` | `brew install node@20` | `apt install nodejs` |
| Rust 1.79+ | `winget install Rustlang.Rustup` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` |
| uv | script oficial | script oficial | script oficial |
| Docker | Docker Desktop (winget) | `brew install --cask docker` | `apt install docker.io` |

### 3.3 Clonagem do Repositório

```bash
git clone --recurse-submodules https://github.com/Brian5m1th/K.A.O.S.git
cd K.A.O.S
```

- Se o diretório já existe, faz `git pull`
- Verifica se o submodule `docs/vault/` está acessível (PAT necessário)
- Se falhar, continua sem o submodule (docs não críticos para funcionamento)

### 3.4 Infraestrutura (Docker Compose)

O launcher executa:

```bash
cd infra/docker
docker compose up -d
```

Isso sobe:
- `kaos-api` (FastAPI)
- `prometheus` + `loki` + `promtail` + `grafana`

O launcher também sobe containers individuais se o Docker Compose não estiver disponível:
- `qdrant/qdrant` (porta 6333)
- `postgres:16` (porta 5432)
- `ollama/ollama` (porta 11434)

### 3.5 Configuração de Ambiente

O launcher gera o arquivo `.env`:

```env
APP_ENV=production
DATABASE_URL=postgresql+psycopg://kaos:kaos@localhost:5432/kaos
OLLAMA_BASE_URL=http://localhost:11434
LOG_LEVEL=INFO
API_KEY=<uuid-gerado-automaticamente>
```

### 3.6 Inicialização do Backend

```bash
cd assistant
uv venv
uv sync
uv run uvicorn assistant.app.main:app --port 8000
```

O launcher gerencia o processo como serviço:
- **Windows**: cria uma task agendada ou serviço Windows
- **Linux/macOS**: cria um systemd service ou launchd plist

---

## 4. Auto-Update

O launcher verifica atualizações no GitHub Releases:

1. Na inicialização, checa `https://api.github.com/repos/Brian5m1th/K.A.O.S/releases/latest`
2. Compara versão local com a versão remota
3. Se há nova versão, baixa o script atualizado e executa migrações

---

## 5. Launcher Nativo (Tauri)

Para experiência ainda mais simples, um launcher nativo pode ser construído com Tauri v2:

```
Launcher Nativo (Tauri + Rust)
├── Janela de boas-vindas
├── Barra de progresso (instalação de dependências)
├── Terminal embutido (logs em tempo real)
└── Botão "Abrir K.A.O.S" ao finalizar
```

### Comunicação

```
Tauri (Rust) → Command::new("powershell"|"bash") → Script de instalação
```

O launcher nativo não substitui os scripts — ele os executa em uma janela com feedback visual.

---

## 6. Estrutura de Arquivos

```
K.A.O.S/
├── launcher/
│   ├── install.ps1          # Windows
│   ├── install.sh           # Linux/macOS
│   ├── launcher-tauri/      # Opcional: launcher nativo
│   │   ├── src-tauri/
│   │   └── src/
│   └── modules/
│       ├── check-deps.ps1   # Verificação de dependências
│       ├── install-deps.ps1 # Instalação de dependências
│       ├── docker.ps1       # Gerenciamento de containers
│       └── config.ps1       # Geração de .env
├── infra/
│   └── docker/
│       ├── docker-compose.yml
│       └── docker-compose.monitoring.yml
└── assistant/
    └── ...
```

---

## 7. Segurança

- O launcher nunca solicita credenciais como argumentos de linha de comando
- API keys são geradas automaticamente e salvas em `.env`
- O script verifica a assinatura dos assets baixados (Cosign)
- Docker images são puxadas de fontes oficiais (`qdrant/qdrant`, `postgres:16`, `ollama/ollama`)

---

## 8. Fluxos Alternativos

### 8.1 Sem Docker

Se Docker não estiver disponível e o usuário optar por não instalar:

- Launcher configura backend para usar SQLite em vez de PostgreSQL
- Embeddings usam sentence-transformers local (sem Qdrant)
- Memória usa Obsidian local (sem banco vetorial)

### 8.2 Atualização

1. Launcher detecta nova versão no GitHub
2. Faz `git pull` no repositório
3. Executa `uv sync` para atualizar dependências Python
4. Executa `docker compose pull` para atualizar imagens
5. Reinicia serviços

### 8.3 Rollback

1. Launcher mantém backup do `.env` anterior
2. `git checkout <tag-anterior>`
3. Restaura `.env` do backup
4. Reinicia serviços

---

## 9. Testes

| Teste | Tipo | O que valida |
|-------|------|-------------|
| `test_check_python` | Unit | Detecção correta da versão do Python |
| `test_install_docker` | Unit | Comando de instalação correto por SO |
| `test_generate_env` | Unit | Geração de .env com valores corretos |
| `test_full_install` | Integration | Execução completa em container Docker |
| `test_upgrade_flow` | Integration | Atualização de versão preserva config |

---

## 10. Critérios de Aceite

- [ ] Script de instalação funcional nos 3 SOs (Windows, macOS, Linux)
- [ ] Launcher detecta e instala dependências faltantes automaticamente
- [ ] Infraestrutura (Qdrant, PostgreSQL, Ollama) sobe via Docker
- [ ] Backend inicia e responde em `http://localhost:8000/health`
- [ ] Auto-update baixa e aplica nova versão sem perder configuração
- [ ] Rollback restaura versão anterior com configuração intacta
