# SDD-INFRA-001 — Docker Compose Produção (K.A.O.S)

## 1. Visão Geral

Este documento define os padrões oficiais de infraestrutura do arquivo `docker-compose.prod.yml`, incluindo limites de CPU/Memória, isolamento de rede, políticas de reinicialização, healthchecks nativos dos componentes, e rotação física dos arquivos de logs gerados no Docker Host.

---

## 2. Rotação de Logs e Limites

Para evitar o estouro de disco provocado por logs acumulados na saída padrão (stdout) dos contêineres Docker, todos os serviços herdam um template de logging rígido:

```yaml
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "5"
```
* **max-size (10m):** Cada arquivo de log individual é limitado a 10 megabytes.
* **max-file (5):** Mantém no máximo 5 arquivos rotacionados por container (limite físico de 50MB por contêiner).

---

## 3. Mapeamentos de Volumes Críticos e Logs da API

```
Host (Servidor)                   Container (FastAPI)
  ./logs/         <─────────────>    /app/logs/
    └── kaos-api.json                  └── kaos-api.json
```

* **Caminho Interno:** O backend FastAPI (`kaos-api`) gera logs JSON em `/app/logs/kaos-api.json`.
* **Configuração de Volume:** Mapeado para o diretório local do host `./logs:/app/logs`.
* **Promtail Integration:** O Promtail lê os logs a partir do volume compartilhado no host (mapeado para `/var/log/kaos-api/kaos-api.json`), garantindo que o arquivo correto seja lido e enviado ao Loki.

---

## 4. Estrutura de Healthchecks

Os healthchecks garantem que os serviços dependentes sejam iniciados apenas após a saúde do serviço base estar validada.

### 4.1. PostgreSQL Healthcheck
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ai-p -d kaos"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### 4.2. FastAPI kaos-api Healthcheck
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 40s
```

### 4.3. n8n Healthcheck
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
```

---

## 5. Publicações de Rotas (Cloudflare Tunnel)

Os subdomínios do túnel configurados no painel do Cloudflare Zero Trust são redirecionados de acordo com a topologia abaixo:

| Subdomínio | Destino Configurado no Tunnel | Contexto |
| :--- | :---: | :--- |
| `api.kaostech.com.br` | `http://kaos-api:8000` | Interno da Rede Docker |
| `chat.kaostech.com.br` | `http://192.168.100.30:3000` | Open WebUI no Host |
| `n8n.kaostech.com.br` | `http://192.168.100.30:5678` | n8n no Host |
| `whatsapp.kaostech.com.br`| `http://192.168.100.30:8080` | Evolution API no Host |
| `grafana.kaostech.com.br` | `http://grafana:3000` | Grafana Interno |
| `prometheus.kaostech.com.br`| `http://prometheus:9090` | Prometheus Interno |
| `loki.kaostech.com.br` | `http://loki:3100` | Loki Interno |
| `alertmanager.kaostech.com.br`| `http://alertmanager:9093` | Alertmanager Interno |
