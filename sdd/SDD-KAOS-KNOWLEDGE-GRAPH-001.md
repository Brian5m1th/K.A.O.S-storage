# SDD-KAOS-KNOWLEDGE-GRAPH-001
## Knowledge Graph — K.A.O.S Desktop

---

| Campo | Valor |
|---|---|
| **ID** | SDD-KAOS-KNOWLEDGE-GRAPH-001 |
| **Status** | 🟡 Draft |
| **Versão** | 1.0 (Draft) |
| **Prioridade** | Alta |
| **Autor** | Antigravity Pair Programmer / Brian5m1th |
| **Data** | 2026-06-28 |
| **Stack** | Desacoplada (FastAPI Backend + React Flow/Zustand Frontend) |
| **Risco** | Médio |
| **Complexidade** | Alta |
| **Posição no Roadmap** | Fase 2 (Graphify / Knowledge Graph Explorer) |

---

## 1. Objetivo

Definir a arquitetura da funcionalidade **Knowledge Graph** do K.A.O.S Desktop, responsável por representar, armazenar, consultar e visualizar o conhecimento do projeto em forma de grafo. Este componente serve como infraestrutura compartilhada para inteligência artificial, observabilidade, documentação, análise de impacto arquitetural e exploração visual interativa pelo usuário.

---

## 2. Contexto

O ecossistema K.A.O.S possui diversas fontes de informação desacopladas:
* **Código-fonte** (Componentes frontend/backend, hooks, stores, APIs)
* **Workflows** (Fluxos N8N, automações locais)
* **MCPs (Model Context Protocol)** (Serviços e ferramentas integradas)
* **Providers** (Configurações de modelos LLM e conexões de APIs de IA)
* **Agentes** (Instruções, estados, playgrounds, logs)
* **Prompt Vault** (Biblioteca de templates e diretrizes de IA)
* **Documentação** (Artigos Wiki, documentação funcional/técnica)
* **Git** (Histórico de commits, tags)
* **Issues e Pull Requests** (Rastreamento de tarefas e alterações)
* **Runtime** (Estados de execução dos microsserviços)
* **Observabilidade** (Métricas de latência, logs de eventos, tokens, custos)

Atualmente, essas fontes permanecem isoladas. O **Knowledge Graph** consolidará essas informações em um modelo unificado de nós e arestas relacionais, permitindo cross-referencing e enriquecimento contextual para agentes de IA e interfaces visuais.

---

## 3. Problema

O sistema não possui uma representação explícita e unificada das relações entre seus diversos componentes físicos e lógicos.

Como consequência, observamos:
* **Dificuldade de navegação**: Usuários e agentes precisam inferir relações manualmente.
* **Baixa descoberta de dependências**: Risco elevado de alterações de código gerarem efeitos colaterais silenciosos em workflows, agentes ou documentações.
* **Pouca reutilização de contexto pela IA**: Limitação na eficácia dos prompts por falta de contexto topológico relevante.
* **Ausência de análise de impacto**: Impossibilidade de rastrear quais partes do sistema dependem de uma funcionalidade antes de sua alteração/refatoração.
* **Arquitetura pouco explorável**: A ausência de representação visual dificulta a compreensão global do ecossistema.

---

## 4. Objetivos

* **GOAL-001**: Representar o conhecimento do workspace de forma abstrata como um grafo de nós (entidades) e arestas (relações).
* **GOAL-002**: Fornecer suporte a interfaces visuais de exploração (ex: React Flow no desktop).
* **GOAL-003**: Permitir consultas eficientes e estruturadas pela IA (contexto estendido e RAG topológico).
* **GOAL-004**: Suportar evolução incremental do grafo para evitar recriação total a cada pequena mudança de arquivo.
* **GOAL-005**: Servir como infraestrutura e base comum para futuras funcionalidades, incluindo o *Graphify* e o *AI Vault Analyzer*.

---

## 5. Fora de Escopo

Este documento de design de arquitetura **não define**:
* O algoritmo específico de layout visual das coordenadas dos nós (ex: Force-Directed, ELK, Dagre).
* O banco de dados de grafo físico a ser eventualmente adotado (Neo4j, Memgraph, Sqlite com extensões, etc.).
* A biblioteca de renderização gráfica do frontend (embora o frontend atual adote React Flow, o design do modelo do grafo deve ser agnóstico à biblioteca).
* A lógica e regras internas de extração de dados (parsers e providers individuais).

