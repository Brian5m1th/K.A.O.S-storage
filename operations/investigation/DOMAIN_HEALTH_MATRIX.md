# Domain Health Matrix

This document lists the status and routing details of all subdomains associated with the K.A.O.S production environment.

| Subdomain | Configured Origin | DNS Status | HTTP Status | SSL/TLS | Cloudflare Proxy | Routing Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `api.kaostech.com.br` | `http://kaos-api:8000` | Resolved (Cloudflare) | **502 Bad Gateway** | Enabled | Proxied | **FAIL** |
| `chat.kaostech.com.br` | `http://192.168.100.30:3000` | Resolved (Cloudflare) | **200 OK** | Enabled | Proxied | **PASS** |
| `n8n.kaostech.com.br` | `http://192.168.100.30:5678` | Resolved (Cloudflare) | **200 OK** | Enabled | Proxied | **PASS** |
| `grafana.kaostech.com.br` | `http://grafana:3000` | Resolved (Cloudflare) | **502 Bad Gateway** | Enabled | Proxied | **FAIL** |
| `prometheus.kaostech.com.br`| `http://prometheus:9090` | Resolved (Cloudflare) | **502 Bad Gateway** | Enabled | Proxied | **FAIL** |
| `loki.kaostech.com.br` | `http://loki:3100` | Resolved (Cloudflare) | **502 Bad Gateway** | Enabled | Proxied | **FAIL** |

## Initial Observation
There is a clear divide:
1. Routing directly to the **host IP and physical ports** (`http://192.168.100.30:<port>`) works perfectly (**200 OK**).
2. Routing to **internal Docker DNS names** (`http://<service-name>:<port>`) fails with **502 Bad Gateway**.

This strongly suggests that the active Cloudflare Tunnel agent processing these subdomains does not have access to the internal Docker network (`kaos-platform_kaos_prod_network`), leading to routing failure for name-based origins.
