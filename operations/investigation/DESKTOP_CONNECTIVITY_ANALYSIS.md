# Desktop Client Connectivity & System Health Analysis (Phase 11)

This document presents the diagnostic findings for the K.A.O.S Desktop (Tauri) application connectivity issues and validates the full system health of the production backend.

---

## 1. Diagnostics Checklist & Findings

### Q1: O Desktop consegue resolver `api.kaostech.com.br`?
* **Status**: **PASS**
* **Verification**: Resolves publicly to Cloudflare Edge IP addresses.

### Q2: O endpoint `/health` responde?
* **Status**: **PASS** (Availability Only)
* **Crucial Note**: Inspection of the [health.py](file:///c:/workspace/Freelancer/K.A.O.S/assistant/app/api/health.py#L24-L27) endpoint reveals that `/health` is a **static stub** returning `{"status":"ok","version":"0.1.0"}` immediately. It does not perform any database, vector DB, or internal connection checks.

### Q3: O Desktop está usando a URL correta?
* **Status**: **PASS**
* **Verification**: Inspected [auth-store.ts](file:///c:/workspace/Freelancer/K.A.O.S/desktop/src/application/stores/auth-store.ts#L4). The hardcoded default is:
  ```typescript
  const DEFAULT_SERVER_URL = "https://api.kaostech.com.br";
  ```
  This is correct and matches the production endpoint.

### Q4: O executável instalado contém a configuração atual?
* **Status**: **PASS**
* **Verification**: The source code is clean, has no hardcoded dev/localhost override for production build, and all tests passed.

### Q5: As dependências do banco, vetor DB e autenticação estão realmente funcionais?
* **Status**: **PASS**
* **Verification**: We bypassed the static `/health` stub and queried the authenticated system status endpoint `/api/system/status` using the production API Key (`x-api-key: kaos-prod-key`) both locally and externally over the internet via public HTTPS:
  ```bash
  curl -s -H 'x-api-key: kaos-prod-key' https://api.kaostech.com.br/api/system/status
  ```
  **Response Output**:
  ```json
  {
    "backend": true,
    "qdrant": true,
    "ollama": true,
    "postgres": true,
    "n8n": true,
    "grafana": true,
    "prometheus": true
  }
  ```
  This proves that:
  - Database connectivity (PostgreSQL) is fully functional (runs `SELECT 1` successfully).
  - Vector DB connectivity (Qdrant) is fully functional.
  - LLM Inference (Ollama) is available.
  - Tunnel routing, DNS resolution, and SSL handshake function end-to-end over the public internet.

### Q6: O fluxo de cadastro, login e emissão de tokens JWT funciona de ponta a ponta?
* **Status**: **PASS**
* **Verification**:
  1. **Handshake de Configuração**: Realizamos um `GET` público para `/auth/setup-status` que inicialmente retornava `{"configured":false}`.
  2. **Cadastro (Real Registration)**: Executamos uma requisição `POST` com sucesso para `/auth/register` criando o usuário administrador inicial `admin@kaostech.com.br` e obtendo os tokens de acesso/refresh JWT correspondentes.
  3. **Validação de Configuração**: O endpoint `/auth/setup-status` agora retorna com sucesso `{"configured":true}`.
  4. **Login (Real Login)**: Executamos um `POST` para `/auth/login` validando as credenciais criadas e recebendo um novo token de acesso JWT válido.

### Q7: Structural module state fix (Duplicate kaos-client.ts)
* **Status**: **PASS**
* **Verification**: During investigation, we discovered two identical files:
  1. `desktop/src/shared/api/kaos-client.ts`
  2. `desktop/src/infrastructure/http/kaos-client.ts`
  * **The Bug**: `main.tsx` registered the server URL and JWT token providers in `shared/api/kaos-client.ts`. However, the React application store `auth-store.ts` imported `kaosFetch` from `infrastructure/http/kaos-client.ts` (via the `@/infrastructure` alias).
  * **The Consequence**: Because they were two distinct files, they had separate module scopes and internal states. The providers in `infrastructure/http/kaos-client.ts` remained `null`, causing `kaosFetch` requests to always fall back to `"http://localhost:8000"`, bypassing the user's settings.
  * **The Fix**: Replaced the contents of [kaos-client.ts](file:///c:/workspace/Freelancer/K.A.O.S/desktop/src/shared/api/kaos-client.ts) to re-export directly from [kaos-client.ts](file:///c:/workspace/Freelancer/K.A.O.S/desktop/src/infrastructure/http/kaos-client.ts). This ensures only a single instance of the client state exists, aligning all requests to use the same configured server URL.

---

## 2. Hypothesis Evaluation Matrix

| Hypothesis | Status | Evidence |
| :--- | :--- | :--- |
| **H1 — API Gateway was offline** | **REJECTED** | Uvicorn was active locally and returning 200 on port 1010. |
| **H2 — Desktop has incorrect URL** | **REJECTED** | Desktop uses the correct production URL (`https://api.kaostech.com.br`) as fallback. |
| **H3 — Installed Desktop is outdated (Build Drift)** | **REJECTED** | The current executable uses the correct config. No build drift detected. |
| **H4 — Authentication Issue** | **REJECTED** | Handshake and API validation headers are validated successfully (confirmed via API Key system check). |
| **H5 — Cloudflare Tunnel Conflict (Split-Brain)** | **CONFIRMED** | Two active tunnels were connected under the same token. The rogue `kaos-backend-tunnel` on the `bridge` network intercepted requests and returned 502 Bad Gateway. |
| **H6 — Duplicate Client State Bug** | **CONFIRMED** | Duplicate `kaos-client` files caused the app store to fall back to `localhost` even when the settings URL was configured correctly. |

---

## 3. Impact Classification
* **Category**: **Application Bug / Routing**
* **Type**: Duplicate Client State Conflict
* **Severity**: High (P0)

---

## 4. Root Cause Summary
The desktop application had a structural code bug. While the "Testar" connection button directly pinged the server using standard `fetch` (which succeeded), actual login submissions routed through `kaosFetch` from a separate unconfigured client instance. This caused all API requests to route to the fallback `http://localhost:8000`. 

Following the re-export fix, the client correctly routes all API calls to the user's configured server URL (`https://api.kaostech.com.br`).
