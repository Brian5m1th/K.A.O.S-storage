# K.A.O.S — Manual de Operações (Runbook)

Este documento contém instruções detalhadas e comandos passo a passo para a administração diária, manutenção de rotina, monitoramento de logs e resolução de problemas comuns (troubleshooting) do ecossistema K.A.O.S em produção.

---

## 1. Gerenciamento de Contêineres e Serviços

Todos os comandos de orquestração devem ser executados no diretório contendo o arquivo compose de produção (`/opt/kaos/infra/docker`):

### Iniciar a Stack Completa
```bash
docker compose -f docker-compose.prod.yml up -d
```

### Parar a Stack Completa
```bash
docker compose -f docker-compose.prod.yml down
```

### Reiniciar Serviço Específico (Zero Downtime para outros)
```bash
# Reiniciar kaos-api
docker compose -f docker-compose.prod.yml restart kaos-api

# Reiniciar banco vetorial Qdrant
docker compose -f docker-compose.prod.yml restart qdrant
```

---

## 2. Atualização de Imagens e Redeploy

Para forçar a atualização imediata das imagens de produção sem aguardar a esteira do CI/CD:

```bash
# 1. Acessar o diretório de produção
cd /opt/kaos/infra/docker

# 2. Baixar as últimas imagens do GHCR
docker compose -f docker-compose.prod.yml pull

# 3. Recriar e reiniciar os containers atualizados
docker compose -f docker-compose.prod.yml up -d

# 4. Remover imagens obsoletas/órfãs do disco
docker image prune -f
```

---

## 3. Estratégia e Comandos de Backup

### 3.1. Backup Automático do PostgreSQL
Gera um dump lógico compactado contendo todo o banco relacional:

```bash
# Executar dump do banco kaos e salvar compactado com data atual
docker exec kaos-platform-postgres-1 pg_dump -U kaos kaos | gzip > /opt/kaos/backup/postgres_kaos_$(date +%Y%m%d_%H%M%S).sql.gz
```

### 3.2. Backup do Banco Vetorial Qdrant
Qdrant fornece uma API de snapshots nativa para consistência dos dados indexados:

```bash
# 1. Solicitar a criação do snapshot via cURL
curl -X POST http://localhost:6333/collections/obsidian_memory/snapshots -o /opt/kaos/backup/qdrant_snapshot_meta.json

# 2. Copiar o arquivo de snapshot gerado da pasta do volume do Qdrant para a pasta de backup externa
docker cp kaos-platform-qdrant-1:/qdrant/snapshots/obsidian_memory/ /opt/kaos/backup/qdrant/
```

### 3.3. Backup de Volumes Físicos (Docker Data)
Para fazer cópia completa dos volumes mapeados no host:

```bash
# Parar os serviços antes do backup para evitar concorrência/corrupção de escrita
docker compose -f docker-compose.prod.yml stop

# Compactar diretórios de dados dos volumes
tar -czf /opt/kaos/backup/docker_volumes_$(date +%Y%m%d).tar.gz /opt/kaos/infra/docker/data/

# Reiniciar serviços
docker compose -f docker-compose.prod.yml start
```

---

## 4. Procedimentos de Restauração (Restore)

### 4.1. Restaurar Banco PostgreSQL
```bash
# 1. Parar a API do K.A.O.S para interromper conexões ativas
docker compose -f docker-compose.prod.yml stop kaos-api

# 2. Recriar o banco limpo
docker exec -i kaos-platform-postgres-1 psql -U kaos -d postgres -c "DROP DATABASE IF EXISTS kaos;"
docker exec -i kaos-platform-postgres-1 psql -U kaos -d postgres -c "CREATE DATABASE kaos;"

# 3. Descompactar e restaurar o backup
gunzip -c /opt/kaos/backup/postgres_kaos_20260710_000000.sql.gz | docker exec -i kaos-platform-postgres-1 psql -U kaos -d kaos

# 4. Reiniciar a API
docker compose -f docker-compose.prod.yml start kaos-api
```

### 4.2. Restaurar Snapshot do Qdrant
```bash
# Restaurar o snapshot da coleção diretamente via API do Qdrant
curl -X POST "http://localhost:6333/collections/obsidian_memory/snapshots/recover" \
     -H "Content-Type: application/json" \
     -d '{"location": "http://localhost:6333/snapshots/obsidian_memory/<NOME_DO_SNAPSHOT>.snapshot"}'
```

