# SDD-KAOS-DESKTOP-UPDATE-001
## Sistema de Atualização Automática — K.A.O.S Desktop

---

| Campo | Valor |
|---|---|
| **ID** | SDD-KAOS-DESKTOP-UPDATE-001 |
| **Status** | 🟢 GO — Aprovado |
| **Versão** | 3.0 (Final) |
| **Prioridade** | Média-Alta |
| **Autor** | Brian5m1th |
| **Data** | 2026-06-23 |
| **Stack** | Tauri 2 + tauri-plugin-updater + GitHub Releases |
| **Risco** | Baixo |
| **Complexidade** | Baixa |
| **Posição no Roadmap** | Após Fase 1 (Documentação), antes do AI Vault Analyzer |

---

## 1. Problema

A distribuição de novas versões do K.A.O.S Desktop exige reinstalação manual pelo usuário:

- Usuário depende de acompanhar manualmente o GitHub Releases.
- Alto risco de operação em versões desatualizadas.
- Processo de atualização não é transparente.
- Custo elevado de suporte.

---

## 2. Decisões de Arquitetura

### DEC-001 — Desacoplamento do Sistema de Providers

> O sistema de atualização deve permanecer **completamente desacoplado** do sistema de providers, model routing e OpenCode Layer.
>
> Atualizações do desktop **não dependem** de OpenAI, Anthropic, Ollama ou qualquer provider externo.
>
> **Motivo**: Evitar acoplamentos futuros que impeçam atualizações quando um provider estiver offline.

### DEC-002 — Separação de Responsabilidades (Service/Store/UI)

```
Store   = estado puro (o que o usuário vê)
Service = regras de negócio (quando e como verificar)
UI      = apresentação (o que renderizar para cada fase)
```

A lógica de `invoke`, cooldown e `listen` reside no `UpdaterService`, não na Store.

### DEC-003 — UpdateScheduler como Intermediário

O `useAppInit` não chama o updater diretamente. Um `UpdateScheduler` centraliza a decisão de quando verificar:

```
useAppInit()
     ↓
UpdateScheduler.schedule()
     ↓
Cooldown Check (lastCheckAt < 6h?)
     ↓
UpdaterService.checkForUpdates()
     ↓
UpdateStore.setState(...)
```

### DEC-004 — Single Source of Truth para Versão

`package.json.version` é a única fonte de verdade. `Cargo.toml`, `tauri.conf.json` e `update-proxy.json` são derivados e gerados automaticamente no CI.

---

## 3. Contexto Técnico Atual

> **IMPORTANTE**: O projeto usa **Tauri 2** (não Electron). O `tauri-plugin-updater` já está instalado e parcialmente configurado.

### Estado da Base de Código

| Componente | Estado |
|---|---|
| `tauri-plugin-updater = "2"` em `Cargo.toml` | ✅ Instalado |
| `@tauri-apps/plugin-updater: "^2.0.0"` em `package.json` | ✅ Instalado |
| `tauri_plugin_updater::Builder::new().build()` em `lib.rs` | ✅ Registrado |
| `plugins.updater` em `tauri.conf.json` com pubkey + endpoint | ✅ Configurado |
| `update-proxy.json` — apenas `windows-x86_64`, sem `version`/`pub_date` | ⚠️ Incompleto |
| `release.yml` com build multi-plataforma | ✅ Existente |
| `TAURI_SIGNING_PRIVATE_KEY` secret | ✅ Configurado |
| **Comando Tauri `check_for_update`** | ❌ Faltando |
| **`UpdaterService`** | ❌ Faltando |
| **`UpdateStore`** | ❌ Faltando |
| **`UpdateScheduler`** | ❌ Faltando |
| **`UpdateCard` (UI)** | ❌ Faltando |
| **Badge na TopBar** | ❌ Faltando |
| **Geração automática de `update-proxy.json` no CI** | ❌ Faltando |

---

## 4. Objetivos

### Funcionais

| ID | Requisito |
|---|---|
| F-01 | Verificar atualizações silenciosamente no startup via `UpdateScheduler`. |
| F-02 | Respeitar cooldown de 6 horas — não verificar a cada abertura do app. |
| F-03 | Permitir verificação manual em `Configurações > Atualizações`. |
| F-04 | Exibir badge discreto na TopBar quando update disponível. |
| F-05 | Exibir progresso de download em tempo real (%). |
| F-06 | Instalar e reiniciar a partir da UI com um clique. |
| F-07 | Exibir release notes (`body`) da versão disponível. |
| F-08 | Exibir mensagem "Você está na versão mais recente" quando não há update. |

