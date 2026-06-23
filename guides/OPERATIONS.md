---
id: operations
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Guia de Operações — K.A.O.S

## Backup

### PostgreSQL

```bash
# Backup
docker exec infra-postgres-1 pg_dump -U ai-p kaos > backup_kaos_$(date +%Y%m%d).sql

# Restore
cat backup_kaos_20260622.sql | docker exec -i infra-postgres-1 psql -U ai-p kaos
```

### Qdrant

```bash
# Backup do diretório de dados (recomendado: parar Qdrant primeiro)
docker compose stop qdrant
tar -czf backup_qdrant_$(date +%Y%m%d).tar.gz infra/docker/data/qdrant/
docker compose start qdrant
```

### Volumes Docker

```bash
# Listar volumes
docker volume ls | grep kaos

# Backup de volume
docker run --rm -v infra_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

### Arquivos de Configuração

```bash
# .env files
cp assistant/.env backup/.env.$(date +%Y%m%d)
cp infra/docker/.env.docker backup/.env.docker.$(date +%Y%m%d)
```

---

## Restore

### PostgreSQL

```bash
# 1. Parar o serviço
docker compose stop kaos-api

# 2. Dropar e recriar database
docker exec infra-postgres-1 psql -U ai-p -c "DROP DATABASE IF EXISTS kaos;"
docker exec infra-postgres-1 psql -U ai-p -c "CREATE DATABASE kaos;"

# 3. Restaurar
cat backup_kaos_20260622.sql | docker exec -i infra-postgres-1 psql -U ai-p kaos

# 4. Reiniciar
docker compose start kaos-api
```

---

## Logs

### Backend (Loguru)

```bash
# Logs em tempo real
tail -f logs/kaos-api.json

# Filtrar por nível
grep '"level": "ERROR"' logs/kaos-api.json

# Filtrar por módulo
grep '"logger": "app.audit"' logs/kaos-api.json

# Últimas 100 linhas
tail -100 logs/kaos-api.json
```

### Docker

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f kaos-api
docker compose logs -f postgres
docker compose logs -f qdrant

# Últimas N linhas
docker compose logs --tail=100 kaos-api
```

### Loki

Acesse `http://localhost:3000` (Grafana) → Explore → Datasource: Loki.

Query exemplo:
```logql
{container_name="infra-kaos-api-1"} |= "ERROR"
```

---

## Monitoramento

### Prometheus

```bash
# Métricas do backend
curl http://localhost:8000/metrics

# Prometheus targets
curl http://localhost:9090/api/v1/targets

# Consulta de exemplo
curl "http://localhost:9090/api/v1/query?query=http_requests_total"
```

### Grafana

Acesse `http://localhost:3000` (login: admin / admin).

Dashboards:
- **K.A.O.S Overview**: Requisições, latência, erros
- **LLM Performance**: Tokens por provedor, custos
- **Audit Coverage**: Cobertura documental ao longo do tempo
- **Docker Monitoring**: Containers, CPU, memória

### Health Checks

```bash
# Backend
curl http://localhost:8000/health

# Qdrant
curl http://localhost:6333/health

# PostgreSQL
docker exec infra-postgres-1 pg_isready

# Ollama
curl http://localhost:11434/api/tags

# Prometheus
curl http://localhost:9090/-/ready

# Loki
curl http://localhost:3100/ready
```

---

## Troubleshooting

### Backend não inicia

```bash
# Verificar logs
tail -50 logs/kaos-api.json

# Verificar porta
netstat -ano | findstr :8000

# Verificar dependências
curl http://localhost:11434/api/tags  # Ollama
curl http://localhost:6333/health     # Qdrant
docker exec infra-postgres-1 pg_isready  # PostgreSQL
```

### Desktop não conecta

```bash
# Verificar se o backend está rodando
curl http://localhost:8000/health

# Verificar API Key
cat data/api_key.txt

# Verificar CORS (deve estar liberado em dev)
# Verificar console do navegador (F12)
```

### Qdrant com erro

```bash
# Verificar logs
docker compose logs qdrant

# Verificar espaço em disco
df -h

# Forçar reconstrução
docker compose stop qdrant
docker compose rm qdrant
docker compose up -d qdrant
```

