# Arquitetura Desktop — K.A.O.S

## Stack

| Camada | Tecnologia |
|--------|-----------|
| UI | React 18 + TypeScript |
| Bundler | Vite 5 |
| Desktop Shell | Tauri v2 (Rust) |
| Store Local | `tauri-plugin-store` |
| Updater | `tauri-plugin-updater` |
| HTTP Client | fetch nativo (ou axios) |
| CSS | CSS Modules / Tailwind |

## Comunicação

O desktop app comunica-se com o backend FastAPI via HTTP:

```
React (UI) → Tauri Commands → fetch → FastAPI (porta 8000)
```

Não há IPC direto com o backend. Toda comunicação passa por HTTP.

### ProviderStore (Tauri Plugin)

O `tauri-plugin-store` persiste configurações localmente em um arquivo JSON (ex: `~/.dev-k-a-o-s/settings.json` em dev).

Serve como cache offline e fallback caso o backend não esteja acessível.

## Estrutura de Diretórios

```
src/
├── src/
│   ├── components/
│   │   └── setup/
│   │       └── ProviderScreen.tsx   # Configuração de providers
│   ├── App.tsx
│   ├── main.tsx
│   └── styles/
├── src-tauri/
│   ├── src/
│   │   ├── main.rs                 # Entrypoint Tauri
│   │   ├── lib.rs                  # Plugins e setup
│   │   └── commands.rs             # Comandos Tauri (se houver)
│   ├── Cargo.toml
│   ├── tauri.conf.json             # Config do Tauri (updater, store, window)
│   ├── capabilities/
│   └── icons/
├── package.json
└── vite.config.ts
```

## Fluxo de Inicialização

1. Tauri inicia e carrega o frontend React
2. React monta `App.tsx` que verifica estado de setup
3. Se provider não configurado, mostra `ProviderScreen`
4. Usuário preenche e salva → POST para backend + persiste local com plugin-store
5. App entra em modo de chat normal

## Auto-Update

O `tauri-plugin-updater` verifica novas versões no GitHub Releases.

Configurado em `tauri.conf.json`:

```json
{
  "plugins": {
    "updater": {
      "pubkey": "...",
      "endpoints": ["https://releases.react-etc.repl.co/latest"],
      "windows": { "installMode": "passive" }
    }
  }
}
```

Gatilho: qualquer tag `v*` no GitHub gera release com asset assinado via Cosign.

## Segurança

- Tauri v2 usa `capabilities` para controlar permissões de IPC
- O plugin-store só é acessível via comandos Tauri explicitamente expostos
- Assets de release são assinados com Cosign keyless antes do upload
