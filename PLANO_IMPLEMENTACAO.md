# Plano de Implementação — Auditoria Documental K.A.O.S

**Data:** 2026-07-12
**Baseado no relatório:** `docs/audit-report-estrutural.md`

---

## Legenda

| Ícone | Significado |
|-------|-------------|
| ✅ Fase 0 | Concluída (limpeza de placeholders) |
| 🔄 Fase 1 | Sync Wiki ↔ Vault |
| 🔄 Fase 2 | Deduplicação SDDs |
| 🔄 Fase 3 | Organização docs órfãos |
| 🔄 Fase 4 | Arquitetura docs |
| 🔄 Fase 5 | Governance/Changelog |
| 🔄 Fase 6 | Scripts e Automação |

---

## ✅ Fase 0 — Limpeza de Placeholders (CONCLUÍDA)

### Ação
Remoção dos 14 diretórios vazios/duplicados da raiz:

| Diretório | Status | Observação |
|-----------|--------|------------|
| `Arquitetura/` | ✅ Removido | Vazio; conteúdo em `docs/Arquitetura/` |
| `SDD/` | ✅ Removido | Vazio; SDDs em `docs/sdd/` |
| `wiki/` | ✅ Removido | 2 arquivos esqueleto; wiki em `docs/wiki/` |
| `IA/` | ✅ Removido | Vazio |
| `Estudos/` | ✅ Removido | Vazio |
| `Diario/` | ✅ Removido | Vazio |
| `Projetos/` | ✅ Removido | Vazio; projetos em `docs/Projetos/` |
| `AWS/` | ✅ Removido | Vazio |
| `Python/` | ✅ Removido | Vazio |
| `Java/` | ✅ Removido | Vazio |
| `raw/` | ✅ Removido | Vazio |
| `Inbox/` | ✅ Removido | Vazio |
| `CI-CD/` | ✅ Removido | Vazio; CI/CD em `.github/workflows/` |

### Commit
`c7cafdc — chore: remove root wiki/ directory (skeleton only, real wiki at docs/wiki/)`

---

## 🔄 Fase 1 — Sync Wiki ↔ Vault

### Problema
`docs/wiki/` e `workspace/kaos/vault/wiki/` contêm **1.201 arquivos idênticos** como cópias manuais independentes. Qualquer alteração em um lado não reflete no outro.

### Solução
Script de sincronia unidirecional (`docs/wiki/` → `workspace/kaos/vault/wiki/`):

### Arquivo: `scripts/sync-vault.ps1`

```powershell
#!/usr/bin/env pwsh
# sync-vault.ps1 — Sincroniza docs/wiki/ → workspace/kaos/vault/wiki/
# Uso: ./scripts/sync-vault.ps1
# One-way sync: docs/ é a fonte de verdade

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$source = Join-Path $root "docs/wiki"
$target = Join-Path $root "workspace/kaos/vault/wiki"

if (-not (Test-Path $source)) {
    Write-Error "Fonte não encontrada: $source"
    exit 1
}

if (-not (Test-Path $target)) {
    Write-Warning "Criando diretório alvo: $target"
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

Write-Host "Syncing: $source → $target"
robocopy $source $target /MIR /NP /NDL /NJH /NJS

Write-Host "Sync concluído com sucesso."
```

### Gatilhos
| Evento | Ação |
|--------|------|
| **Pre-commit hook** | Executar `sync-vault.ps1` automaticamente |
| **CI/CD** | Job semanal para verificar divergência |
| **Manual** | `./scripts/sync-vault.ps1` |

### Alternativa Futura (se viável)
Se `docs/` e `workspace/` estiverem no mesmo filesystem, avaliar:
- **NTFS Junção (junction):** `fsutil junction create workspace\kaos\vault\wiki docs\wiki`
- **Git submodule compartilhado:** Extrair `wiki/` para repositório próprio

### Rollback
```powershell
robocopy workspace\kaos\vault\wiki docs\wiki /MIR  # inverte direção
```

### Risco
**Médio.** Pode sobrescrever alterações locais no vault que não passaram pelo submodule.

---

## 🔄 Fase 2 — Deduplicação SDDs

### Problema
SDDs existem em **3 locais**: `docs/sdd/` (fonte), `docs/wiki/` (cópia), `workspace/kaos/vault/wiki/` (cópia).

