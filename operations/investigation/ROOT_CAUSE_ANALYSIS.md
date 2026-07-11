# Root Cause Analysis (SDD-OPS-INVESTIGATION-001-AI)

## Findings

### Finding F-001
* **ID**: F-001
* **Category**: TUNNEL / ROUTING
* **Observation**: Standalone tunnel client `/kaos-backend-tunnel` running on the default `bridge` network hijacks traffic for `api.kaostech.com.br` and other internal subdomains, failing to resolve them via external DNS (`8.8.8.8`), resulting in **502 Bad Gateway**.
* **Evidence**:
  * **Command**: `docker inspect kaos-backend-tunnel` (Network section)
    ```json
    "Networks": {
        "bridge": {
            "IPAddress": "172.17.0.2"
        }
    }
    ```
  * **Command**: `docker logs --tail 2 kaos-backend-tunnel`
    ```
    2026-07-11T01:40:13Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp: lookup kaos-api on 8.8.8.8:53: no such host" connIndex=1 event=1 ingressRule=0 originService=http://kaos-api:8000
    ```
* **Confidence**: **HIGH**
* **Impact**: Public API (`api.kaostech.com.br`) and observability tools (`grafana`, `prometheus`, `loki`) are completely unavailable to external clients.

---

### Finding F-002
* **ID**: F-002
* **Category**: FIREWALL / ROUTING
* **Observation**: Compose tunnel client `kaos-platform-cloudflared-1` running in the custom compose network `kaos-platform_kaos_prod_network` cannot route back to the host physical IP address (`192.168.100.30:3000`), leading to `i/o timeout` errors when trying to serve `chat.kaostech.com.br`.
* **Evidence**:
  * **Command**: `docker logs kaos-platform-cloudflared-1`
    ```
    2026-07-11T01:40:27Z ERR  error="Unable to reach the origin service. The service may be down or it may not be responding to traffic from cloudflared: dial tcp 192.168.100.30:3000: i/o timeout" connIndex=3 event=1 ingressRule=1 originService=http://192.168.100.30:3000
    ```
* **Confidence**: **HIGH**
* **Impact**: Web Chat (`chat.kaostech.com.br`) experiences intermitent outages or timeout failures.

---

### Finding F-003
* **ID**: F-003
* **Category**: CI/CD PIPELINE
* **Observation**: The deployment cleanup script in `.github/workflows/deploy.yml` fails to detect, stop, or remove the standalone `/kaos-backend-tunnel` container because it only filters for containers containing the prefix `kaos-platform-`.
* **Evidence**:
  * **File Reference**: [deploy.yml](file:///c:/workspace/Freelancer/K.A.O.S/.github/workflows/deploy.yml#L19-L21)
    ```yaml
    CONTAINERS=$(docker ps -a --filter "name=kaos-platform-" -q)
    if [ -n "$CONTAINERS" ]; then
      docker rm -f $CONTAINERS || true
    fi
    ```
* **Confidence**: **HIGH**
* **Impact**: Abandoned standalone containers running old/conflicting configs persist across builds, creating permanent split-tunnel traffic collision issues.

---

### Finding F-004
* **ID**: F-004
* **Category**: APPLICATION HEALTH
* **Observation**: The FastAPI backend (`kaos-platform-kaos-api-1`) is running healthy, responding `200 OK` to local queries, and successfully maintaining active database/observability connections.
* **Evidence**:
  * **Command**: `curl -iv http://localhost:1010/health`
    ```json
    HTTP/1.1 200 OK
    server: uvicorn
    {"status":"ok","version":"0.1.0"}
    ```
  * **Command**: `docker logs --tail 2 kaos-platform-kaos-api-1`
    ```
    INFO:     172.29.0.4:45012 - "GET /metrics HTTP/1.1" 200 OK
    ```
* **Confidence**: **HIGH**
* **Impact**: Confirms the failure is strictly an **Infrastructure / Network Routing** issue, not an application crash.

---

## Root Cause Summary
The **502 Bad Gateway** and **Cannot reach backend** errors are caused by a **Split-Tunnel Conflict**. 
An orphan container named `kaos-backend-tunnel` is running on the default `bridge` network and shares the same Cloudflare Tunnel Token as the official `kaos-platform-cloudflared-1` compose tunnel. Because it resides on the `bridge` network, it cannot resolve compose service names (like `kaos-api` or `grafana`), intercepting traffic and returning 502s. The official tunnel also struggles to route host-bound IPs (like `192.168.100.30:3000`), timing out requests.
