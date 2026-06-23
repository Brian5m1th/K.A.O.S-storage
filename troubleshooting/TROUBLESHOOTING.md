---
id: troubleshooting
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Troubleshooting — K.A.O.S

## Backend

### Erro: `ModuleNotFoundError: No module named 'assistant'`

**Causa:** `uv sync` não foi executado ou venv não ativada.

**Solução:**
```bash
cd assistant
uv venv
.venv\Scripts\Activate.ps1  # Windows
uv sync
```

### Erro: `sqlalchemy.exc.OperationalError: could not connect to server`

**Causa:** PostgreSQL não está rodando ou `DATABASE_URL` incorreta.

**Solução:** Verifique se o container PostgreSQL está ativo:
```bash
docker ps | findstr postgres
```

### Erro: `401 Unauthorized` no healthcheck ou curl

**Causa:** Header `X-API-Key` ausente ou inválido.

**Solução:**
```bash
curl -H "X-API-Key: kaos-dev-key" http://localhost:8000/api/setup/provider
```

### Erro: Provider retorna 503

**Causa:** Provider de LLM não está acessível (ex: Ollama não iniciou).

**Solução:** Verifique se o container do provider está rodando e a `base_url` está correta.

## Desktop

### Erro: `Command 'plugin-store' not found`

**Causa:** Plugin `tauri-plugin-store` não registrado no `tauri.conf.json`.

**Solução:** Verifique se o plugin está na lista `plugins` do `tauri.conf.json` e no `Cargo.toml`.

### Erro: `Failed to load settings from backend`

**Causa:** Backend não está rodando ou endpoint de provider inacessível.

**Solução:** Inicie o backend (`uv run uvicorn ...`) e verifique conectividade:
```bash
curl http://localhost:8000/health
```

### Janela em branco no Tauri dev

**Causa:** Vite dev server não iniciou ou porta incorreta.

**Solução:**
```bash
npm run dev  # Inicia Vite separadamente
# Ou
npm run tauri dev  # Inicia ambos
```

## Docker

### Erro: `port is already allocated`

**Causa:** Porta já em uso por outro processo/container.

**Solução:**
```bash
docker compose down
# Ou mude a porta no docker-compose.yml
```

### Container reinicia em loop

**Causa:** Healthcheck falhando.

**Solução:**
```bash
docker compose logs kaos-api
# Verifique se o backend consegue iniciar corretamente
```

## CI/CD

### Cosign: `parsing reference`

**Causa:** Uso de `${{ env.IMAGE_NAME }}` em vez de `${GITHUB_REPOSITORY,,}`.

**Solução:** Use `${GITHUB_REPOSITORY,,}` para lowercase expansion do bash.

### Checkout do submodule falha (404)

**Causa:** `GITHUB_TOKEN` não tem acesso a repositórios privados.

**Solução:** Use `secrets.PAT` (Repository secret) no lugar do `GITHUB_TOKEN`.

### paths-ignore não funciona

**Causa:** `paths` e `paths-ignore` combinados no mesmo trigger.

**Solução:** Use apenas `paths-ignore` com `!` negation patterns:
```yaml
on:
  push:
    paths-ignore:
      - "**/*.md"
```

## Resumo
- Informações pendentes de validação ou auto-geração.

## Objetivo
- Informações pendentes de validação ou auto-geração.

## Responsabilidades
- Informações pendentes de validação ou auto-geração.

## Dependencias
- Informações pendentes de validação ou auto-geração.

## Fluxos
- Informações pendentes de validação ou auto-geração.

## Integracoes
- Informações pendentes de validação ou auto-geração.

## Arquivos Relacionados
- Informações pendentes de validação ou auto-geração.

## Referencias KIRL
- Informações pendentes de validação ou auto-geração.

## Status
- Informações pendentes de validação ou auto-geração.

## Ultima Atualizacao
- Informações pendentes de validação ou auto-geração.
