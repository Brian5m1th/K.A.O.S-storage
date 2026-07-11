# CI/CD Deployment Pipeline Analysis

We investigated the GitHub Actions workflow [deploy.yml](file:///c:/workspace/Freelancer/K.A.O.S/.github/workflows/deploy.yml) running on the self-hosted runner at the production host.

---

## Answers to Key Investigation Questions

### 1. Qual pasta recebe o deploy?
O deploy é processado no workspace local do runner self-hosted:
`/home/dev/actions-runner/kaos/_work/K.A.O.S/K.A.O.S/infra/docker/`

### 2. Qual branch e commit?
* **Branch**: `main` (definido no gatilho `on: push: branches: [main]`)
* **Commit**: O commit mais recente na branch `main`. No deploy atual, é o `452fc57e9f75f256e48a39b28ac155378c175e09` (`452fc57`).

### 3. Qual compose é executado?
O comando executado é:
```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```
Este comando é executado no diretório `/home/dev/actions-runner/kaos/_work/K.A.O.S/K.A.O.S/infra/docker/` e cria contêineres sob o nome de projeto `kaos-platform`.

### 4. O deploy atualiza o container correto?
Sim, o deploy atualiza com sucesso os containers que fazem parte da stack do Docker Compose, como `kaos-platform-kaos-api-1` e `kaos-platform-cloudflared-1`.

---

## Critical Flaw in the Deploy Clean Step

The deployment workflow includes a cleanup step to remove old containers:
```yaml
- name: Clean Workspace Permissions
  run: |
    echo "Stopping existing containers to release volume mounts..."
    CONTAINERS=$(docker ps -a --filter "name=kaos-platform-" -q)
    if [ -n "$CONTAINERS" ]; then
      docker rm -f $CONTAINERS || true
    fi
    docker rm -f evolution_api_prod 2>/dev/null || true
```

### Analysis of the Flaw
* The clean script specifically filters for containers whose name matches `kaos-platform-`.
* The orphan/standalone tunnel container is named `/kaos-backend-tunnel` (it does not contain the `kaos-platform-` prefix).
* Consequently, `kaos-backend-tunnel` is **never stopped or removed** by the deploy pipeline. It remains running persistently on the host's `bridge` network, retaining its connection to the Cloudflare Tunnel using the same production token, resulting in traffic hijacking and 502 Bad Gateway errors.
