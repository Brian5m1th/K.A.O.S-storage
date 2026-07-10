# SDD-OPS-002 — Disaster Recovery & Limpezas Físicas (K.A.O.S)

## 1. Visão Geral

Este documento define os procedimentos de mitigação em caso de exaustão física de disco, corrupção de bancos de dados ou falhas catastróficas de startup.

---

## 2. Procedimento Seguro de Limpeza de Disco (Sem Perda de Dados)

Se o espaço em disco ou inodes do servidor esgotarem, execute a limpeza na seguinte ordem estrita para evitar a perda de dados persistentes importantes (como volumes de bancos de dados):

### Passo 1: Avaliar Uso de Disco do Docker
```bash
docker system df
```
Identifique se o gargalo são imagens órfãs, cache de compilação ou volumes inativos.

### Passo 2: Limpar Cache do Builder (Altamente Seguro)
```bash
docker builder prune -a
```
Remove arquivos gerados em builds anteriores do Docker. Não afeta contêineres em execução.

### Passo 3: Limpar Contêineres Parados/Inativos
```bash
docker container prune
```

### Passo 4: Limpar Imagens Não Utilizadas
```bash
# Executado apenas após os passos anteriores se o disco continuar cheio
docker image prune -a
```
*Atenção:* Isso fará com que o Docker precise baixar novamente as imagens se um container inativo for reiniciado.

### Passo 5: Truncar Arquivo de Logs Físico
Se o arquivo `kaos-api.json` estiver gigante e consumindo o host:
```bash
truncate -s 0 /opt/kaos/infra/docker/logs/kaos-api.json
```

---

## 3. Procedimento de Restauração de Dados

### 3.1. PostgreSQL (Restauração Lógica)
Para restaurar um backup relacional lógico:
```bash
# 1. Parar a API para interromper as conexões ativas no Postgres
docker compose -f /opt/kaos/infra/docker/docker-compose.prod.yml stop kaos-api

# 2. Recriar o banco de dados limpo
docker compose -f /opt/kaos/infra/docker/docker-compose.prod.yml exec -T postgres psql -U ai-p -d postgres -c "DROP DATABASE IF EXISTS kaos;"
docker compose -f /opt/kaos/infra/docker/docker-compose.prod.yml exec -T postgres psql -U ai-p -d postgres -c "CREATE DATABASE kaos;"

# 3. Descompactar e restaurar o backup
gunzip -c /opt/kaos/backup/postgres_kaos_<DATA>.sql.gz | docker compose -f /opt/kaos/infra/docker/docker-compose.prod.yml exec -T postgres psql -U ai-p -d kaos

# 4. Iniciar a API novamente
docker compose -f /opt/kaos/infra/docker/docker-compose.prod.yml start kaos-api
```

### 3.2. Qdrant (Restauração de Snapshots)
Para restaurar snapshots vetoriais da coleção `obsidian_memory`:
```bash
curl -X POST "http://localhost:6333/collections/obsidian_memory/snapshots/recover" \
     -H "Content-Type: application/json" \
     -d '{"location": "http://localhost:6333/snapshots/obsidian_memory/<NOME_SNAPSHOT>.snapshot"}'
```