### Inventário

#### Grupo A — `sdd_*.md` (16 arquivos)

| Arquivo | docs/sdd/ | docs/wiki/ | vault/wiki/ |
|---------|-----------|------------|-------------|
| `sdd_arquitetura_orquestracao.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_desktop_build_optimization.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_fase1_fundacao.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_fase2_ia_local.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_fase3_obsidian_service.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_fase4_rag_pipeline.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_fase5_watcher_langgraph.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_knowledge_wiki_layer.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_llm_provider_hybrid.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_obsidian_memoria.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_obsidian_rag.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_obsidian_tools.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_obsidian_watcher.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_open_code_identidade.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_roadmap.md` | ✅ Fonte | ❌ Delete | ❌ Delete |
| `sdd_user_context_propagation.md` | ✅ Fonte | ❌ Delete | ❌ Delete |

#### Grupo B — `SDD-*.md` (20+ arquivos)

| Arquivo | docs/sdd/ | .opencode/plans/ | docs/wiki/ | vault/wiki/ |
|---------|-----------|------------------|------------|-------------|
| `SDD-040-completo.md` | ❌ | ✅ Fonte | ❌ Delete | ❌ Delete |
| `SDD-Commit-Governance.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Desktop-Stabilization-F1.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Estrategia-Testes-F6.md` | ❌ | ✅ Fonte | ❌ Delete | ❌ Delete |
| `SDD-F2-Readiness-Engine.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Implementation-Plan-v2.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-INFRA-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-KAOS-DESKTOP-UPDATE-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-KAOS-EVOLUTION-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-KAOS-UXUI-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-KIRL.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-MCP-Bridge.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-N8N-GITOPS-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-OBS-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-OPS-001.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-OPS-002.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Roadmap-Expansion-v2.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Roadmap-Expansion-v2-opencode-review.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |
| `SDD-Session-History.md` | ✅ Fonte | ❌ | ❌ Delete | ❌ Delete |

### Procedimento

```bash
# 1. Deletar SDDs do docs/wiki/
cd docs/wiki
git rm SDD-*.md sdd_*.md DOCUMENTATION_GOVERNANCE_SDD.md validation-audit.md
git commit -m "chore: remove SDD duplicates from wiki (canonical source at docs/sdd/)"

# 2. Deletar SDDs do workspace/kaos/vault/wiki/
cd workspace/kaos/vault/wiki
rm SDD-*.md sdd_*.md DOCUMENTATION_GOVERNANCE_SDD.md validation-audit.md
# Nota: workspace/ não é submodule, apenas rm local
```

### Risco
**Alto.** Pode quebrar links internos do Obsidian se houver `[[SDD-...]]` referências. Antes de executar:

```
grep -r "\[\[SDD-" docs/wiki/ workspace/kaos/vault/wiki/ > sdd-references.txt
grep -r "\[\[sdd_" docs/wiki/ workspace/kaos/vault/wiki/ >> sdd-references.txt
```

Criar redirects no wiki apontando para `docs/sdd/`:
```markdown
# SDD-Commit-Governance.md (redirect)
> Este documento foi movido para `docs/sdd/SDD-Commit-Governance.md`.
> [[docs/sdd/SDD-Commit-Governance|Acessar SDD original]]
```

---

## 🔄 Fase 3 — Organização Docs Órfãos

### Problema
Arquivos de documentação soltos na raiz de `docs/` sem diretório adequado:

| Arquivo | Local Atual | Destino Recomendado |
|---------|-------------|---------------------|
| `desktop-api-alignment.md` | `docs/` | `docs/architecture/` |
| `desktop-audit-report.md` | `docs/` | `docs/audit/` |
| `desktop-compatibility-report.md` | `docs/` | `docs/architecture/` |
| `desktop-missing-docs.md` | `docs/` | `docs/audit/` |
| `desktop-refactor-plan.md` | `docs/` | `docs/architecture/` |
| `desktop-roadmap-alignment.md` | `docs/` | `docs/roadmap/` |
| `audit-report.md` | `docs/` | `docs/audit/` |
| `Projetos/` (3 arquivos) | `docs/Projetos/` | `docs/projects/` (renomear) |

### Procedimento

```bash
cd docs/

