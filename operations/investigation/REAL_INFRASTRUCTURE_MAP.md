# Real Infrastructure Map

## Active Compose Projects
We detected the following active Docker Compose projects:
* **kaos-platform**
  * Config file: `/home/dev/actions-runner/kaos/_work/K.A.O.S/K.A.O.S/infra/docker/docker-compose.prod.yml`
  * Status: `restarting(1), running(15)`
* **deploy-guide**
  * Config file: `/home/configurator/docker/deploy-guide/docker-compose.yml`
  * Status: `running(1)`
* **vmind-client**
  * Config file: `/home/dev/docker/vmind-client/docker-compose.yml`
  * Status: `running(1)`

---

## Active Containers (K.A.O.S Related)

| Container Name | Image | Status | Ports | Docker Networks | Compose Project |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `kaos-platform-kaos-api-1` | `kaos-platform-kaos-api:sha-452fc57` | Up 58m (healthy) | `0.0.0.0:1010->8000/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-platform-cloudflared-1` | `cloudflare/cloudflared:latest` | Up 56m | None | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-backend-tunnel` | `cloudflare/cloudflared:latest` (sha: `6e88b56b4ce9`) | Up 9h | None | `bridge` | None (Standalone) |
| `kaos-platform-open-webui-1` | `ghcr.io/open-webui/open-webui:latest` | Up 56m (healthy) | `0.0.0.0:3000->8080/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-platform-n8n-1` | `n8nio/n8n:latest` | Up 58m (healthy) | `0.0.0.0:5678->5678/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-platform-postgres-1` | `postgres:16-alpine` | Up 1h (healthy) | `0.0.0.0:5433->5432/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-platform-qdrant-1` | `qdrant/qdrant:latest` | Up 1h | `0.0.0.0:6333-6334->6333-6334/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `kaos-platform-ollama-1` | `ollama/ollama:latest` | Up 1h | `0.0.0.0:11434->11434/tcp` | `kaos-platform_kaos_prod_network` | `kaos-platform` |
| `evolution_api_prod` | `evoapicloud/evolution-api:v2.1.1` | Restarting (1) | None | `kaos-platform_kaos_prod_network` | `kaos-platform` |

---

## Detailed Discovery Metrics

* **active_compose**: `kaos-platform`
* **production_container**: `kaos-platform-kaos-api-1`
* **docker_image**: `kaos-platform-kaos-api:sha-452fc57`
* **source_directory**: `/home/dev/actions-runner/kaos/_work/K.A.O.S/K.A.O.S`
* **commit**: `452fc57`
