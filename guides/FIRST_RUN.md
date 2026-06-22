# Guia de Primeira Execução — K.A.O.S

Este guia mostra como validar que o K.A.O.S está funcionando corretamente após a instalação.

---

## 1. Subir Backend

```bash
cd assistant
uv run uvicorn app.main:app --reload --port 8000
```

**Saída esperada:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     [start] K.A.O.S - modo development
INFO:     [observability] subscribers registered
```

---

## 2. Subir Desktop (outro terminal)

```bash
cd desktop
npm run dev
```

**Saída esperada:**
```
VITE v5.x  ready in XXXms
➜  Local:   http://localhost:1420
```

Acesse `http://localhost:1420` no navegador.

---

## 3. Subir Infraestrutura (outro terminal)

```bash
cd infra/docker
docker compose up -d
```

**Saída esperada:**
```
✅ Container postgres    Started
✅ Container qdrant      Started
✅ Container kaos-api    Started
(etc.)
```

---

## 4. Validar APIs

### 4.1 Health Check

```bash
curl http://localhost:8000/health
```

**Resposta esperada:**
```json
{"status":"ok","version":"0.1.0","embedder_ready":true}
```

### 4.2 API Key

```bash
cat data/api_key.txt
```

Use este valor no header `x-api-key` para requisições autenticadas.

### 4.3 Chat (requer API Key)

```bash
API_KEY=$(cat data/api_key.txt)

curl -X POST http://localhost:8000/api/chat/message \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"message":"Ola, quem e voce?","model":"llama3.2:3b"}'
```

**Resposta esperada:** Streaming de tokens ou resposta JSON.

### 4.4 Models

```bash
curl -X GET http://localhost:8000/v1/models \
  -H "x-api-key: $API_KEY"
```

**Resposta esperada:** Lista de modelos disponíveis.

---

## 5. Validar Ollama

```bash
# Listar modelos instalados
ollama list

# Testar inferência
ollama run llama3.2:3b "Ola, mundo!"
```

**Ollama deve estar rodando em** `http://localhost:11434`.

---

## 6. Validar Qdrant

```bash
curl http://localhost:6333/health
```

**Resposta esperada:**
```json
{"ok":true}
```

---

## 7. Validar PostgreSQL

```bash
docker exec infra-postgres-1 pg_isready
```

**Resposta esperada:**
```
/var/run/postgresql:5432 - accepting connections
```

---

## 8. Validar Observabilidade

### 8.1 Métricas Prometheus

```bash
curl http://localhost:8000/metrics
```

**Resposta esperada:** Texto com métricas no formato Prometheus.

### 8.2 Grafana

Acesse `http://localhost:3000` (login: admin / admin).

### 8.3 Logs

```bash
# Logs do backend
tail -f logs/kaos-api.json

# Logs do Docker
docker compose logs -f kaos-api
```

---

## 9. Validar Desktop

### 9.1 Sidebar

Ao abrir `http://localhost:1420`, a sidebar deve mostrar:

```
KAOS
├── Dashboard
├── Chat
├── Orquestração
├── Agents
├── Pipelines
├── Knowledge
├── Observability
├── Doc Health
├── Settings
└── [status] online
```

### 9.2 Documentation Health

Navegue para `/documentation`:

- ✅ Cards de métricas (Coverage, Missing Docs, Outdated SDDs)
- ✅ Botão "Run Audit" funcional
- ✅ Tabs (Overview, Missing, Outdated, Timeline)
- ✅ Quick Actions com APIs reais

### 9.3 Architecture Graph

Navegue para `/architecture`:

- ✅ Grafo interativo com nodes e edges
- ✅ Zoom/Pan com mouse
- ✅ Filtro por tipo de node
- ✅ 3 layouts (Force, Hierarchical, Radial)
- ✅ Export JSON / GraphML / SVG

### 9.4 CTRL+K (Command Palette)

Pressione `Ctrl+K` ou `Cmd+K`:

- ✅ "Go to Dashboard"
- ✅ "Open Chat"
- ✅ "Run Documentation Audit"
- ✅ "Show Undocumented Features"
- ✅ "Open Documentation Health"

---

## 10. Validar KIRL (Documentation Runtime Layer)

### 10.1 Executar Auditoria

Via API:

```bash
curl -X POST http://localhost:8000/api/audit/run \
  -H "x-api-key: $API_KEY"
```

**Resposta esperada:**
```json
{
  "coverage": 0,
  "driftLevel": "high",
  "missingFeatures": [],
  "outdatedDocs": [],
  "inconsistentPhases": []
}
```

### 10.2 Verificar Snapshot

```bash
curl http://localhost:8000/api/audit/snapshot \
  -H "x-api-key: $API_KEY"
```

### 10.3 Verificar Feature Registry

```bash
curl http://localhost:8000/api/audit/features \
  -H "x-api-key: $API_KEY"
```

### 10.4 Escanear Commits

```bash
curl -X POST http://localhost:8000/api/audit/scan-commits \
  -H "x-api-key: $API_KEY"
```

---

## 11. Validar Auto-Doc

O sistema inicia automaticamente o ciclo de auto-documentação (60s).

Para forçar uma execução:

```typescript
// No console do navegador, se o desktop estiver aberto
// (apenas para debugging)
```

Para verificar SDDs gerados:

```bash
ls docs/runtime/auto-generated/
```

---

## Checklist Final

| Item | Status | Comando |
|------|--------|---------|
| Backend rodando | ⬜ | `curl localhost:8000/health` |
| Desktop rodando | ⬜ | `http://localhost:1420` |
| Docker services up | ⬜ | `docker compose ps` |
| Ollama funcional | ⬜ | `ollama list` |
| Qdrant funcional | ⬜ | `curl localhost:6333/health` |
| PostgreSQL funcional | ⬜ | `docker exec infra-postgres-1 pg_isready` |
| API Key gerada | ⬜ | `cat data/api_key.txt` |
| Chat funcional | ⬜ | `curl -X POST localhost:8000/api/chat/message` |
| Metrics endpoint | ⬜ | `curl localhost:8000/metrics` |
| Auditoria KIRL | ⬜ | `curl -X POST localhost:8000/api/audit/run` |
| Sidebar completa | ⬜ | Verificar 9 itens + status |
| CTRL+K funcional | ⬜ | Pressionar Ctrl+K |
| Build sem erros | ⬜ | `npx tsc --noEmit` |
| Testes passando | ⬜ | `uv run pytest` |

---

## Próximos Passos

Após validar a instalação:

1. [Guia do Usuário](USER_GUIDE.md) — aprender a usar o sistema
2. [Guia do Desenvolvedor](DEVELOPER_GUIDE.md) — criar features
3. [Guia de Operações](OPERATIONS.md) — manutenção e deploy
4. [Guia KIRL](KIRL_GUIDE.md) — auditoria documental
5. [Guia Obsidian](OBSIDIAN_GUIDE.md) — integração com Obsidian