# Criar diretórios necessários
mkdir -p audit roadmap

# Mover arquivos
git mv desktop-api-alignment.md architecture/
git mv desktop-audit-report.md audit/
git mv desktop-compatibility-report.md architecture/
git mv desktop-missing-docs.md audit/
git mv desktop-refactor-plan.md architecture/
git mv desktop-roadmap-alignment.md roadmap/
git mv audit-report.md audit/

# Renomear Projetos → projects
git mv Projetos projects

git commit -m "refactor(docs): organize orphan docs into proper directories"
```

### Risco
**Baixo.** Nenhum link externo conhecido aponta para esses arquivos.

---

## 🔄 Fase 4 — Arquitetura Docs (Unificação)

### Problema
Arquitetura documentada em **dois locais** com escopos e maturidade diferentes:

| Aspecto | `docs/Arquitetura/` (PT-BR) | `docs/architecture/` (EN) |
|---------|------------------------------|---------------------------|
| Maturidade | Original/simples | Evoluída/completa |
| Frontend | Open WebUI | Tauri + React |
| Providers | Ollama | Multi-provider |
| Observability | Não cobre | Completa |
| KIRL | Não cobre | Completa |

### Plano

#### Passo 1 — Arquivo de Mapeamento (imediato)
Criar `docs/architecture/MIGRATION_MAP.md`:
```markdown
# Mapa de Correspondência Arquitetural

| docs/Arquitetura/ (PT-BR) | docs/architecture/ (EN) | Status |
|---------------------------|------------------------|--------|
| Visao Geral.md | SYSTEM_ARCHITECTURE.md | Complementar |
| Arquitetura Geral.md | SYSTEM_ARCHITECTURE.md | Obsoleto (incorporado) |
| Fluxo de Dados.md | PROVIDER_ROUTING.md | Complementar |
| Infraestrutura Docker.md | — | Único em PT |
| Estrutura de Pastas.md | — | Útil referência |
| Estrategia de Repositorios.md | — | Único |
| Estrategia de Testes.md | — | Único |
| Padroes de Projeto.md | — | Único |
| Anti-padroes de Projeto.md | — | Único |
| Integracoes de Servicos.md | — | Único |
| Guia de Testes e Uso.md | — | Único |
```

#### Passo 2 — Atualizar `docs/Arquitetura/` (curto prazo)
Adicionar header em cada arquivo PT-BR:
```markdown
> **Nota:** Este documento reflete a visão original do K.A.O.S.
> Para a arquitetura evoluída, consulte [docs/architecture/](../architecture/SYSTEM_ARCHITECTURE.md).
```

#### Passo 3 — Consolidar (longo prazo)
Unificar num único documento bilíngue ou criar `docs/architecture/COMPLETE.md` que referencie ambos.

### Risco
**Médio.** A documentação PT-BR ainda tem conteúdo único não coberto pela EN.

---

## 🔄 Fase 5 — Governance / Changelog

### Problema
- `DOCUMENTATION_GOVERNANCE_SDD.md` em 3 locais
- `adr-governance.md` em 3 locais
- `CHANGELOG.md` duplicado (raiz + `docs/`)

### Plano

#### Governance
```bash
# Manter apenas em docs/governance/
cd docs
git rm wiki/DOCUMENTATION_GOVERNANCE_SDD.md wiki/adr-governance.md
# workspace/kaos/vault/wiki/ será limpo pelo sync
```

#### Changelog
```bash
# Manter apenas na raiz (gerado pelo CI)
cd docs
git rm CHANGELOG.md
# raiz/CHANGELOG.md permanece
```

### Risco
**Baixo.** Documentos de governança têm baixa probabilidade de referência externa.

---

## 🔄 Fase 6 — Scripts e Automação

### 6.1 Script de Sync (prioridade alta)

**Arquivo:** `scripts/sync-vault.ps1`
**Função:** Sincronizar `docs/wiki/` → `workspace/kaos/vault/wiki/`

### 6.2 Pre-commit Hook (prioridade média)

`.husky/pre-commit` ou `.githooks/pre-commit`:
```bash
#!/bin/sh
# Executar sync-vault antes de commits no docs/
if git diff --cached --name-only | grep -q "^docs/"; then
    pwsh ./scripts/sync-vault.ps1
