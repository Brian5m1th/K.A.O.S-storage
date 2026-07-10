# SDD-OPS-001 — Runbook de Diagnóstico Operacional (K.A.O.S)

## 1. Visão Geral

Este documento define os procedimentos oficiais e a sequência lógica de investigação em caso de falhas ou indisponibilidade parcial/total nos serviços de produção do ecossistema K.A.O.S. O objetivo é restaurar os serviços com segurança, preservando dados e logs para análise post-mortem.

---

## 2. Sequência de Investigação (Ordem de Prioridade)

### 2.1. Passo 1: Armazenamento e Limites do Sistema
Antes de reiniciar qualquer serviço, verifique se a gravação de arquivos está bloqueada por falta de espaço físico ou falta de inodes.

* **Comando para espaço livre:**
  ```bash
  df -h
  ```
  *Ação corretiva se estiver >95%:* Prossiga imediatamente para o plano de limpeza de disco ([SDD-OPS-002](file:///c:/workspace/Freelancer/K.A.O.S/docs/sdd/SDD-OPS-002.md)).

* **Comando para inodes:**
  ```bash
  df -i
  ```
  *Ação corretiva se estiver >95%:* Significa que muitos arquivos pequenos (como logs quebrados ou temporários) consumiram o indexador. É necessário deletar arquivos órfãos.

---

### 2.2. Passo 2: Memória RAM e OOM Killer
Verifique se os contêineres principais (como `kaos-api` ou `postgres`) foram forçados a encerrar devido ao limite de memória física.

* **Comando para memória livre:**
  ```bash
  free -h
  ```
* **Comando para logs do Kernel (OOM):**
  ```bash
  dmesg -T | grep -i oom
  # Ou
  journalctl -k | grep -i oom
  ```
  *Sintoma:* Se houver saídas contendo `Killed process (python)` ou `Killed process (postgres)`, o serviço morreu por falta de memória física (Out Of Memory).

---

### 2.3. Passo 3: Estado dos Contêineres e Eventos
Investigue o estado geral do Docker e capture eventos recentes de reinicialização cíclica.

* **Status geral da Stack:**
  ```bash
  cd /opt/kaos/infra/docker
  docker compose -f docker-compose.prod.yml ps -a
  ```
* **Inspecionar estado dinamicamente (sem nomes fixos):**
  ```bash
  docker inspect $(docker compose -f docker-compose.prod.yml ps -q kaos-api) | grep -E "RestartCount|ExitCode|Health" -A 5
  ```
* **Monitorar eventos recentes:**
  ```bash
  # Captura eventos gerais do daemon do docker em tempo real na última hora
  docker events --since 1h
  ```

---

### 2.4. Passo 4: Validação do Banco PostgreSQL
Isolar se a queda da aplicação é devido ao banco PostgreSQL estar indisponível.

* **Verificar aceitação de conexões:**
  ```bash
  docker compose -f docker-compose.prod.yml exec postgres pg_isready
  ```
* **Executar query simples diretamente no banco:**
  ```bash
  docker compose -f docker-compose.prod.yml exec postgres psql -U ai-p -d kaos -c "SELECT 1;"
  ```
  *Se o Postgres falhar em responder mas estiver ativo, verifique se a senha foi alterada no `.env.prod`.*

---

### 2.5. Passo 5: Teste de Conectividade Interna (Docker Network)
Valide a comunicação entre os componentes ignorando o Cloudflare Tunnel para identificar gargalos de rede Docker.

* **Testar a API a partir do container do Cloudflare Tunnel:**
  ```bash
  docker compose -f docker-compose.prod.yml exec cloudflared curl -I http://kaos-api:8000/health
  ```
* **Testar a API localmente no seu próprio container:**
  ```bash
  docker compose -f docker-compose.prod.yml exec kaos-api curl -I http://localhost:8000/health
  ```
* **Testar o n8n a partir do container da API:**
  ```bash
  docker compose -f docker-compose.prod.yml exec kaos-api curl -I http://n8n:5678/healthz
  ```
