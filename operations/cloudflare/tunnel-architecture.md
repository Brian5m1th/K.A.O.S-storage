# K.A.O.S Cloudflare Tunnel Production Architecture

This document defines the official production network and routing architecture for the K.A.O.S ecosystem behind CGNAT.

---

## 1. Network Constraints (CGNAT)
The production host runs behind a **CGNAT (Carrier-Grade NAT)**. It does not possess a public IPv4 address, and all inbound ports (80, 443, 8000, etc.) are physically closed.

To make services accessible to the public internet (such as the K.A.O.S Desktop Tauri Client or external web browsers), the server relies entirely on outbound persistent connections established by a **Cloudflare Tunnel** daemon (`cloudflared`).

---

## 2. Ingress & Routing Topology (Docker DNS)
To ensure maximum isolation, security, and ease of deployment, **no physical IP addresses of the Docker Host (e.g., `192.168.100.30`) should be configured as origins inside the Cloudflare Tunnel.**

The tunnel agent container (`kaos-platform-cloudflared-1`) runs within the custom Docker compose network `kaos-platform_kaos_prod_network`. It resolves and communicates with other containers directly via **Docker DNS names**.

### Target Ingress Configuration
All subdomains of `kaostech.com.br` mapped in the Cloudflare Zero Trust Dashboard must point to internal service names and ports:

| Subdomain | Target Ingress URL (Internal DNS) | Description |
| :--- | :--- | :--- |
| `api.kaostech.com.br` | `http://kaos-api:8000` | FastAPI Assistant Backend |
| `chat.kaostech.com.br` | `http://open-webui:8080` | Open WebUI Client |
| `n8n.kaostech.com.br` | `http://n8n:5678` | n8n Automation Workflows |
| `whatsapp.kaostech.com.br`| `http://evolution-api:8080` | Evolution WhatsApp API |
| `grafana.kaostech.com.br` | `http://grafana:3000` | Grafana Dashboard |
| `prometheus.kaostech.com.br`| `http://prometheus:9090` | Prometheus Metrics |
| `loki.kaostech.com.br` | `http://loki:3100` | Loki Log Engine |
| `alertmanager.kaostech.com.br`| `http://alertmanager:9093` | Alertmanager Alerts |

---

## 3. The Split-Brain Routing Risk (Single Tunnel Policy)
Only a **single** instance of the Cloudflare Tunnel conector (the docker-compose service `kaos-platform-cloudflared-1`) is allowed to connect to Cloudflare edge using the production token.

### Why Concurrency Fails:
If an additional client (such as a standalone `kaos-backend-tunnel` container or a legacy daemon on the host) connects using the same token:
1. Cloudflare treats both connectors as active and load-balances incoming traffic between them.
2. If one client runs on a network namespace (like the default `bridge` network) that cannot resolve service names like `kaos-api` or `grafana`, it will query public DNS (`8.8.8.8`) and fail, returning **502 Bad Gateway** intermittently.

---

## 4. Pipeline Safeguards & Clean Steps
The CI/CD pipeline enforces the removal of any legacy/standalone containers during cleanup:
* **Workflow reference**: [deploy.yml](file:///c:/workspace/Freelancer/K.A.O.S/.github/workflows/deploy.yml#L16-L23)
* **Cleanup command**:
  ```bash
  CONTAINERS=$(docker ps -a --filter "name=kaos-platform-" -q; docker ps -a --filter "name=kaos-backend-tunnel" -q)
  if [ -n "$CONTAINERS" ]; then
    docker rm -f $CONTAINERS || true
  fi
  ```
