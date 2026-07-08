---
id: loki_queries
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Loki Queries — K.A.O.S

## Formato dos Logs

Os logs são gerados pelo loguru em `logs/kaos-api.json` no formato JSONL:

```json
{"timestamp":"2025-06-19T10:30:00.000Z","level":"INFO","module":"assistant.app.api.chat","function":"chat_handler","line":42,"message":"Request processed","trace_id":"abc123","user_id":"usr_xxx","provider":"openai"}
```

## LogQL — Consultas Úteis

### Básicas

```logql
# Últimos 30 minutos de todos os logs
{job="kaos-api"} |= ``

# Logs de erro
{job="kaos-api"} | json | level = "ERROR"

# Logs de warning
{job="kaos-api"} | json | level = "WARNING"
```

### Por Provider

```logql
# Logs de um provider específico
{job="kaos-api"} | json | provider = "openai"

# Logs de erro por provider
{job="kaos-api"} | json | level = "ERROR" | provider != ""
```

### Por Módulo

```logql
# Logs do módulo de chat
{job="kaos-api"} | json | module = "assistant.app.api.chat"

# Logs de autenticação
{job="kaos-api"} | json | module = "assistant.app.middleware.auth"
```

### Análise de Erros

```logql
# Contagem de erros por módulo (última 1h)
sum by (module) (count_over_time({job="kaos-api"} | json | level = "ERROR" [1h]))

# Top 10 mensagens de erro mais frequentes
{job="kaos-api"} | json | level = "ERROR" | topk(10, message) by (message)
```

### Métricas a partir de Logs

```logql
# Requests por minuto (derivado de logs)
sum by (provider) (count_over_time({job="kaos-api"} | json | provider != "" [1m]))

# Latência — extraída se presente no log como campo
{job="kaos-api"} | json | duration != "" | duration > 5
```

### Filtro por Trace ID

```logql
{job="kaos-api"} | json | trace_id = "abc123"
```

## Dicas

- Use `| json` para parsear logs JSONL
- Campos aninhados não são suportados diretamente; use `| json` + `| line_format` se necessário
- Para debug detalhado, use `level = "DEBUG"` (não habilitado em produção por padrão)

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
