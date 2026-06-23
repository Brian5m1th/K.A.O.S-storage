---
id: grafana_dashboards
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Grafana Dashboards — K.A.O.S

## Acesso

- **URL:** `http://localhost:3001`
- **Login:** `admin`
- **Senha:** `admin` (configurável via `GF_SECURITY_ADMIN_PASSWORD`)

## Datasources Provisionados

| Datasource | Tipo | URL |
|-----------|------|-----|
| Prometheus | Prometheus | `http://prometheus:9090` |
| Loki | Loki | `http://loki:3100` |

Provisionados automaticamente via `infra/docker/grafana-datasources.yml`.

## Painéis Recomendados

### 1. Visão Geral da API

Métricas do Prometheus:

| Painel | Query |
|--------|-------|
| Request Rate | `rate(http_request_count_total[5m])` |
| Latência P95 | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, method, route))` |
| Erros por segundo | `rate(http_request_count_total{status=~"5.."}[5m])` |
| Requests por provedor | `count by (provider) (http_request_count_total)` |

### 2. Logs de Erro (Loki)

```
{job="kaos-api"} | json | level = "ERROR"
```

### 3. Logs por Provider (Loki)

```
{job="kaos-api"} | json | provider != "" | level != "DEBUG"
```

## Importação de Dashboards

Dashboards JSON podem ser salvos em `infra/docker/grafana-dashboards/` para provisionamento automático.

Formato esperado: JSON exportado do Grafana (Dashboard → Share → Export).

## Alertas

Alertas podem ser configurados via UI do Grafana (Alerting → Contact points → Notification policies).

Sugestões de alerta:
- **API Down:** `up{job="kaos-api"} == 0` por > 30s
- **Alta latência:** `http_request_duration_seconds{quantile="0.95"} > 5` por > 5min
- **Erros altos:** `rate(http_request_count_total{status=~"5.."}[5m]) > 0.1` por > 5min

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
