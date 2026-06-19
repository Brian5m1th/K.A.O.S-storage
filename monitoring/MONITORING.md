# Monitoramento — K.A.O.S

## Stack (Prometheus + Loki + Grafana)

A stack de observabilidade é definida em `infra/docker/docker-compose.yml` e provisionada **auto** pelo backend FastAPI (não exige intervenção manual no docker-compose).

### Serviços

| Serviço | Porta | Imagem | Função |
|---------|-------|--------|--------|
| **prometheus** | 9090 | `prom/prometheus:latest` | Métricas e alertas |
| **loki** | 3100 | `grafana/loki:latest` | Agregação de logs estruturados |
| **promtail** | — | `grafana/promtail:latest` | Coleta logs do JSON gerado pelo backend |
| **grafana** | 3001 | `grafana/grafana:latest` | Dashboards + alertas |

### Arquivos de Configuração

| Arquivo | Descrição |
|---------|-----------|
| `infra/docker/prometheus.yml` | Scrape configs: kaos-api (8000), qdrant (6333), postgres (9187) |
| `infra/docker/loki.yml` | Filesystem storage, retenção 30 dias |
| `infra/docker/promtail.yml` | Tail de `logs/kaos-api.json` com label `job=kaos-api` |
| `infra/docker/grafana-datasources.yml` | Provisiona datasources Prometheus + Loki |
| `infra/docker/grafana-dashboards/` | Dashboards pré-criados (opcional) |

## Métricas do Backend

O backend FastAPI expõe métricas em `GET /metrics` via `prometheus-fastapi-instrumentator`.

Métricas incluídas:
- `http_request_duration_seconds` (latência)
- `http_request_count` (total por método/rota/status)
- `http_request_size_bytes`
- `http_response_size_bytes`

### Healthcheck

O healthcheck do Docker Compose consulta `GET /health` no backend:

```yaml
healthcheck:
  test: ["CMD", "uv", "run", "httpx", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

Retorno esperado: `{"status": "ok"}` (HTTP 200).

## Logs Estruturados (JSON via loguru)

Em produção (`APP_ENV=production`), o loguru escreve logs em `logs/kaos-api.json` no formato JSONL.

Campos de cada entrada:
```json
{
  "timestamp": "2025-06-19T10:30:00.000Z",
  "level": "INFO",
  "module": "assistant.app.api.chat",
  "function": "chat_handler",
  "line": 42,
  "message": "Request processed",
  "trace_id": "abc123",
  "user_id": "usr_xxx",
  "provider": "openai"
}
```

O Promtail coleta esse arquivo e envia para o Loki. No Loki os logs podem ser consultados com LogQL:

```logql
{job="kaos-api"} | json | level = "ERROR"
```

## Grafana

- URL: `http://localhost:3001`
- Login: `admin` / `admin` (configurável via variável de ambiente)
- Datasources pré-provisionados: Prometheus + Loki

### Consultas Úteis

**Erros por provider:**
```logql
{job="kaos-api"} | json | level = "ERROR" | provider != ""
```

**Latência p95 (painel):**
```
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, method, route))
```

**Request rate por rota:**
```
rate(http_request_count_total[5m])
```

## Backup dos Logs

Logs do Loki são armazenados em filesystem (`/tmp/loki` no container). Para persistência em produção, configure S3/GCS no `loki.yml`.

Dados do Grafana (dashboards, alertas, usuários) são salvos em volume Docker. Para backup:

```bash
docker exec grafana-db tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
```

## Troubleshooting

| Problema | Causa Comum | Solução |
|----------|-------------|---------|
| Grafana não sobe | Porta 3001 ocupada | Altere `GF_SERVER_HTTP_PORT` ou pare o serviço concorrente |
| Prometheus sem targets | Scrape config incorreto | Verifique `prometheus.yml` e `docker-compose logs prometheus` |
| Loki sem logs | Promtail não consegue ler `logs/kaos-api.json` | Verifique se `APP_ENV=production` e permissão de leitura |
| "503 Service Unavailable" | Healthcheck falhou | Verifique `docker-compose ps` e `docker-compose logs kaos-api` |
