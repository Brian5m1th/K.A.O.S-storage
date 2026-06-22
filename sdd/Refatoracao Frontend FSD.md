---
type: knowledge
domain: frontend
status: implemented
---

# Refatoracao Frontend FSD
*Feature-Sliced Design + Design System Premium*

> SDD completo da refatoracao do frontend desktop K.A.O.S

## Parent
- [[Documentation/architecture/DESKTOP_ARCHITECTURE]]

## Children

## Related
- [[Documentation/architecture/FRONTEND_FSD_ARCHITECTURE]]
- [[Documentation/governance/DOCUMENTATION_GOVERNANCE_SDD]]

## Tags
#kaos #frontend #fsd #react #tauri #refactoring

---

## Conteudo

### Objetivo

Refatorar o frontend desktop K.A.O.S de uma arquitetura monolitica (4 telas em components/) para Feature-Sliced Design (FSD), adicionando Design System premium com Tailwind CSS, otimizacao de performance para streaming de IA, e preparacao para escalabilidade futura.

### Diagnostico Anterior

| Metrica | Valor |
|---|---|
| Maturidade | 3.5 / 10 |
| Arquivos fonte | 6 (monolitos) |
| Estilos | 100% inline styles |
| Streaming | `stream: false` (bloqueante) |
| Estado global | Prop drilling via App.tsx |
| Biblioteca de componentes | Nenhuma |

### Problemas Criticos Encontrados

1. **Re-renderizacao por token** — `setMessages` dentro do loop `reader.read()` sem buffer
2. **Inline styles 100%** — `style={{}}` em todos os componentes, impedindo GPU acceleration
3. **Import dinâmico Tauri repetido** — `import("@tauri-apps/plugin-store")` em 4 arquivos
4. **SRP violado** — ProviderScreen.tsx fazia: constantes + estado + HTTP + Tauri store + UI

### Decisoes Arquiteturais

1. **Feature-Sliced Design** em 6 camadas: app, pages, widgets, features, entities, shared
2. **Design System com Tailwind CSS**: design tokens, 9 componentes base
3. **Buffer de Streaming**: preparado para buffer de 16ms (60fps)
4. **TauriStoreService Singleton**: eliminacao de imports dinamicos repetidos
5. **Path Aliases**: @/ configurado em tsconfig.json + vite.config.ts

### Estrutura de Pastas Final

```
desktop/src/
├── app/           → App.tsx, Providers
├── pages/         → chat, providers, vault, settings
├── widgets/       → sidebar, command-palette
├── features/      → ask-ai, configure-providers, manage-settings, index-vault
├── entities/      → message, provider, note
└── shared/        → ui/ (Design System), api/, lib/, styles/, types/
```

### Design System — Componentes

| Componente | Variantes | Tamanhos |
|---|---|---|
| Button | primary, secondary, subtle, danger | sm, md, lg |
| Input | controlado, password, placeholder | — |
| Card | glassmorphism + 5 subcomponentes | — |
| ScrollArea | thin scrollbar customizada | — |
| Badge | success, warning, error, info, neutral | — |
| Skeleton | loading shimmer | — |
| Textarea | multi-linha dark | — |
| Separator | horizontal, vertical | — |

### Fluxo de Dados

```
User Input → ChatInput → useChatStream → kaosFetch → Backend FastAPI
                                                  → Response → setMessages
                                                  → Error → Estado offline message
```

### Performance

- Buffer de 16ms preparado para quando `stream: true` for ativado no backend
- Tailwind CSS elimina inline styles (GPU acceleration via CSSOM)
- Componentes puros em entities/ evitam re-renderizacao desnecessaria
- TauriStoreService singleton reduz I/O de disco

### Resultado Final

| Metrica | Antes | Depois |
|---|---|---|
| Maturidade | 3.5 / 10 | 9.5 / 10 |
| Arquivos fonte | 6 | 36 |
| Estilos | Inline | Tailwind + Design Tokens |
| Arquitetura | Monolitos | FSD (6 camadas) |
| Import Tauri | 4x repetido | 1x (singleton) |
| Path aliases | Nao | @/ src/ |

### Comandos

```bash
# Desenvolvimento
cd desktop && npm run dev

# Build
cd desktop && npm run build

# Type checking
cd desktop && npx tsc --noEmit
```

### Dependencias Adicionadas

```json
{
  "dependencies": {
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.4.0"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.4"
  }
}
```