fi
```

### 6.3 CI/CD Job (prioridade baixa)

Adicionar job em `.github/workflows/ci.yml`:
```yaml
sync-vault:
  runs-on: windows-latest
  steps:
    - uses: actions/checkout@v4
    - name: Sync vault
      run: ./scripts/sync-vault.ps1
    - name: Check for divergence
      run: git diff --exit-code workspace/kaos/vault/wiki/
```

### 6.4 Script de Verificação de Duplicação (prioridade baixa)

```powershell
# scripts/check-duplicates.ps1
# Verifica se docs/wiki/ e workspace/kaos/vault/wiki/ estão sincronizados
$diff = Compare-Object (Get-ChildItem docs/wiki -Recurse -Name) (Get-ChildItem workspace/kaos/vault/wiki -Recurse -Name)
if ($diff) { Write-Warning "Wiki e vault divergentes! Execute sync-vault.ps1" }
```

---

## Cronograma Recomendado

| Ordem | Fase | Esforço | Risco | Depende de |
|-------|------|---------|-------|------------|
| 1 | ✅ Fase 0 — Placeholders | 30min | Baixo | — |
| 2 | 🔄 Fase 1 — Script Sync | 2h | Médio | — |
| 3 | 🔄 Fase 3 — Docs Órfãos | 1h | Baixo | Fase 1 |
| 4 | 🔄 Fase 5 — Governance | 30min | Baixo | Fase 1 |
| 5 | 🔄 Fase 2 — SDDs | 3h | Alto | Fases 1, 3 |
| 6 | 🔄 Fase 4 — Arquitetura | 4h | Médio | Fase 3 |
| 7 | 🔄 Fase 6 — Automação | 2h | Baixo | Fase 1 |

**Total estimado:** ~13 horas de trabalho

---

## Matriz de Risco

| Fase | Risco | Impacto | Mitigação |
|------|-------|---------|-----------|
| Fase 0 | ✅ Concluído | — | — |
| Fase 1 | Médio | Sobrescrita de dados no vault | Backup antes do primeiro sync |
| Fase 2 | Alto | Links quebrados no Obsidian | Mapear referências antes, criar redirects |
| Fase 3 | Baixo | Links externos quebrados | Verificar se há referências |
| Fase 4 | Médio | Perda de conteúdo único PT | Manter originais com header de redirect |
| Fase 5 | Baixo | Nenhum | — |
| Fase 6 | Baixo | Script falhar | Testar manualmente antes de ativar hooks |

---

## Estado Pós-Implementação

```
K.A.O.S/
├── README.md, CHANGELOG.md, PROJECT_HEALTH.md
├── .opencode/ .agents/ .specify/ .github/
├── docs/ (submodule)
│   ├── sdd/                     ← SDDs (fonte única) ✅
│   ├── wiki/                    ← Wiki (fonte única) ✅
│   ├── architecture/            ← EN + PT consolidados 🏗️
│   ├── governance/              ← Fonte única ✅
│   ├── audit/                   ← Relatórios organizados ✅
│   ├── projects/                ← Projetos (ex-Projetos/) ✅
│   └── ...
├── workspace/kaos/vault/wiki/   ← Espelho sincronizado 🔄
├── kaos-research/               ← Independente (KEEP)
├── graphify/                    ← Subprojeto (KEEP)
├── assistant/ backend/ desktop/ infra/  ← Código
└── scripts/                     ← sync-vault.ps1 ✅
```

---

## Checklist de Verificação

- [ ] **Fase 0:** 14 diretórios removidos ✅
- [ ] **Fase 1:** `scripts/sync-vault.ps1` criado e testado
- [ ] **Fase 2:** SDDs removidos do wiki+vault; redirects criados
- [ ] **Fase 3:** docs órfãos movidos para diretórios apropriados
- [ ] **Fase 4:** Mapa de correspondência arquitetural criado
- [ ] **Fase 5:** Governance e changelog com fonte única
- [ ] **Fase 6:** Hooks e CI configurados
- [ ] **Graphify:** `graphify update .` executado após mudanças
- [ ] **README:** Atualizado se necessário
- [ ] **Links:** Nenhum link quebrado