### PostgreSQL com erro

```bash
# Verificar logs
docker compose logs postgres

# Resetar senha
docker exec -it infra-postgres-1 psql -U ai-p -c "ALTER USER ai-p PASSWORD 'nova-senha';"

# Verificar conexão
docker exec infra-postgres-1 pg_isready
```

### Ollama não responde

```bash
# Verificar se está rodando
ollama list

# Iniciar servidor
ollama serve

# Verificar logs (Linux)
journalctl -u ollama -f
```

### KIRL / Auditoria não funciona

```bash
# Verificar se o scheduler está rodando
# (no logs do backend deve aparecer "periodic audit scheduler started")

# Executar manualmente
curl -X POST http://localhost:8000/api/audit/run -H "x-api-key: $API_KEY"

# Verificar snapshot
curl http://localhost:8000/api/audit/snapshot -H "x-api-key: $API_KEY"
```

---

## Atualizações

### Backend

```bash
cd assistant
git pull origin dev
uv sync
# Reiniciar o servidor
```

### Desktop

```bash
cd desktop
git pull origin dev
npm install
npm run build  # ou npm run dev para desenvolvimento
```

### Docker

```bash
cd infra/docker
git pull origin dev
docker compose pull
docker compose up -d --force-recreate
```

### Migrations

```bash
# Verificar status
uv run alembic current

# Executar migrations pendentes
uv run alembic upgrade head

# Rollback (1 migration)
uv run alembic downgrade -1
```

---

## CI/CD

### GitHub Actions

Workflows disponíveis:

| Workflow | Trigger | Descrição |
|----------|---------|-----------|
| `ci.yml` | Push/PR para dev | Ruff + pytest + tsc |
| `release.yml` | Tag v* | Build desktop + publish |

### Executar CI Localmente

```bash
# Ruff (lint Python)
uv run ruff check .

# Pytest (testes)
uv run pytest -v

# TypeScript typecheck
cd desktop && npx tsc --noEmit

# TypeScript lint
cd desktop && npm run lint
```

---

## Deploy

### Produção (Docker)

```bash
# 1. Clonar na máquina de produção
git clone https://github.com/Brian5m1th/K.A.O.S.git
cd K.A.O.S

# 2. Configurar ambiente
cp infra/docker/.env.docker .env
# Editar .env com configurações de produção

# 3. Subir serviços
cd infra/docker
docker compose up -d

# 4. Verificar
curl http://localhost:8000/health
curl http://localhost:8000/api/audit/coverage
```

### Requisitos de Produção

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 16 GB | 32 GB |
| Disco | 50 GB | 100 GB SSD |
| Docker | 24+ | 24+ |
| Ollama | Sim | Sim (GPU recomendada) |

### Segurança em Produção

```bash
# 1. Alterar senhas padrão no .env
POSTGRES_PASSWORD=senha-forte-aqui
N8N_ENCRYPTION_KEY=chave-forte-aqui

# 2. Restringir CORS
# Em assistant/app/main.py, alterar:
# allow_origins=["https://meudominio.com"]

# 3. Usar HTTPS (reverse proxy)
# Recomendado: nginx + certbot ou Caddy
```

---

## Métricas de Saúde do Sistema

### Indicadores Chave

| Métrica | Alerta | Ação |
|---------|--------|------|
| Coverage < 90% | ⚠️ | Revisar documentação |
| Drift Level = HIGH | 🚨 | Executar auditoria, corrigir SDDs |
| Backend down | 🚨 | Verificar logs, reiniciar |
| Qdrant down | 🚨 | Verificar volume Docker |
| Ollama down | ⚠️ | Verificar servidor |
| Disco > 80% | ⚠️ | Limpar logs/images antigos |
| Memória > 80% | ⚠️ | Verificar memory leak |

### Comandos de Diagnóstico Rápido

```bash
# 1. Verificar serviços
docker compose ps

# 2. Verificar health
curl -s http://localhost:8000/health | jq .

# 3. Verificar cobertura doc
curl -s http://localhost:8000/api/audit/coverage -H "x-api-key: $API_KEY" | jq .

# 4. Verificar espaço
df -h

# 5. Verificar memória
docker stats --no-stream
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
