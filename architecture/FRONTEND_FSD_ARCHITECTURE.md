---
id: frontend_fsd_architecture
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Arquitetura Frontend FSD — K.A.O.S

## Stack

| Camada | Tecnologia |
|---|---|
| UI | React 18 + TypeScript |
| Bundler | Vite 5 |
| CSS | Tailwind CSS 3 + Design Tokens |
| Desktop Shell | Tauri v2 (Rust) |
| Store Local | TauriStoreService (Singleton sobre plugin-store) |
| HTTP Client | kaosFetch (fetch nativo) |

## Estrutura de Diretorios

```
desktop/
├── src/
│   ├── app/           # Inicializacao, Providers, Roteamento
│   ├── pages/         # Containers de tela (montam features)
│   ├── widgets/       # Sidebar, Command Palette
│   ├── features/      # Hooks de logica de negocios
│   ├── entities/      # Tipos de dados + componentes puros
│   └── shared/        # Design System, API, Utilitarios
├── src-tauri/
│   ├── src/
│   │   ├── main.rs    # Entrypoint Tauri
│   │   └── lib.rs     # Plugins, comandos Tauri (check_server, check_ollama)
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── capabilities/
│   └── icons/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
└── index.html
```

## Arquitetura em Camadas (FSD)

```
app/       pages/      widgets/    features/   entities/   shared/
┌─────┐   ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐
│     │──>│     │────>│     │────>│     │────>│     │────>│     │
└─────┘   └─────┘     └─────┘     └─────┘     └─────┘     └─────┘
  App      Pages       Widgets     Features    Entities    Shared
  (router)  (layouts)   (complexo)  (logica)   (domínio)   (base)
```

**Regra de Ouro:** Camadas superiores importam das inferiores. Nunca o contrario.

## Regras de Dependencia

| Camada | Pode Importar | Exemplo |
|---|---|---|
| `app/` | pages, widgets, features, entities, shared | `import { Sidebar } from "@/widgets/sidebar"` |
| `pages/` | widgets, features, entities, shared | `import { useChatStream } from "@/features/ask-ai"` |
| `widgets/` | features, entities, shared | `import { Button } from "@/shared/ui"` |
| `features/` | entities, shared | `import { TauriStoreService } from "@/shared/api"` |
| `entities/` | shared | `import { cn } from "@/shared/lib/utils"` |
| `shared/` | — | Nao importa nada do projeto |

## Fluxo de Inicializacao

1. Tauri inicia e carrega o frontend React
2. `main.tsx` monta `<App />` com StrictMode
3. `App.tsx` carrega apiKey do TauriStoreService (singleton)
4. App renderiza Sidebar + Main area
5. Sidebar controla navegacao entre paginas
6. Cada pagina carrega sua feature hook correspondente
7. useChatStream gerencia estado de mensagens + chamadas HTTP ao backend

## Comunicacao

```
React (UI) → kaosFetch → HTTP → FastAPI (porta 8000)
```

Nao ha IPC direto com o backend. Toda comunicacao passa por HTTP.

### TauriStoreService (Singleton)

O acesso ao plugin-store do Tauri e centralizado em um unico singleton:

```typescript
// shared/api/tauri-store-service.ts
export class TauriStoreService {
  private static instance = null;

  static async get<T>(key: string): Promise<T | null> {
    // Importa o modulo Tauri UMA VEZ, reusa para sempre
  }

  static async set(key: string, value: unknown): Promise<boolean> {
    // Singleton cacheado
  }
}
```

**Antes:** 4 `await import("@tauri-apps/plugin-store")` espalhados.
**Depois:** 1 import, cacheado em singleton, sem I/O duplicado.

## Design System

Ver `docs/vault/sdd/Refatoracao Frontend FSD.md` para detalhes completos dos componentes.

### Tokens de Cor

| Token | HEX | Uso |
|---|---|---|
| `bg-canvas` | `#09090b` | Fundo principal (Jet Black) |
| `bg-surface` | `#121214` | Paineis internos |
| `bg-elevated` | `#18181b` | Cards e modais |
| `text-primary` | `#f4f4f5` | Texto principal |
| `text-secondary` | `#a1a1aa` | Texto secundario |
| `accent` | `#1976d2` | Cor de destaque |

## Performance

- Buffer de 16ms para atualizacao de estado durante streaming de IA
- Tailwind CSS com GPU acceleration (sem inline styles)
- Componentes puros em entities/ evitam re-renderizacao em cascata
- Preparado para virtualizacao de listas longas (historico do chat)

## Auto-Update

O `tauri-plugin-updater` verifica novas versoes no GitHub Releases.

Configurado em `tauri.conf.json` com pubkey e endpoints.

Gatilho: qualquer tag `v*` no GitHub gera release com asset assinado.
