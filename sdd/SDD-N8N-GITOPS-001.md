# SDD-N8N-GITOPS-001 — Sincronização Automática de Workflows do n8n (GitOps)

## 1. Objetivo

Projetar e detalhar a arquitetura declarativa de infraestrutura como código (GitOps) para sincronização automática de workflows do n8n a partir do repositório Git do K.A.O.S. O repositório Git atua como a única fonte da verdade (Single Source of Truth), e o sistema gerencia o estado declarativamente nos ambientes de desenvolvimento, homologação e produção.

---

## 2. Estrutura do Repositório

Os workflows declarativos do n8n ficarão organizados no repositório de acordo com o seguinte layout:

```
automation/
  n8n/
    workflows/
      onboarding.json
      whatsapp-agent.json
      scheduler.json
    manifest.yaml
    sync.py
```

* **workflows/*.json:** O payload JSON completo exportado do n8n (contendo nós, conexões e configurações de metadados).
* **manifest.yaml:** Arquivo declarativo que mapeia a topologia e parametrização dos workflows por ambiente.
* **sync.py:** Script em Python que orquestra a normalização, comparação inteligente, validação e deploy dos workflows.

---

## 3. Manifesto Multi-Ambiente (`manifest.yaml`)

O manifesto suporta múltiplos estágios e gerencia dependências e identificadores persistentes de workflows:

```yaml
environments:
  development:
    url: "http://localhost:5678"
    api_key_env: "N8N_API_KEY_DEV"
  staging:
    url: "https://staging-n8n.kaostech.com.br"
    api_key_env: "N8N_API_KEY_STAGING"
  production:
    url: "https://n8n.kaostech.com.br"
    api_key_env: "N8N_API_KEY_PROD"

workflows:
  - id: "customer-onboarding"
    file: "onboarding.json"
    name: "Onboarding Customer"
    active: true

  - id: "whatsapp-agent"
    file: "whatsapp-agent.json"
    name: "WhatsApp Agentic Flow"
    active: true
    depends_on:
      - "customer-onboarding" # Garante ordem correta de deploy

  - id: "nightly-scheduler"
    file: "scheduler.json"
    name: "Nightly Scheduler"
    active: false
```

---

## 4. Arquitetura do Processo de Sincronização (`sync.py`)

A sincronização baseia-se exclusivamente na API REST v1 do n8n e no fluxo declarativo estruturado abaixo:

```
+-------------------+      Compara      +-----------------+
| workflows/*.json  | <---------------> |  manifest.yaml  |
+-------------------+                   +-----------------+
          |                                      |
          +──────────────────┬───────────────────+
                             v
                     +---------------+
                     |    sync.py    |
                     +---------------+
                             |
         1. Valida Sintaxe e Dependências locais
         2. Normaliza JSONs (remove updatedAt, etc.)
         3. Ordena deploy pela árvore de "depends_on"
                             |
                             v
                 +-----------------------+
                 | Backup de Estado Atual | (Salva backup em memória por ID)
                 +-----------------------+
                             |
                             v
                 +-----------------------+
                 |  API Rest v1 do n8n   | (GET /v1/workflows)
                 +-----------------------+
                 /           |           \
     POST /v1/workflows      |      PUT /v1/workflows/{id}
     (Criar Novos)           |      (Atualizar Modificados)
                             v
              POST /v1/workflows/{id}/activate
```

---

## 5. Recursos e Recursos de Engenharia

### 5.1. Identificador Estável por Workflow
Os workflows são mapeados pelo campo `id` definido no `manifest.yaml` (ex: `customer-onboarding`). O sincronizador usa este ID e as tags/descrições do n8n para identificar de forma unívoca o workflow correspondente, evitando conflitos por alteração ou colisão de nomes.

### 5.2. Comparação Inteligente (Normalização de JSON)
Para evitar deploys redundantes causados por alterações automáticas do n8n (ex: timestamps e IDs de sessões/versões), o `sync.py` normaliza o JSON local e o JSON remoto antes de calcular o hash de comparação.
* **Campos removidos na normalização:**
  - `updatedAt`
  - `createdAt`
  - `versionId`
  - `meta` (ou outros dados voláteis específicos do runtime).

### 5.3. Validação de Pré-Deploy (Linting)
Antes de enviar qualquer payload para a API, o script realiza verificações:
* Validade de sintaxe JSON.
* Presença de nós obrigatórios (como nós de Start ou Webhook).
* Validação de expressões e referências de links entre nós.
* Checagem de credenciais: O script inspeciona os nós do workflow em busca de dependências de credenciais. Caso a credencial exigida não esteja cadastrada na API do n8n, o deploy é abortado emitindo um alerta amigável detalhando a credencial ausente.

### 5.4. Ordenação por Dependência (`depends_on`)
Trata a árvore de dependência entre workflows (ex: sub-workflows chamados por outros fluxos). O deploy e ativação são executados na ordem topológica correta, minimizando falhas de vinculação de chamadas ativas.

### 5.5. Backup e Rollback Automático (Resiliência)
* Antes de realizar o `PUT` de atualização de um workflow, o `sync.py` realiza um `GET /v1/workflows/{id}` e guarda o estado estável remoto completo em memória/cache temporário.
* Se qualquer operação de deploy de um workflow falhar, o script inicia o rollback, aplicando o estado original salvo nos contêineres e deixando os workflows anteriores ativos, evitando estados inconsistentes na produção.

---

## 6. Exportação Automática (Fluxo Reverso / GitOps Sync)

Para evitar desvios de configuração (drift) causados por modificações legítimas feitas diretamente por desenvolvedores na interface web do n8n, implementamos um fluxo reverso:

1. **Webhook de Alteração:** O n8n é configurado para escutar alterações de workflow e disparar um gatilho.
2. **Exportador Periódico (Cron no Servidor):** Um script secundário faz `GET /v1/workflows` a cada 1 hora no ambiente de desenvolvimento/staging.
3. **Escrita local & Commit:** O script normaliza os arquivos JSON, escreve de volta no diretório `automation/n8n/workflows/` e, caso identifique divergências com a branch atual:
   - Cria uma branch específica (ex: `drift/workflow-updates-<timestamp>`).
   - Realiza o push para o GitHub.
   - Abre automaticamente um **Pull Request (PR)** para a branch principal (`main` ou `dev`) para aprovação do desenvolvedor.
