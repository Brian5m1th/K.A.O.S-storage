# Changelog — K.A.O.S

## v0.1.1 (2026-06-19)

### Features
- **Observability:** Prometheus + Loki + Grafana stack (`infra/docker/`) com métricas em `/metrics` — PR #49
- **Auth:** API Key authentication via header `X-API-Key` com endpoints `/auth/key` e `/auth/regenerate` — PR #48
- **Desktop CI:** Vite cache, negation patterns, build metrics — PR #46
- **Cosign:** Keyless signing para imagens Docker (`ghcr.io`) — PR #45
- **Multi-Provider UI:** Interface desktop para configurar OpenAI, Anthropic, Google e Ollama com `tauri-plugin-store` — PR #44
- **ProviderConfigService:** Backend endpoints `/api/setup/provider` para gerenciar providers — PR #43
- **Vault Submodule:** Integração do K.A.O.S-storage como submodule em `docs/vault/` — PR #42

### Fixes
- **Cosign lowercase:** Uso de `${GITHUB_REPOSITORY,,}` para evitar erro `parsing reference` — PR #47
- **Docker Compose:** Bind mount que escondia `.venv` do build multi-stage resolvido
- **Provider connection test:** Testes de conexão adaptados para cada provider (Ollama `/api/tags`, OpenAI `/models`, etc)

### Documentation
- `API_KEYS.md` — Autenticação via API Key
- `COSIGN.md` — Cosign keyless signing
- `MONITORING.md` — Stack Prometheus/Loki/Grafana
- `PROVIDERS.md` — Configuração de LLM providers
- `SETUP.md` — Guia de instalação completo
- `DESKTOP_ARCHITECTURE.md` — Arquitetura do desktop Tauri+React
- `PROVIDER_ROUTING.md` — Roteamento de providers no backend
- `VAULT_SUBMODULE.md` — Gerenciamento do submodule
- `GITHUB_ACTIONS.md` — Workflows CI/CD
- `DOCUMENTATION_GOVERNANCE_SDD.md` — Regras de documentação
- `GRAFANA_DASHBOARDS.md` — Dashboards e alertas
- `LOKI_QUERIES.md` — Consultas LogQL
- `TROUBLESHOOTING.md` — Problemas comuns e soluções
- Backlog do Projeto atualizado (Fase 10 marcada como completa)
