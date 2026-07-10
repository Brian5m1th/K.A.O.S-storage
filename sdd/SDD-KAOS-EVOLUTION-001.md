# SDD-KAOS-EVOLUTION-001 — K.A.O.S Evolution Blueprint
*Technical Refinement, Living Architecture & Product Evolution Roadmap*

---
id: SDD-KAOS-EVOLUTION-001
type: strategic-sdd
status: approved
phase: future-stabilization
tags:
  - architecture
  - evolution-roadmap
  - design-principles
  - kaos
---

## 1. Princípios Arquiteturais Fundamentais

Este documento define os princípios permanentes e a direção técnica do K.A.O.S a longo prazo. Toda e qualquer nova funcionalidade ou refatoração estrutural deve se submeter aos seis pilares listados abaixo:

1.  **Runtime Agnostic Principle:** Nenhuma Capability pode possuir dependência física ou acoplamento a um fornecedor, modelo de IA ou motor de banco de dados específico. A infraestrutura e as engines são commodities substituíveis.
2.  **Capability-First Architecture:** O sistema é organizado e subdividido de acordo com suas capacidades de negócio/operação, não pela tecnologia que utiliza. Cada Capability gerencia seu próprio ciclo de vida, rotas, manifestos e testes.
3.  **Provider Abstraction Layer:** O acesso a recursos externos (LLMs, bancos de dados, serviços de mensagens, MCPs) é intermediado por Runtimes abstratos. As capacidades conversam com as abstrações; os adaptadores tratam dos detalhes de baixo nível.
4.  **Event-Driven Collaboration:** A comunicação entre diferentes domínios e Capabilities deve ser prioritariamente assíncrona baseada em eventos, eliminando encadeamentos diretos e chamadas síncronas bloqueantes entre submódulos.
5.  **Auto-Discoverability:** A inicialização e registro de Runtimes e Capabilities ocorrem de forma autônoma (manifest-driven) no boot do servidor, eliminando a necessidade de mapeamento manual nas rotas principais do FastAPI.
6.  **Observability by Design:** Todo componente do ecossistema expõe ativamente seu estado de saúde, dependências, erros acumulados, custos de processamento (tokens/USD) e latência média para o painel de monitoramento.

---

## 2. Nova Estrutura de Diretórios Orientada a Capacidades

Para mitigar a dispersão de responsabilidades, o K.A.O.S migrará gradativamente da organização baseada em camadas técnicas (`api/`, `services/`, `runtime/`, `core/`) para uma estrutura baseada em **Capacidades Independentes**:

```text
assistant/
├── app/
│   ├── capabilities/
│   │   ├── chat/
│   │   ├── memory/
│   │   ├── workspace_intelligence/
│   │   ├── communication/
│   │   ├── orchestration/
│   │   ├── observability/
│   │   ├── documentation/
│   │   └── plugins/
│   ├── core/                  # Kernel do sistema (event bus, config service, etc.)
│   └── main.py                # Ponto de entrada (carregamento dinâmico de manifestos)
```

Cada diretório de Capability (ex: `app/capabilities/communication/`) conterá:
*   `manifest.yaml`: Declaração de identidade, permissões, dependências, rotas expostas e comandos suportados.
*   `api/`: Rotas FastAPI expostas por essa Capability.
*   `runtime/`: Abstrações de execução e seleção de adaptadores.
*   `services/`: Lógica interna do domínio.
*   `providers/` ou `adapters/`: Implementações de drivers específicos (ex: Evolution API, Meta Cloud API).
*   `events/`: Assinantes de eventos de domínio.
*   `models/`: Esquemas Pydantic e entidades SQLAlchemy locais.
*   `tests/`: Testes de integração e unitários dedicados.

---

## 3. Runtime Registry Centralizado

Para acomodar múltiplos motores operacionais à medida que a plataforma expande, introduzimos a abstração do **Runtime Registry**:

```text
                 RuntimeRegistry
                        │
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
     AI Runtime    Comm Runtime   Storage Runtime
                        │
                        ▼
                Memory Runtime
                Workflow Runtime
                Tool Runtime
                Plugin Runtime
                Automation Runtime
                Index Runtime
                Embedding Runtime
```

Qualquer submódulo ou agente pode localizar e consumir runtimes de forma dinâmica:
```python
# Exemplo de consumo agnóstico
runtime = RuntimeRegistry.get("communication")
await runtime.send(to="+55...", message="Hello World", channel="whatsapp")
```

---

## 4. Capability Lifecycle & Manifests

### Ciclo de Vida da Capability
Cada Capability mapeará e atualizará seu estado dinamicamente no `CapabilityRegistry` em resposta à integridade do seu ambiente:

```text
  CREATED ➔ REGISTERED ➔ INITIALIZED ➔ HEALTHY ➔ DEGRADED ➔ FAILED
                                          ▲                     │
                                          │                     ▼
                                      RECOVERING ◄────────── DISABLED
```

### Exemplo de Manifesto (`manifest.yaml`)
```yaml
id: workspace_intelligence
version: 1.0
owner: Architecture
permissions:
  - vault_read
  - filesystem_write
dependencies:
  - memory_runtime
  - embedding_runtime
  - ai_runtime
health:
  endpoint: /api/workspace-intelligence/health
events_subscribed:
  - vault.updated
  - git.commit_detected
commands_exposed:
  - auto_tag
  - suggest_links
  - detect_duplicates
  - check_vault_health
```

---

## 5. Workspace Intelligence Capability

Em vez de focar apenas no Obsidian Vault, a **Workspace Intelligence Capability** adquire a responsabilidade de monitorar e otimizar a integridade global do espaço de trabalho do desenvolvedor:

```text
Workspace Intelligence
├── Vault (notas, rascunhos, links órfãos, frontmatter YAML)
├── Repository (saúde do código, dependências, duplicidade lógica)
├── Documentation (DRIFT do commit contra o código, KIRL inconsistencies)
├── Knowledge Graph (vínculos conceituais, entidades órfãs)
└── Continuous Learning (histórico de correções do usuário)
```

Toda chamada à base vetorial ou banco de dados relacional é intermediada de forma agnóstica via **Knowledge Runtime** (abstraindo Qdrant, Postgres, SQLite ou qualquer backend gráfico).

---

## 6. Credential Service Plugável

O armazenamento de credenciais sensíveis é centralizado no `CredentialService`, que gerencia diferentes backends de segurança com base no sistema operacional do host:

```text
Credential Service
├── File Encrypted Provider (fallback seguro local)
├── Windows Credential Manager Provider (Windows)
├── macOS Keychain Provider (macOS)
├── Linux Secret Service Provider (Linux)
└── Vault Cloud Provider (ex: AWS Secrets, Hashicorp Vault)
```

Isso garante que chaves como `WHATSAPP_API_KEY`, `OPENAI_API_KEY` ou `GITHUB_TOKEN` nunca fiquem expostas em arquivos de texto plano de forma estática.
