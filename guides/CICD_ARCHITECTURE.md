# Arquitetura de CI/CD — K.A.O.S

Este documento detalha a infraestrutura lógica de Integração Contínua (CI) e Entrega Contínua (CD) do ecossistema K.A.O.S, descrevendo os fluxos de trabalho, a política de versionamento de imagens e o mapeamento de variáveis de ambiente.

---

## 1. Fluxo Lógico e Ciclo de Vida do Pipeline

Para garantir estabilidade, segurança e separação de interesses, a arquitetura é dividida em dois workflows independentes no GitHub Actions:

```
[Desenvolvedor]
       │
   Git Push
       │
       ▼
[GitHub Repository] ➔ Dispara ➔ [CI Pipeline: ci.yml] (Validações, Lints, Tests, Build)
       │
  Merge na main
       │
       ▼
[Docker Hub / GHCR] ➔ Publica Imagem (kaos-api:sha-xxxx / kaos-api:latest)
       │
       ▼
[Deploy Pipeline: deploy.yml] (Acionado no runner local)
       │
       ▼
[Self-Hosted Runner no Servidor] ➔ Executa comandos locais:
       ├── docker compose pull
       ├── docker compose up -d
       └── docker image prune -f
       │
       ▼
[Health Check] ➔ Validar contêineres saudáveis
```

* **Pipeline de CI (`ci.yml`):** Responsável por testar, validar o type checking e empacotar o software em uma imagem Docker. Executa em toda Pull Request e commit enviado para as ramificações `dev` e `main`. **Nunca realiza alterações no servidor de produção.**
* **Pipeline de CD (`deploy.yml`):** Responsável pela atualização dos containers no servidor de produção de forma segura. Executa em um runner local (`self-hosted`) diretamente no servidor, sendo disparado automaticamente após merges na branch `main` ou manualmente via `workflow_dispatch`.

---

## 2. Estratégia de Versionamento de Imagens Docker

As imagens geradas durante a compilação do container da API (`kaos-api`) no GitHub Container Registry (GHCR) seguem políticas rígidas de tag:

| Tag da Imagem | Gatilho / Momento da Geração | Descrição / Uso |
| :--- | :--- | :--- |
| `latest` | Commit mesclado na branch `main`. | Sempre aponta para a imagem da última versão estável compilada. Utilizada para deploy padrão automático. |
| `sha-<commit_sha>` | Todo build bem-sucedido na branch `main`. | Tag imutável baseada no hash curto do commit do Git. Essencial para rastreabilidade e estratégia de Rollback. |
| `nightly` | Build periódico ou commits na branch `dev`. | Imagem de desenvolvimento instável para homologação local dos programadores. |
| `v*.*.*` | Publicação de uma release oficial com tag do Git. | Tag imutável para versões oficiais distribuídas em larga escala (coincide com os lançamentos das novas versões da Tauri app). |

---

## 3. Matriz de Configurações (.env)

O ecossistema utiliza três arquivos de ambiente para gerenciar as configurações entre os modos de desenvolvimento e produção:

| Variável de Ambiente | Obrigatória? | Valor Local / Dev | Valor Produção (Prod) | Descrição / Regra de Segurança |
| :--- | :---: | :--- | :--- | :--- |
| `APP_ENV` | Sim | `development` | `production` | Controla níveis de log e watchers de hot-reload. |
| `API_KEY` | Sim | `kaos-dev-key` | *Segredo randômico* | Chave mestra de autenticação do backend. **NUNCA commitar no Git**. |
| `DATABASE_URL` | Sim | `postgresql+psycopg://...` | `postgresql+psycopg://...` | String de conexão do banco Postgres. **NUNCA commitar no Git**. |
| `QDRANT_HOST` | Sim | `localhost` (ou `qdrant`) | `qdrant` | Nome do host do Qdrant resolve no Docker Compose. |
| `OLLAMA_BASE_URL` | Sim | `http://localhost:11434` | `http://ollama:11434` | Endereço do Ollama na rede interna Docker. |
| `HF_TOKEN` | Sim | `hf_...` | *Token específico* | Token do Hugging Face. **NUNCA commitar no Git**. |
| `N8N_API_URL` | Não | `http://localhost:5678` | `http://n8n:5678` | Endereço para despacho de webhooks ao n8n. |
| `CORS_ORIGINS` | Sim | `["http://localhost:3000"]` | `["tauri://localhost"]` | Origens autorizadas para requisições de navegadores. |

### Regras Críticas de Segurança
1. O arquivo `.env.example` serve apenas como referência e deve conter valores fictícios ou vazios. Ele é mantido no Git.
2. O arquivo `.env` (desenvolvimento) e o arquivo `.env.prod` (produção) contêm credenciais reais e são **explicitamente ignorados no arquivo `.gitignore`** para evitar vazamento acidental de tokens e senhas do banco.
3. No servidor de produção, o arquivo de ambiente real deve possuir permissões de leitura exclusivas ao usuário executor (`chmod 600 .env.prod`).

---

## 4. Esteira de Deploy Automatizado (Self-Hosted CD)

Ao utilizar o **Self-Hosted Runner**, o deploy ocorre de forma interna, dispensando o tráfego de chaves criptográficas SSH na nuvem e mitigando vulnerabilidades em portas expostas.

1. **Gatilho:** O push/merge na branch `main` dispara o job de CD no repositório.
2. **Distribuição:** O GitHub envia o job para a fila do runner local que roda no servidor.
3. **Download e Substituição:** O runner executa diretamente na máquina de produção os passos lógicos:
   * Realiza o pull da nova imagem baseada no Git SHA gerado no CI.
   * Modifica a tag ativa no arquivo `.env.prod`.
   * Executa `docker compose -f docker-compose.prod.yml up -d` para atualizar os containers afetados com zero downtime.
   * Realiza a limpeza de imagens antigas via `docker image prune -f` para conservar armazenamento.
4. **Verificação de Saúde (Health Check):** O runner consome a API local `/health` para garantir que o serviço responde adequadamente.
