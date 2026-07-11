# Cloudflare Tunnel Analysis

We analyzed the Cloudflare Tunnel configuration, tokens, and logs of both active tunnel containers on the production host.

---

## Log Extracts & Diagnostics

### 1. Standalone Container (`kaos-backend-tunnel`)
* **Docker Network**: `bridge`
* **Log Findings**:
  ```
  2026-07-11T01:40:13Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp: lookup kaos-api on 8.8.8.8:53: no such host" connIndex=1 event=1 ingressRule=0 originService=http://kaos-api:8000
  2026-07-11T01:40:18Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp: lookup grafana on 8.8.8.8:53: no such host" connIndex=1 event=1 ingressRule=4 originService=http://grafana:3000
  ```
* **Analysis**: This container is successfully connected to Cloudflare and receives traffic for `api.kaostech.com.br` and `grafana.kaostech.com.br`. However, because it runs on the default `bridge` network, it queries external DNS (`8.8.8.8`) to resolve the hostnames `kaos-api` and `grafana`. Since these are internal compose service names, DNS resolution fails, returning **502 Bad Gateway** to clients.

### 2. Compose Container (`kaos-platform-cloudflared-1`)
* **Docker Network**: `kaos-platform_kaos_prod_network` (custom)
* **Log Findings**:
  ```
  2026-07-11T01:40:27Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp 192.168.100.30:3000: i/o timeout" connIndex=3 event=1 ingressRule=1 originService=http://192.168.100.30:3000
  ```
* **Analysis**: This container is connected to the custom compose network. It successfully resolves name-based service routes internally. However, when it tries to reach services configured with the host IP address (`http://192.168.100.30:3000` for `chat.kaostech.com.br`), the request fails with a connection `i/o timeout`. This is caused by firewall/routing rules on the Docker host that block container-to-host routing on the physical LAN IP.

---

## Failure Classification

* **Failure Class**: **ORIGIN FAILURE**
  * The Cloudflare Edge network is functioning correctly.
  * The failure originates entirely on the host infrastructure due to two conflicting tunnel clients sharing the same token but operating on different network namespaces (one lacks Docker DNS; the other lacks Host loopback routing).