Essas definições operacionais e tecnológicas específicas serão detalhadas em especificações técnicas específicas de implementação de cada componente.

---

## 6. Stakeholders

* **Usuário Desktop**: Necessita visualizar, explorar e buscar relações entre arquivos, documentações, e componentes do projeto.
* **IA**: Necessita extrair subgrafos contextuais de forma rápida para compor prompts inteligentes.
* **Runtime**: Registra eventos dinâmicos que podem alterar o estado de nós e arestas temporariamente.
* **AI Vault Analyzer**: Analisa e audita o Vault de documentação contra o estado real do código.
* **Graphify**: Módulo visual para visualização e análise de topologia e acoplamento.
* **Documentação & Plugins**: Módulos que geram ou consomem informações catalogadas no grafo.
* **MCPs (Model Context Protocol)**: Consomem o grafo como parte de ferramentas oferecidas às IAs.

---

## 7. Requisitos (EARS)

### 7.1 Ubiquitous (Ubíquos)

* **REQ-001**: O sistema **DEVE** manter uma representação unificada de grafo do workspace.
* **REQ-002**: O sistema **DEVE** representar entidades e relacionamentos de forma agnóstica à linguagem de programação.
* **REQ-003**: O sistema **DEVE** identificar de forma única cada nó através de uma URI/ID persistente e previsível (ex: combinando escopo de namespace, tipo e caminho relativo).
* **REQ-013**: O sistema **DEVE** ser totalmente compatível com a arquitetura do K.A.O.S Desktop.
* **REQ-014**: O sistema **DEVE** se integrar ao backend do Desktop por meio de abstrações de serviços existentes, sem ignorar a arquitetura da aplicação.
* **REQ-015**: O sistema **DEVE** operar corretamente tanto em ambientes Desktop portáteis (Portable Mode) quanto em instalações convencionais.
* **REQ-016**: O sistema **DEVE** funcionar perfeitamente sem exigir conectividade de rede externa para suas capacidades de infraestrutura central.

### 7.2 Event Driven (Baseados em Eventos)

* **REQ-004**: **QUANDO** um workspace for aberto, o sistema **DEVE** sincronizar o grafo.
* **REQ-005**: **QUANDO** um arquivo mudar no workspace, o sistema **DEVE** atualizar apenas os nós e arestas afetados por aquela mudança (sincronização incremental).
* **REQ-006**: **QUANDO** um plugin registrar novas entidades, o sistema **DEVE** incorporá-las ao modelo unificado.
* **REQ-007**: **QUANDO** eventos de runtime ocorrerem (ex: execuções de agentes, chamadas de API, erros de observabilidade), o grafo **DEVE** refletir e atualizar o estado de execução nos nós correspondentes.
* **REQ-017**: **QUANDO** o workspace ativo do Desktop mudar, o sistema **DEVE** sincronizar o Knowledge Graph correspondente ao novo escopo.

### 7.3 Optional (Opcionais)

* **REQ-008**: **ONDE** a visualização de grafo estiver disponível, o usuário **DEVE** conseguir navegar e navegar dinamicamente através de entidades conectadas.
* **REQ-009**: **ONDE** o contexto de IA for solicitado, o grafo **DEVE** expor entidades relacionadas para enriquecer o prompt do modelo.

### 7.4 Unwanted (Tratamento de Exceções)

* **REQ-010**: **SE** a geração/sincronização do grafo falhar, o sistema **DEVE** preservar o último estado consistente conhecido.
* **REQ-011**: **SE** uma entidade individual não puder ser processada/parseada, o sistema **DEVE** registrar a falha de processamento no log do serviço sem interromper a sincronização do restante do grafo.
* **REQ-012**: **SE** existirem dependências circulares entre entidades, o grafo **DEVE** representá-las normalmente sem causar estouro de pilha (stack overflow) ou perda de dados.

---

## 8. Requisitos Arquiteturais (GEARS)

### 8.1 Goal (Objetivo)
O Knowledge Graph deve consolidar-se como um serviço compartilhado de primeira classe da plataforma K.A.O.S Desktop, consumido por todas as partes e módulos da aplicação.