### Não Funcionais

| ID | Requisito |
|---|---|
| NF-01 | Funcionar em Windows, Linux e macOS (schema pronto; binários gradualmente). |
| NF-02 | Sem servidor de atualização próprio (100% GitHub Releases). |
| NF-03 | Verificação de integridade via assinatura Minisign. |
| NF-04 | Verificação e download em background — não bloquear a UI. |
| NF-05 | Cooldown de 6 horas persistido para sobreviver reinicializações. |
| NF-06 | `update-proxy.json` deve ser gerado automaticamente pelo `release.yml` a partir de `package.json.version`. |

---

## 5. Arquitetura

### 5.1 Estrutura de Camadas

```
┌─────────────────────────────────────────────────────┐
│                   Renderer Process                   │
│                                                     │
│  useAppInit → UpdateScheduler → UpdaterService      │
│                                        │            │
│                               UpdateStore (Zustand) │
│                                        │            │
│                    UpdateCard / TopBar Badge        │
└────────────────────────┬────────────────────────────┘
                         │ invoke / emit (IPC)
┌────────────────────────▼────────────────────────────┐
│                    Main Process (Rust)               │
│                                                     │
│           updater.rs (check / download)             │
│                      │                              │
│           tauri-plugin-updater                      │
│                      │                              │
│           GitHub Releases / update-proxy.json       │
└─────────────────────────────────────────────────────┘
```

### 5.2 Fluxo de Verificação no Startup

```
App abre
    │
    ▼
useAppInit()
    │
    ▼
UpdateScheduler.schedule()
    │
    ├── lastCheckAt existe E (now - lastCheckAt) < 6h?
    │       └── Sim → RETORNA (sem chamada ao GitHub)
    │
    └── Não → UpdaterService.checkForUpdates()
                    │
                    ▼
              invoke("check_for_update")  [Rust]
                    │
                    ├── available = true
                    │       ├── UpdateStore.set({ phase: "available", update })
                    │       ├── TopBar badge verde
                    │       └── Toast discreto: "v{X.Y.Z} disponível"
                    │
                    └── available = false
                            └── UpdateStore.set({ phase: "not-available" })
                                UpdateStore.set({ lastCheckAt: now })
```

### 5.3 Fluxo de Download e Instalação

```
Usuário clica "Baixar Atualização"
    │
    ▼
UpdaterService.downloadUpdate()
    │
    ▼
invoke("download_and_install")  [Rust]
    │
    ├── listen("update:progress") → UpdateStore.setProgress(%)
    ├── listen("update:ready")    → UpdateStore.set({ phase: "ready" })
    └── listen("update:error")    → UpdateStore.set({ phase: "error" })

Usuário clica "Reiniciar e Instalar"
    │
    ▼
UpdaterService.installUpdate()
    │
    ▼
invoke("install_update")  → relaunch()
```

---

## 6. Contratos de Interface

### 6.1 UpdateStore — Estado Puro

```typescript
type UpdatePhase =
  | "idle"
  | "checking"
  | "available"
  | "not-available"
  | "downloading"
  | "ready"
  | "error";

type UpdateChannel = "stable" | "beta" | "nightly"; // apenas "stable" na Fase 1

interface UpdateInfo {
  version: string;
  date: string;
  body: string;  // release notes em Markdown
}

interface UpdateMetadata {
  lastCheckAt?: string;  // ISO 8601 — controla o cooldown
}

interface UpdateState {
  // Estado
  phase: UpdatePhase;
  channel: UpdateChannel;
  currentVersion: string;   // de __APP_VERSION__ (injetado pelo Vite)
  update: UpdateInfo | null;
  progress: number;         // 0–100
  lastCheckAt: string | null;
  error: string | null;

  // Mutações (chamadas apenas pelo UpdaterService)
  setPhase: (phase: UpdatePhase) => void;
  setUpdate: (update: UpdateInfo | null) => void;
  setProgress: (progress: number) => void;
  setLastCheckAt: (date: string) => void;
  setError: (error: string | null) => void;
  setChannel: (channel: UpdateChannel) => void;
}

// Persistido: lastCheckAt + channel
```

### 6.2 UpdaterService — Regras de Negócio

