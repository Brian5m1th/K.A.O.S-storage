# K.A.O.S — Knowledge Assistant & Offline System

**Plataforma universal de orquestração de IA, agentes e automações baseada em capacidades.**

[![CI](https://github.com/Brian5m1th/K.A.O.S/actions/workflows/ci.yml/badge.svg)](https://github.com/Brian5m1th/K.A.O.S/actions)
[![Python 3.13](https://img.shields.io/badge/python-3.13-blue)](https://python.org)
[![React 18](https://img.shields.io/badge/react-18-61dafb)](https://react.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Quick Start

```bash
# 1. Backend
cd assistant
uv sync
uv run uvicorn app.main:app --reload

# 2. Desktop (outro terminal)
cd desktop
npm install
npm run dev

# 3. Infraestrutura (outro terminal)
cd infra/docker
docker compose up -d
```

Acesse `http://localhost:1420` para o desktop ou `http://localhost:8000/docs` para a API.

---

## Arquitetura (Resumo)

```
┌─────────────────────────────────────────────────────┐
│                   DESKTOP (Tauri)                    │
│  React 18 · TypeScript · Zustand · Tailwind · FSD   │
│  Event Bus · Command Palette · Router               │
└──────────────────────────┬──────────────────────────┘
                           │ HTTP/SSE
┌──────────────────────────▼──────────────────────────┐
│              BACKEND (Python / FastAPI)               │
│  LangGraph · SQLAlchemy · Qdrant · Ollama · OpenAI   │
│  Event Bus · Service Registry · Workflow Engine      │
│  KIRL (Documentation Runtime Layer)                  │
└──────────────────────────┬──────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────┐
│              INFRAESTRUTURA (Docker)                  │
│  PostgreSQL · Qdrant · Ollama · n8n · Prometheus     │
│  Loki · Grafana · Open WebUI                         │
└─────────────────────────────────────────────────────┘
```

### Camadas do Sistema

| Camada | Tecnologia | Finalidade |
|--------|-----------|------------|
| **Desktop** | Tauri + React + TypeScript | Interface gráfica do usuário |
| **Backend** | Python + FastAPI + LangGraph | Orquestração e lógica de negócio |
| **Providers** | Ollama, OpenAI, Anthropic, Gemini | Modelos de linguagem |
| **Vector DB** | Qdrant | Memória semântica e RAG |
| **Database** | PostgreSQL | Dados estruturados |
| **Observability** | Prometheus + Loki + Grafana | Métricas, logs e dashboards |
| **Automation** | n8n | Workflows de automação |
| **KIRL** | Python + TypeScript | Auditoria documental e drift arquitetural |

---

## Documentação

### Guias de Uso
| Guia | Descrição |
|------|-----------|
| [INSTALLATION.md](guides/INSTALLATION.md) | Instalação completa do zero |
| [FIRST_RUN.md](guides/FIRST_RUN.md) | Primeira execução e validação |
| [USER_GUIDE.md](guides/USER_GUIDE.md) | Como usar o sistema |
| [DEVELOPER_GUIDE.md](guides/DEVELOPER_GUIDE.md) | Como desenvolver e contribuir |
| [OPERATIONS.md](guides/OPERATIONS.md) | Operação e manutenção |
| [KIRL_GUIDE.md](guides/KIRL_GUIDE.md) | Auditoria documental |
| [OBSIDIAN_GUIDE.md](guides/OBSIDIAN_GUIDE.md) | Integração com Obsidian |

### Arquitetura
| Documento | Descrição |
|-----------|-----------|
| [SYSTEM_ARCHITECTURE.md](architecture/SYSTEM_ARCHITECTURE.md) | Visão completa da arquitetura |
| [DESKTOP_ARCHITECTURE.md](architecture/DESKTOP_ARCHITECTURE.md) | Arquitetura do frontend desktop |
| [FRONTEND_FSD_ARCHITECTURE.md](architecture/FRONTEND_FSD_ARCHITECTURE.md) | Feature-Sliced Design no frontend |
| [PROVIDER_ROUTING.md](architecture/PROVIDER_ROUTING.md) | Roteamento de providers |

### APIs
| Documento | Descrição |
|-----------|-----------|
| [API_REFERENCE.md](api/API_REFERENCE.md) | Referência completa de endpoints |
| [Swagger UI](http://localhost:8000/docs) | Documentação interativa (local) |

### SDDs (Software Design Documents)
Os SDDs estão em `docs/sdd/` e cobrem:
- [SDD-040](docs/sdd/SDD-040.md) — Universal Orchestration Platform
- [SDD-KIRL](docs/sdd/SDD-KIRL.md) — K.A.O.S Intelligence Runtime Layer
- SDDs de fases (1-10), componentes e integrações

### Outros
| Documento | Descrição |
|-----------|-----------|
| [CHANGELOG.md](CHANGELOG.md) | Histórico de versões |
| [FEATURE_CATALOG.md](docs/features/FEATURE_CATALOG.md) | Catálogo de funcionalidades |
| [TROUBLESHOOTING.md](docs/troubleshooting/TROUBLESHOOTING.md) | Problemas comuns |
| [SECURITY.md](docs/security/API_KEYS.md) | Chaves de API e segurança |

---

## Stack Tecnológica

### Backend
| Componente | Tecnologia | Versão |
|-----------|-----------|--------|
| Linguagem | Python | 3.13 |
| Framework | FastAPI | 0.115+ |
| ORM | SQLAlchemy | 2.0+ |
| Agent Framework | LangGraph | 0.2+ |
| Vector DB | Qdrant | 1.9+ |
| Database | PostgreSQL | 16 |
| LLM Providers | Ollama, OpenAI, Anthropic, Gemini | — |
| Package Manager | UV | — |

### Frontend
| Componente | Tecnologia | Versão |
|-----------|-----------|--------|
| Framework | React | 18 |
| Linguagem | TypeScript | 5.5+ |
| Bundler | Vite | 5 |
| Desktop | Tauri | 2 |
| State | Zustand | 5 |
| Router | React Router | 7 |
| Styling | Tailwind CSS | 3 |
| Animação | Framer Motion | 12 |

### Infraestrutura
| Componente | Tecnologia |
|-----------|-----------|
| Container | Docker + Docker Compose |
| Monitoramento | Prometheus + Grafana |
| Logs | Loki + Promtail |
| Automação | n8n |
| CI/CD | GitHub Actions |

---

## Módulos do Sistema

### KIRL — K.A.O.S Intelligence Runtime Layer
Sistema de auditoria documental que garante consistência entre código e documentação.

- **Feature Registry**: Catálogo central de features
- **Audit Engine**: Drift detection entre código e SDDs
- **DRL Snapshot**: Estado unificado do sistema
- **Graphify**: Grafo de arquitetura interativo
- **Auto-Doc**: Geração automática de SDDs
- **Event Bus Integration**: Eventos de auditoria em tempo real

### Workflow Engine
Orquestração de fluxos baseada em capacidades.

- **Intent Classifier**: Classifica intenção do usuário
- **Model Router**: Seleciona melhor modelo para a capacidade
- **Provider Selector**: Escolhe provedor disponível
- **Circuit Breaker**: Proteção contra falhas em cascata
- **Plan Executor**: Execução do plano com streaming
- **Dead Letter Queue**: Forense de execuções falhas

### RAG Pipeline
Recuperação aumentada de conhecimento.

- **Vault Indexer**: Indexa documentos do Obsidian
- **Embedder**: Gera embeddings locais
- **Semantic Retriever**: Busca semântica no Qdrant
- **Wiki Pipeline**: Consulta Wiki-first

---

## Roadmap

### 2026 Q2
- ✅ KIRL — Documentation Runtime Layer
- ✅ Graphify — Architecture Graph
- 🔄 Documentação centralizada (SDD-DOCS-001)
- ⏳ AI Vault Analyzer

### 2026 Q3
- ⏳ Auto-Documentation contínua
- ⏳ AI Architecture Reviewer
- ⏳ OpenCode Configuration Layer
- ⏳ Self-Healing DRL

---

## Glossário

| Termo | Significado |
|-------|------------|
| **KIRL** | K.A.O.S Intelligence Runtime Layer — camada de auditoria documental |
| **DRL** | Documentation Runtime Layer — camada de runtime da documentação |
| **SDD** | Software Design Document — documento de design do sistema |
| **FSD** | Feature-Sliced Design — metodologia de organização frontend |
| **RAG** | Retrieval-Augmented Generation — geração aumentada por recuperação |
| **MCP** | Model Context Protocol — protocolo de contexto para modelos |
| **DLQ** | Dead Letter Queue — fila de mensagens falhas |
| **Graphify** | Engine de grafo de arquitetura |

---

## Contribuição

1. Crie uma branch a partir de `dev`
2. Implemente a feature
3. Execute `ruff check` e `pytest`
4. Abra um PR para `dev`

### Commits
```
feat: nova funcionalidade
fix: correção de bug
docs: documentação
test: testes
refactor: refatoração
style: formatação
```

---

## Licença

MIT
