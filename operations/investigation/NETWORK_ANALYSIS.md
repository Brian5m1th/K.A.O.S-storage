# Network Analysis

## Docker Network Configuration
We analyzed the Docker networks on the host and identified the main custom network in use by the K.A.O.S application stack:
* **Network Name**: `kaos-platform_kaos_prod_network`
* **Subnet**: `172.29.0.0/16`
* **Gateway**: `172.29.0.1`

---

## Connected Services in `kaos-platform_kaos_prod_network`

| Container Name | Internal IP Address | DNS Name (Alias) | Network Reachable? |
| :--- | :--- | :--- | :--- |
| `kaos-platform-kaos-api-1` | `172.29.0.13` | `kaos-api` | **PASS** |
| `kaos-platform-cloudflared-1` | `172.29.0.14` | `cloudflared` | **PASS** |
| `kaos-platform-grafana-1` | `172.29.0.8` | `grafana` | **PASS** |
| `kaos-platform-loki-1` | `172.29.0.6` | `loki` | **PASS** |
| `kaos-platform-prometheus-1` | `172.29.0.4` | `prometheus` | **PASS** |
| `kaos-platform-n8n-1` | `172.29.0.12` | `n8n` | **PASS** |
| `kaos-platform-open-webui-1` | `172.29.0.15` | `open-webui` | **PASS** |
| `kaos-platform-postgres-1` | `172.29.0.7` | `postgres` | **PASS** |

---

## Isolated Container (Default `bridge` network)

| Container Name | IP Address | Docker Network | DNS Resolution for `kaos-api` |
| :--- | :--- | :--- | :--- |
| `kaos-backend-tunnel` | `172.17.0.2` | `bridge` | **FAIL** (Cannot resolve internal DNS names) |

---

## Network Connection Audit Results
* **Official Tunnel (`kaos-platform-cloudflared-1`)**: Connected to the same network as the backend. It can resolve `kaos-api` successfully.
* **Orphan Tunnel (`kaos-backend-tunnel`)**: Running on the default `bridge` network. It has no connection to `kaos-platform_kaos_prod_network` and fails to resolve `kaos-api`.
* **Inter-container Connectivity**: Verified. Internal DNS resolution and routing between compose containers are functional.

**NETWORK HEALTH: FAIL** (Due to the active orphan tunnel container running in the isolated `bridge` network while sharing the same Cloudflare token).