```typescript
// features/auto-update/services/updater-service.ts
export class UpdaterService {
  static async checkForUpdates(): Promise<void>
  // invoke("check_for_update") → lê resultado → atualiza UpdateStore

  static async downloadUpdate(): Promise<void>
  // invoke("download_and_install") + listen eventos de progresso

  static async installUpdate(): Promise<void>
  // invoke("install_update") → relaunch
}
```

### 6.3 UpdateScheduler

```typescript
// features/auto-update/services/update-scheduler.ts
const COOLDOWN_MS = 6 * 60 * 60 * 1000; // 6 horas

export class UpdateScheduler {
  static schedule(): void {
    const { lastCheckAt } = useUpdateStore.getState();
    if (lastCheckAt) {
      const elapsed = Date.now() - new Date(lastCheckAt).getTime();
      if (elapsed < COOLDOWN_MS) return;
    }
    void UpdaterService.checkForUpdates();
  }
}
```

### 6.4 Comandos Rust (updater.rs)

```rust
#[derive(Serialize)]
pub struct UpdateResult {
    pub available: bool,
    pub version: Option<String>,
    pub date: Option<String>,
    pub body: Option<String>,   // release notes
}

#[derive(Serialize, Clone)]
struct ProgressPayload {
    downloaded: u64,
    total: Option<u64>,
}

#[tauri::command]
pub async fn check_for_update(app: AppHandle) -> Result<UpdateResult, String>

#[tauri::command]
pub async fn download_and_install(app: AppHandle) -> Result<(), String>
// Emite via app.emit():
//   "update:progress" → ProgressPayload
//   "update:ready"    → ()
//   "update:error"    → { message: String }

#[tauri::command]
pub async fn install_update(app: AppHandle) -> Result<(), String>
// Chama app.restart()
```

---

## 7. update-proxy.json — Schema Formal (NF-06)

Schema multiplataforma completo desde a Fase 1, mesmo que inicialmente apenas `windows-x86_64` tenha URL preenchida:

```json
{
  "version": "0.5.0",
  "pub_date": "2026-06-23T00:00:00Z",
  "notes": "Release notes da versão em texto livre",
  "platforms": {
    "windows-x86_64": {
      "url": "https://github.com/Brian5m1th/K.A.O.S/releases/download/v0.5.0/KAOS_0.5.0_x64.msi",
      "signature": "<minisign_assinatura_do_msi>"
    },
    "linux-x86_64": {
      "url": "",
      "signature": ""
    },
    "darwin-aarch64": {
      "url": "",
      "signature": ""
    }
  }
}
```

**Geração automática** via `scripts/gen_update_proxy.py` executado no `release.yml`:
- Lê versão de `package.json.version`
- Lê assinaturas dos arquivos `.sig` gerados pelo Tauri Builder
- Gera `update-proxy.json` e publica como asset da release

---

## 8. Estrutura de Arquivos

```
desktop/
├── src-tauri/
│   └── src/
│       ├── lib.rs                           (MODIFICAR — registrar novos comandos)
│       └── updater.rs                       (NOVO — check_for_update, download_and_install, install_update)
│
└── src/
    ├── shared/
    │   ├── lib/
    │   │   ├── use-init.ts                  (MODIFICAR — chamar UpdateScheduler.schedule())
    │   │   └── stores/
    │   │       ├── index.ts                 (MODIFICAR — exportar useUpdateStore)
    │   │       └── update-store.ts          (NOVO — estado puro + persist lastCheckAt)
    │   └── ui/
    │       └── toast.tsx                    (verificar se existe — usar para notificação)
    │
    ├── features/
    │   └── auto-update/
    │       ├── services/
    │       │   ├── updater-service.ts       (NOVO — lógica invoke/listen)
    │       │   └── update-scheduler.ts      (NOVO — cooldown + dispatch)
    │       ├── hooks/
    │       │   └── useUpdateCheck.ts        (NOVO — bridge useAppInit → UpdateScheduler)
    │       └── ui/
    │           └── UpdateCard.tsx           (NOVO — UI por fase)
    │
    ├── widgets/
    │   └── topbar/                          (MODIFICAR — badge quando phase="available")
    │
    └── pages/
        └── settings/
            └── index.tsx                    (MODIFICAR — aba "Atualizações" + UpdateCard)

.github/workflows/
    └── release.yml                          (MODIFICAR — step de geração do update-proxy.json)

scripts/
    └── gen_update_proxy.py                  (NOVO — gerador Python do update-proxy.json)

desktop/src-tauri/
    └── update-proxy.json                    (MODIFICAR — schema multiplataforma)
```