---

## 5. Gerenciamento do Cloudflare Tunnel

### Criar ou Renovar Credenciais do Túnel
Se o token do Cloudflare Tunnel expirar ou se você precisar redefinir o túnel `kaos-backend-tunnel`:
1. Acesse o painel **Cloudflare Zero Trust** ➔ **Access** ➔ **Tunnels**.
2. Clique em **Reset Token** na linha correspondente ao túnel.
3. Copie o novo Token fornecido.
4. No servidor de produção, edite o arquivo `.env.prod` e atualize a variável:
   ```env
   CLOUDFLARE_TUNNEL_TOKEN=seu_novo_token_aqui
   ```
5. Reinicie o contêiner do túnel para aplicar:
   ```bash
   docker compose -f docker-compose.prod.yml up -d --force-recreate cloudflared
   ```

---

## 6. Alteração de Domínio

Para migrar a aplicação para um novo domínio (ex: de `kaostech.com.br` para `kaosnew.com.br`):
1. **Configuração DNS:** Delegue o novo domínio na Cloudflare.
2. **Cloudflare Tunnel:** Vá em **Public Hostnames** do túnel no painel do Zero Trust e altere o domínio de todos os subdomínios cadastrados (`api`, `chat`, `n8n`, `whatsapp`) para o novo domínio selecionado.
3. **Variáveis de Ambiente:** No servidor de produção, acesse `.env.prod` e atualize as variáveis de CORS e URLs base:
   ```env
   CORS_ORIGINS=https://chat.kaosnew.com.br,tauri://localhost
   N8N_WEBHOOK_URL=https://n8n.kaosnew.com.br
   ```
4. Reinicie os contêineres afetados:
   ```bash
   docker compose -f docker-compose.prod.yml up -d --force-recreate kaos-api n8n
   ```

---

## 7. Limpeza e Coleta de Lixo (Garbage Collection)

O uso de contêineres e logs volumosos pode saturar o disco. Execute periodicamente:

### Limpar cache do Builder, redes órfãs e imagens sem tag
```bash
docker system prune -f
```

### Limpar imagens antigas não utilizadas por contêineres ativos
```bash
docker image prune -a -f
```

### Limpeza Física dos Arquivos de Log da API
```bash
# Esvaziar arquivo de logs json mantendo a estrutura
truncate -s 0 /opt/kaos/infra/docker/logs/kaos-api.json
```

---

## 8. Monitoramento de Logs

### Monitorar Logs da API em Tempo Real (Live Tail)
```bash
tail -f /opt/kaos/infra/docker/logs/kaos-api.json
```

### Filtrar Logs por Nível de Severidade
```bash
# Apenas Erros
grep '"level": "ERROR"' /opt/kaos/infra/docker/logs/kaos-api.json

# Apenas avisos de Drift
grep "drift" /opt/kaos/infra/docker/logs/kaos-api.json
```

### Loki & Grafana (Interface Gráfica)
1. Acesse `https://grafana.kaostech.com.br`.
2. Vá na aba **Explore**.
3. Selecione a fonte de dados **Loki**.
4. Use a Query LogQL para filtrar os logs da API de produção:
   ```logql
   {filename="/var/log/kaos-api/kaos-api.json"} |= "ERROR"
   ```

---

## 9. Troubleshooting e Diagnósticos Rápidos

### 1. Porta do Backend Ocupada
Se a API falhar ao iniciar por conflito de portas no host:
```bash
# Descobrir qual processo está ocupando a porta 1010
sudo lsof -i :1010
# Matar o processo conflitante
sudo kill -9 <PID>
```

### 2. Banco Vetorial Bloqueado/Travado
Se o Qdrant parar de responder a gravações por falta de espaço em disco ou corrupção de índice:
```bash
# Verificar logs do container Qdrant
docker compose -f docker-compose.prod.yml logs qdrant
# Se necessário, forçar reinicialização limpa
docker compose -f docker-compose.prod.yml restart qdrant
```

### 3. Verificar Saúde Física do Servidor
```bash
# Verificar uso de CPU e Memória por contêiner
docker stats --no-stream

# Verificar espaço livre em disco
df -h
```