### 8.2 Environment (Ambiente de Execução)
A solução deve operar em:
* Desktop (suporte multi-plataforma: Windows, Linux e macOS).
* Modo Offline (operação 100% local, sem dependência de serviços externos ou SaaS).
* Portable Mode (com portabilidade completa de caminhos e arquivos).
* Instalações convencionais.
* Escopo de múltiplos projetos simultâneos e grandes repositórios locais.

### 8.3 Assumptions (Premissas)
Assume-se que:
* Novos tipos de entidades de código e arquivos surgirão constantemente.
* Plugins de terceiros poderão registrar entidades customizadas e novos tipos de arestas.
* Modelos de IA locais e remotos consultarão o grafo para construção de contexto.
* Ferramentas internas como *Graphify*, *AI Vault Analyzer* e painéis de *Observabilidade* dependerão desta infraestrutura.

### 8.4 Requirements (Requisitos Estruturais)
A arquitetura do Knowledge Graph deve ser compatível e extensível com:
* Ciclo de vida da aplicação K.A.O.S Desktop (startup, idle, workspace-switch, shutdown).
* Gerenciamento centralizado de configurações (`ConfigService`).
* Resolução dinâmica de caminhos de arquivos por meio do `RuntimePathResolver`.
* Sistema de eventos internos da plataforma para notificar alterações topológicas.
* Estado global do frontend (através das Zustand stores do Desktop).
* Evolução de esquema sem quebrar compatibilidade retroativa das APIs existentes.

### 8.5 Strategy (Estratégia de Implementação)
A implementação deve seguir uma arquitetura orientada a serviços (SOA) local. Toda comunicação do Knowledge Graph deve ocorrer através das camadas oficiais do Desktop (serviços, eventos e APIs internas baseadas em REST/IPC), evitando acessos diretos arbitrários ao sistema de arquivos que violem o isolamento do `RuntimePathResolver` ou que impeçam a portabilidade. A extração de dados deve ser desacoplada da camada visual e da engine de persistência física por meio de interfaces abstratas de "Extractors" e "Providers".

---

## 9. Diretrizes de Governança Arquitetural

> [!IMPORTANT]
> **ARCH-001: Compatibilidade Arquitetural Obrigatória**
>
> Toda nova funcionalidade ou módulo integrado ao K.A.O.S deve ser compatível com a arquitetura Desktop existente e planejada, incluindo:
> * **Portable Mode** (nenhum caminho absoluto hardcoded; uso estrito do `RuntimePathResolver`).
> * **ConfigService** (centralização de configurações).
> * **Sistema de Plugins** (capacidade de extensibilidade dinâmica).
> * **Observabilidade** (registro e auditoria de estados e métricas).
> * **Serviços nativos** (Graphify, AI Vault Analyzer, etc.).
>
> Não é permitida a introdução de acoplamentos fortes ou acessos diretos que limitem a evolução, portabilidade ou integridade multi-plataforma da aplicação.

---

## 10. Respostas & Recomendações para Perguntas Arquiteturais (Open Questions)

Abaixo estão as análises arquiteturais para as doze questões em aberto originais do rascunho:

### Q1: Qual será a Source of Truth (Fonte da Verdade) do grafo?
* **Análise/Decisão**: O workspace do usuário (código, documentações Markdown, configurações, arquivos de workflow) é a única Fonte da Verdade definitiva. O Knowledge Graph atua como um índice otimizado (Read Model/Materialized View) derivado dessas fontes de dados físicas primárias.

### Q2: O grafo será persistido ou reconstruído?
* **Análise/Decisão**: Persistido em disco e atualizado incrementalmente. Uma reconstrução completa no startup é aceitável como estratégia de fallback (ou primeira abertura do projeto), mas a persistência em um arquivo estruturado JSON local (ou base embarcada) é necessária para carregamento rápido e suporte offline.

### Q3: Como versionar o esquema do grafo?
* **Análise/Decisão**: O formato JSON exportado ou consumido pelas APIs deve conter um campo explícito de versão (ex: `"version": "1.0"`). O backend do serviço deve implementar lógica de migração automática ou descarte/reconstrução do cache local caso a versão suportada mude.