---

## 9. UI — UpdateCard por Fase

| `phase` | Conteúdo Exibido |
|---|---|
| `idle` / `not-available` | Versão atual + botão "Verificar Atualizações" |
| `checking` | Spinner + "Verificando..." |
| `available` | Badge verde + versão nova + **release notes** + "Baixar Atualização" |
| `downloading` | Barra de progresso animada com % |
| `ready` | Release notes + botão pulsante "Reiniciar e Instalar" |
| `error` | Mensagem de erro + "Tentar Novamente" |

### Exemplo — fase `available`

```
┌─────────────────────────────────────────┐
│  ↑ Versão 0.9.0 Disponível              │
│                                         │
│  Novidades:                             │
│  • AI Vault Analyzer                    │
│  • Melhorias no KIRL parsing            │
│  • Correções de bugs                    │
│                                         │
│  [ Baixar Atualização ]                 │
└─────────────────────────────────────────┘
```

---

## 10. Observabilidade

Eventos estruturados preparados para integração futura com o módulo de observabilidade do K.A.O.S (sem necessidade de refatoração):

| Evento | Quando | Payload |
|---|---|---|
| `event.desktop.update.check` | Verificação iniciada | `{ channel, forced }` |
| `event.desktop.update.available` | Update encontrado | `{ version, date }` |
| `event.desktop.update.skipped` | Cooldown ativo | `{ lastCheckAt, remaining_ms }` |
| `event.desktop.update.download.start` | Download iniciado | `{ version }` |
| `event.desktop.update.download.complete` | Download concluído | `{ version, bytes }` |
| `event.desktop.update.install` | Instalação/relaunch | `{ version }` |
| `event.desktop.update.error` | Erro em qualquer fase | `{ phase, message }` |

> Na Fase 1 esses eventos são apenas `console.debug`. Na Fase 2 alimentam dashboards.

---

## 11. Segurança

| Aspecto | Mecanismo |
|---|---|
| Integridade do binário | Assinatura Minisign via `TAURI_SIGNING_PRIVATE_KEY` |
| Verificação antes de instalar | `tauri-plugin-updater` verifica assinatura automaticamente |
| Canal de distribuição | HTTPS obrigatório (GitHub Releases) |
| Fonte única | Somente `Brian5m1th/K.A.O.S` via `tauri.conf.json` |
| Desacoplamento de providers | Ver DEC-001 |

---

## 12. Critérios de Aceitação

| ID | Cenário | Resultado Esperado |
|---|---|---|
| CA-001 | App inicia com nova release no GitHub | Badge na TopBar + toast discreto |
| CA-002 | App inicia dentro do cooldown de 6h | Nenhuma chamada ao GitHub |
| CA-003 | `Configurações > Atualizações` | Versão atual + status corretos |
| CA-004 | Clica "Verificar Atualizações" | Estado "verificando" → resultado exibido |
| CA-005 | Update disponível | Release notes visíveis na UI |
| CA-006 | Clica "Baixar" | Barra de progresso com % real |
| CA-007 | Download concluído | Botão "Reiniciar e Instalar" habilitado |
| CA-008 | Clica "Reiniciar e Instalar" | App reinicia e aplica nova versão |
| CA-009 | Nenhuma atualização disponível | "Você está na versão mais recente" |
| CA-010 | Erro de rede | Mensagem amigável; app continua funcionando |
| CA-011 | Nova tag publicada no GitHub | `update-proxy.json` gerado automaticamente com versão correta |

---

## 13. Fora de Escopo (Fase 1)

- Canal beta / nightly
- Download automático silencioso sem interação do usuário
- Rollback automático
- Code Signing pago (Windows SmartScreen) / Notarização macOS
- Servidor de updates próprio
- Integração de observabilidade (Fase 2)

---

## 14. Roadmap

| Fase | Funcionalidades |
|---|---|
| **Fase 1 — MVP** (Este SDD) | Rust commands, UpdaterService, UpdateScheduler, UpdateStore, UpdateCard, badge TopBar, release notes, CI automático |
| **Fase 2** | Canal beta, download automático silencioso, eventos de observabilidade para dashboards, notificação do SO |
| **Fase 3** | Canal nightly, delta updates, rollback, Code Signing |
