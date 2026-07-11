# Request Flow Trace

This document traces the request path from the client to the backend database, checking each layer's status.

```
USER
 ↓ (PASS)
Cloudflare (Edge SSL)
 ↓ (PASS)
Tunnel (Active Clients: kaos-backend-tunnel & kaos-platform-cloudflared-1)
  ├─► kaos-backend-tunnel (Bridge Network) ──► (FAIL: Cannot resolve docker names like 'kaos-api')
  └─► kaos-platform-cloudflared-1 (Custom Network) ──► (FAIL: i/o timeout reaching host IP 192.168.100.30)
 ↓
Docker Network (DNS Resolution)
 ↓ (PASS: Verified internally kaos-api -> grafana)
FastAPI Backend (kaos-api)
 ↓ (PASS: Verified 200 OK via localhost:1010/health)
Database (PostgreSQL 16)
   (PASS: Database connection status OK)
```

---

## Status of Each Layer

* **cloudflare**: **PASS**
  * DNS resolves correctly to Cloudflare edge IPs.
  * SSL/TLS handshake completes successfully.
  * Serves the HTTP 502 Bad Gateway response page directly from the Edge, meaning the tunnel client rejected/failed the request.

* **tunnel**: **FAIL**
  * Two tunnel clients are running simultaneously with the same `TUNNEL_TOKEN`.
  * **Client A (kaos-backend-tunnel)**: Running on the default `bridge` network. It receives requests for `api.kaostech.com.br` but fails to resolve the docker service name `kaos-api` via DNS, logging: `lookup kaos-api on 8.8.8.8:53: no such host`. This returns **502 Bad Gateway**.
  * **Client B (kaos-platform-cloudflared-1)**: Running on the custom network `kaos-platform_kaos_prod_network`. It cannot reach host-bound services like `chat.kaostech.com.br` pointing to `192.168.100.30:3000` because of container-to-host routing blocks, logging: `dial tcp 192.168.100.30:3000: i/o timeout`.

* **docker_network**: **PASS**
  * Internal container-to-container DNS resolution works. A test curl request from `kaos-platform-kaos-api-1` to `http://grafana:3000` resolved `172.29.0.8` successfully and returned `302 Found`.

* **backend**: **PASS**
  * FastAPI is fully healthy and active.
  * Responding locally at `http://localhost:1010/health` with `{"status":"ok","version":"0.1.0"}`.
  * Responding inside the Docker network at `http://kaos-api:8000/health`.

* **database**: **PASS**
  * PostgreSQL container is up and running.
  * Health status returned by `/health` is `"ok"`, confirming connection to postgres.