### Q4: Como representar múltiplos workspaces?
* **Análise/Decisão**: Cada workspace aberto no K.A.O.S Desktop gerencia seu próprio diretório `.opencode` e diretório `docs/runtime/architecture` dinamicamente resolvidos pelo `RuntimePathResolver`. Portanto, o Knowledge Graph é estritamente isolado no nível de workspace físico, eliminando sobreposições ou misturas de informações de diferentes projetos.

### Q5: Como sincronizar mudanças incrementais?
* **Análise/Decisão**: Utilização de um Watcher de sistema de arquivos integrado ao backend. Quando um arquivo muda, o serviço identifica o arquivo modificado, chama o Extractor específico daquele tipo de arquivo, remove os relacionamentos antigos daquele nó e insere os novos, sem precisar varrer todo o restante do workspace.

### Q6: Como integrar runtime e observabilidade?
* **Análise/Decisão**: O Knowledge Graph deve disponibilizar endpoints de mutação ou canais de eventos rápidos (IPC/Websockets locais) onde o Runtime e a Observabilidade possam anexar metadados dinâmicos e temporários (ex: "tempo de resposta", "último erro", "status ativo/inativo") nos nós correspondentes aos agentes, workflows ou provedores.

### Q7: Como permitir extensões por plugins?
* **Análise/Decisão**: Definição de uma API de registro de esquemas de nós e arestas. Um plugin pode expor um manifesto declarando os novos tipos de entidades e arestas que ele gerencia, além de se registrar no pipeline do Watcher para fornecer parsers para extensões específicas de arquivo.

### Q8: Como a IA consultará o grafo?
* **Análise/Decisão**: O serviço do Knowledge Graph no backend deve expor um serviço auxiliar de consulta topológica (ex: busca por vizinhança de N graus, busca por caminhos entre nós, ou filtragem por tipos de arestas). Esse serviço expõe ferramentas em formato de MCP (Model Context Protocol) permitindo que agentes LLM façam buscas semânticas e topológicas ativamente.

### Q9: Como lidar com projetos muito grandes?
* **Análise/Decisão**: O scanner deve ignorar pastas gigantes de dependências (ex: `node_modules`, `.git`, `venv`, `dist`, `target`) por padrão por meio de regras de exclusão globais (como `.gitignore` ou `.antigravityignore`). O parser de código deve utilizar ASTs eficientes e técnicas de cache incremental para manter o tempo de resposta do indexador sob controle.

### Q10: Como exportar/importar grafos?
* **Análise/Decisão**: Sendo o grafo armazenado em um formato unificado JSON no diretório de runtime do workspace (`knowledge-graph.json`), exportar e importar resume-se à cópia estruturada desse arquivo. Ele pode ser exportado para formatos comuns como GEXF, GraphML ou CSV para ferramentas externas de análise (como Gephi).

### Q11: Como representar diferentes linguagens de programação?
* **Análise/Decisão**: Normalização do modelo de dados. Independentemente de ser um arquivo TypeScript, Python ou Rust, o grafo representa os mesmos conceitos abstratos de forma agnóstica (ex: tipo de nó `store`, `endpoint`, `logic`, `interface`) e relações comuns (`imports`, `calls`, `defines`). Os parsers específicos da linguagem realizam essa tradução para o modelo normalizado.

### Q12: Como medir desempenho e escalabilidade?
* **Análise/Decisão**: Registro de logs estruturados de telemetria interna monitorando o tempo de indexação inicial, o tempo de atualização incremental por arquivo e o consumo de memória RAM do backend. Esses logs devem ser integrados ao painel de Observabilidade do K.A.O.S Desktop.

---

## 11. Critérios de Aceite

O projeto de implementação da arquitetura do Knowledge Graph será considerado aceito ao cumprir:
1. **Rastreabilidade total**: Todos os requisitos EARS (REQ-001 a REQ-017) e GEARS estão documentados e mapeados para soluções ou diretrizes de implementação.
2. **Resolução de dúvidas**: Todas as doze perguntas arquiteturais estão documentadas com respostas claras e direcionamentos técnicos para o desenvolvimento.
3. **Neutralidade tecnológica**: O documento não força o uso de uma tecnologia gráfica ou banco de dados específico, permitindo evolução da stack.
4. **Isolamento de ambiente**: O modelo projetado é estritamente autocontido, compatível com Portable Mode e sem dependência de nuvem.
5. **Base para especificação**: O SDD serve como base explícita para criação das especificações técnicas, planos de implementação e tarefas no `task.md`.
