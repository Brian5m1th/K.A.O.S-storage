# SDD-KAOS-UXUI-001 — K.A.O.S Frontend, UX & Design System Modernization

- **Status**: Aprovado & Implementado
- **Data**: 2026-06-25
- **Autor**: Antigravity Pair Programmer
- **Versão**: 1.0

---

## 1. Objetivo
Elevar a experiência do K.A.O.S Desktop ao padrão de ferramentas modernas (Cursor, Linear, Obsidian, VSCode) por meio de uma auditoria global e reestruturação do design system, navegação lateral colapsável, caixa de comandos, e a criação de novas páginas e ferramentas interativas de produto.

---

## 2. Especificação Técnica das Mudanças

### 🎨 2.1 Design System V2 & Temas Dinâmicos
* ** CSS Custom Properties (`globals.css`)**: Definidos tokens de espaçamento, bordas e sombras no `:root` (`--radius-*`, `--duration-*`, `--shadow-*`).
* **Scrollbars e Estados nativos**: Removidas todas as cores hexadecimais estáticas do arquivo CSS. Elementos como scrollbars, anel de foco (`focus-visible`) e campos `disabled` agora usam variáveis CSS dinâmicas como `var(--accent-primary)`, `var(--border-subtle)` e `var(--text-dim)`.
* **Tokens de Elevação (`theme-store.ts`)**: Adicionados os tokens `--surface-raised`, `--surface-elevated` e `--surface-hover` com cores harmônicas para cada um dos 8 temas disponíveis (Dark, Light, Kaos Blue, Purple, Terminal, Cyberpunk, Nordic, Forest).
* **Mapeamento Tailwind (`tailwind.config.js`)**: Extendidos as propriedades de cores de superfície, bordas, sombras e durações de animação para herdar as custom properties correspondentes.

### 📂 2.2 Sidebar V2 (Navegação Colapsável)
* **Organização**: Itens agrupados logicamente em seções de produto:
  * **Core**: Dashboard, Chat
  * **Intelligence**: Agents, Orquestração, Prompt Library
  * **Knowledge**: Knowledge Vault, Knowledge Graph, Graphify Docs
  * **DevOps**: Pipelines, Observability, Event Explorer, Tools & Registry
  * **System**: Users, Doc Health, Cost Center, Settings
* **Colapso Dinâmico**: Menu colapsável com tamanho reduzido (60px) controlado via Zustand state (`useUIStore`), exibindo apenas ícones com tooltips flutuantes no modo compacto.
* **SVG Branding**: Cabeçalho contém um logotipo vetorial customizado da letra **K** que pulsa suavemente de acordo com o status operacional.
* **Ctrl+K Hint**: Dica visual no rodapé para busca global rápida.

### ⌨️ 2.3 Command Palette
* Atualizado o contexto do `CommandPalette` (`widgets/command-palette/index.tsx`) para garantir compatibilidade com os temas expandidos. O comando "Toggle Theme" agora alterna perfeitamente entre os modos claro/escuro utilizando os seletores dinâmicos do `useThemeStore`.

### 🤖 2.4 Agents Playground & Form Modals
* **New Agent**: Adicionado modal acessível com `Dialog` que permite configurar nome, modelo (dropdown para Qwen3, Llama3, Claude, etc.), system prompt (instruções), temperatura e top-p.
* **Playground Chat**: Interface de chat embarcada na aba Playground que faz streaming de respostas do backend (`/api/chat/message`). Se o agente estiver inativo (`idle`), exibe um CTA amigável com botão para iniciá-lo.

### 📊 2.5 Dashboard V2 & Pipelines
* **Personalização**: Saudação personalizada contendo o nome/email do usuário autenticado no sistema.
* **Quick Actions**: Atalhos rápidos para operações frequentes (New Chat, Run Agent, Open Vault, View Docs).
* **System Alerts**: Painel de alertas reais e críticos consumidos diretamente da API do backend (`/api/notifications`).
* **Conventional Badges**: Badges visuais de `SIMULATED` aplicadas em recursos mocks para dar clareza entre dados reais e dados simulados de desenvolvimento.
* **Simulador de Pipelines**: O botão "Trigger Manual" simula um fluxo assíncrono em tempo real, transitando estados de `pending` -> `running` -> `success` / `failed` dinamicamente.

### 🌐 2.6 Novas Páginas (Stubs & Rotas)
* **`/welcome`**: Assistente de primeiro login estruturado em 3 passos para configurar o endereço do servidor backend, escolher provedor de IA e realizar testes de conectividade.
* **`/prompts`**: Hub de consulta de prompts de sistema categorizados com opção de cópia rápida.
* **`/events`**: Monitor visual do EventBus em tempo real.
* **`/costs`**: Painel para acompanhamento financeiro de consumo de tokens.

---

## 3. Plano de Verificação

### Testes Executados
1. **TypeScript compilation**: Executado `npx tsc --noEmit` no diretório `desktop`, terminando com **0 erros**.
2. **Production Bundle**: Executado `npm run build` gerando os arquivos estáticos de produção com sucesso em 5.14 segundos.
3. **Rust Backend**: Verificada a conformidade do arquivo `updater.rs` com as flags de desativação de warnings de código inalcançável.
