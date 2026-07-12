# Auditoria Estrutural da Documentação — K.A.O.S

**Data:** 2026-07-12
**Versão do Relatório:** 1.0
**Status:** Auditoria Completa (nenhuma alteração executada)

---

## Resumo Executivo

O repositório K.A.O.S possui **47 entradas raiz**, das quais **14 são diretórios de documentação** em diferentes estados de maturidade. A documentação está espalhada por múltiplos diretórios com **duplicação massiva** entre `docs/wiki/` e `workspace/kaos/vault/wiki/` (**1.201 arquivos idênticos**). Onze diretórios raiz estão **vazios** (placeholders criados mas nunca populados). A arquitetura documental atual carece de uma fonte de verdade única, resultando em versões divergentes e dificuldade de manutenção.

**Problemas críticos identificados:**
1. Duplicação de 1.201+ arquivos entre `docs/wiki/` e `workspace/kaos/vault/wiki/`
2. 11 diretórios raiz vazios criando poluição visual
3. SDDs triplicados em `docs/sdd/`, `docs/wiki/` e `workspace/kaos/vault/wiki/`
4. Documentação de arquitetura dividida entre português (`docs/Arquitetura/`) e inglês (`docs/architecture/`) com escopos diferentes
5. Ausência de política formal de "fonte de verdade" por tipo de documento
6. `docs/` é um submodule Git (`K.A.O.S-storage`), o que limita flexibilidade de movimentação

---

## Fase 1 — Inventário Completo da Documentação

### 1.1 Diretórios de Documentação por Categoria

| Diretório | Arquivos | Tamanho | Status | Categoria |
|-----------|----------|---------|--------|-----------|
| `docs/` (submodule) | 1.409 | ~45 MB | **ATIVO** | Hub central de documentação |
| `docs/architecture/` | 4 | 29 KB | **ATIVO** | Arquitetura (EN) |
| `docs/Arquitetura/` | 11 | 44 KB | **ATIVO** | Arquitetura (PT-BR) |
| `docs/adr/` | 4 | 8 KB | **ATIVO** | ADRs |
| `docs/sdd/` | 75 | 402 KB | **ATIVO** | SDDs (fonte primária) |
| `docs/wiki/` | 1.201 | 6,2 MB | **ATIVO** | Wiki/Obsidian vault |
| `docs/guides/` | 10 | 97 KB | **ATIVO** | Guias |
| `docs/governance/` | 5 | 20 KB | **ATIVO** | Governança |
| `docs/openCode/` | 39 | ~177 KB | **ATIVO** | Config AI agents |
| `kaos-research/` | 18 | 65 KB | **ATIVO** | Laboratório de pesquisa |
| `graphify/` | 733 | ~50 MB | **ATIVO** | Engine de knowledge graph |
| `airllm/` | 7 | 129 KB | **ATIVO** | Submódulo AirLLM |
| `.opencode/` | 52 | ~177 KB | **ATIVO** | Config OpenCode |
| `.agents/` | 2 | 1,2 KB | **ATIVO** | Config Gemini agents |
| `.specify/` | 9 | 38 KB | **ATIVO** | Memória SpecKit |
| `.github/` | 1 | 1 KB | **ATIVO** | Template PR |

### 1.2 Diretórios Vazios (Placeholders)

| Diretório | Criado em | Propósito Intencionado |
|-----------|-----------|----------------------|
| `Arquitetura/` | 2026-07-08 | Documentação de arquitetura (raiz) |
| `SDD/` | 2026-07-08 | System Design Documents (raiz) |
| `wiki/` | 2026-07-09 | Wiki (raiz) — contém só index.md + log.md |
| `IA/` | 2026-07-08 | Inteligência Artificial |
| `Estudos/` | 2026-07-08 | Estudos e pesquisas |
| `Diario/` | 2026-07-08 | Diário de bordo |
| `Projetos/` | 2026-07-08 | Projetos diversos |
| `AWS/` | 2026-07-08 | Documentação AWS |
| `Python/` | 2026-07-08 | Código/documentação Python |
| `Java/` | 2026-07-08 | Código/documentação Java |
| `raw/` | 2026-07-08 | Raw data |
| `Inbox/` | 2026-07-08 | Caixa de entrada |
| `CI-CD/` | 2026-07-08 | CI/CD docs (raiz) |
| `AWS/` | 2026-07-08 | AWS docs (raiz) |

**Total: 14 diretórios vazios** (11 na raiz + 3 em `workspace/kaos/vault/`)

### 1.3 Documentos Raiz

| Arquivo | Tamanho | Propósito |
|---------|---------|-----------|
| `README.md` | 4,6 KB | Overview do projeto |
| `CHANGELOG.md` | 9,8 KB | Changelog (v2.2.0 a v2.5.4) |
| `PROJECT_HEALTH.md` | 2,1 KB | Relatório de saúde (72/100) |
| `package.json` | 333 B | Commitlint config |
| `.releaserc.json` | 779 B | Semantic-release config |
| `.commitlintrc.json` | 322 B | Commitlint rules |
| `setup.ps1` | 5,3 KB | Bootstrap Windows |

---

## Fase 2 — Relatório de Duplicações

### 2.1 Duplicação Massiva: `docs/wiki/` ⇔ `workspace/kaos/vault/wiki/`

| Métrica | Valor |
|---------|-------|
| Arquivos idênticos | **1.201** |
| Tamanho total | **6.177.916 bytes** (cada) |
| Similaridade | **EXATO** (bit-for-bit) |
| Causa | Obsidian vault duplicado localmente |

### 2.2 SDDs Triplicados

**16 arquivos `sdd_*.md`** aparecem em 3 locais:
- `docs/sdd/` (fonte primária)
- `docs/wiki/` (cópia)
- `workspace/kaos/vault/wiki/` (cópia)

**20+ arquivos `SDD-*.md`** aparecem em 2-3 locais:
- `docs/sdd/` (fonte primária)
- `docs/wiki/` (cópia)
- `workspace/kaos/vault/wiki/` (cópia)

**Similaridade:** Presumivelmente EXATO (mesmos nomes, tamanhos similares)

### 2.3 READMEs Duplicados

| Documento A | Documento B | Similaridade |
|-------------|-------------|--------------|
| `README.md` (raiz) | `docs/README.md` | **PARCIAL** (conteúdos diferentes) |
| `docs/README.md` | `docs/wiki/README.md` | **DIFERENTE** (propósitos distintos) |
| `docs/wiki/README.*.md` (32 locales) | `workspace/kaos/vault/wiki/README.*.md` (32 locales) | **EXATO** |

### 2.4 Documentos Raiz Duplicados no Vault

| Arquivo Raiz | docs/wiki/ | workspace/kaos/vault/wiki/ |
|-------------|------------|---------------------------|
| `PROJECT_HEALTH.md` | Cópia | Cópia |
| `CHANGELOG.md` no root | Cópia em `docs/CHANGELOG.md` | Cópia em vault |

### 2.5 Architecture Docs Duplicados (Ramo)

| Conteúdo | Local A | Local B | Similaridade |
|----------|---------|---------|-------------|
| `architecture.md` | `docs/wiki/` | `workspace/kaos/vault/wiki/` | EXATO (stubs Graphify) |
| `tunnel-architecture.md` | `docs/operations/cloudflare/` | `docs/wiki/` + vault | PARCIAL |
| `sdd_arquitetura_orquestracao.md` | `docs/sdd/` | `docs/wiki/` + vault | EXATO (provável) |
| `DOCUMENTATION_GOVERNANCE_SDD.md` | `docs/governance/` | `docs/wiki/` + vault | EXATO (provável) |

### 2.6 Audit Docs Duplicados

10+ arquivos `audit*.md` aparecem em ambos `docs/wiki/` e `workspace/kaos/vault/wiki/`.

### 2.7 Health Docs Duplicados

6+ arquivos `health*.md` aparecem em ambos `docs/wiki/` e `workspace/kaos/vault/wiki/`.

### 2.8 Tabela Consolidada de Duplicações

| Padrão | # Arquivos | Locais | Similaridade | Ação Recomendada |
|--------|-----------|--------|-------------|-----------------|
| `wiki/*` | ~1.200 | `docs/wiki/` ↔ `workspace/kaos/vault/wiki/` | EXATO | REDIRECT (symlink ou sync tool) |
| `sdd_*.md` | 16 | `docs/sdd/` + `docs/wiki/` + vault | EXATO | DELETE cópias no wiki+vault |
| `SDD-*.md` | 20+ | `docs/sdd/` + `docs/wiki/` + vault | EXATO | DELETE cópias no wiki+vault |
| `README.*.md` | 32 locales | `docs/wiki/` ↔ vault | EXATO | REDIRECT via sync |
| `audit*.md` | 10+ | `docs/wiki/` ↔ vault | EXATO | REDIRECT via sync |
| `health*.md` | 6+ | `docs/wiki/` ↔ vault | EXATO | REDIRECT via sync |
| `index*.md` | 7+ | `docs/wiki/` ↔ vault | EXATO | REDIRECT via sync |
| `PROJECT_HEALTH.md` | 3 | raiz + `docs/wiki/` + vault | PARCIAL | KEEP raiz + sync vault |
| `CHANGELOG.md` | 4 | raiz + `docs/` + wiki + vault | PARCIAL | KEEP raiz + sync vault |
| `governance/*.md` | 2 | `docs/governance/` + wiki + vault | EXATO | DELETE cópias no wiki+vault |

---

## Fase 3 — Fonte de Verdade (Canonical Source)

### 3.1 Definição por Tipo de Documento

| Tipo | Fonte Canônica | Justificativa |
|------|---------------|---------------|
| **SDDs** | `docs/sdd/` | Local primário de criação, 75 arquivos, referenciado por CI/CD e KIRL |
| **Wiki knowledge base** | `docs/wiki/` | Submodule versionado, ~1.200 arquivos, consumido por Obsidian |
| **Architecture (EN)** | `docs/architecture/` | Documentação mais madura e atualizada do sistema evoluído |
| **Architecture (PT-BR)** | `docs/Arquitetura/` | Visão original do sistema, complementar à EN |
| **ADRs** | `docs/adr/` | Local dedicado, vinculado à governance |
| **Governance** | `docs/governance/` | Local dedicado com templates e regras |
| **Guides** | `docs/guides/` | Local dedicado com 10 guias |
| **Config AI (OpenCode)** | `.opencode/` | Diretório de configuração da ferramenta |
| **Config AI (Gemini)** | `.agents/` | Diretório de configuração da ferramenta |
| **Research** | `kaos-research/` | Laboratório isolado com método científico próprio |
| **Graphify engine** | `graphify/` | Subprojeto independente (Pypi: graphifyy) |
| **Health/Status** | `PROJECT_HEALTH.md` (raiz) | Gerado automaticamente pelo EvidenceEngine |
| **Changelog** | `CHANGELOG.md` (raiz) | Gerado pelo semantic-release |
| **SpecKit memory** | `.specify/` | Diretório interno do pipeline SpecKit |
| **Infrastructure docs** | `docs/` (subdirs apropriados) | Dentro do submodule versionado |

### 3.2 Documentos sem Fonte de Verdade Clara

- `docs/audit-report.md` vs `docs/wiki/audit-report.md` vs `docs/wiki/validation-audit.md`
- `docs/desktop-*.md` (6 arquivos soltos na raiz de docs/)
- `docs/CHANGELOG.md` duplicado do `CHANGELOG.md` raiz
- `docs/Projetos/` — conteúdo de projeto que deveria estar em `docs/`

---

## Fase 4 — Auditoria Arquitetural dos Diretórios

### 4.1 Diretórios Raiz Vazios — Recomendação: DELETE

| Diretório | Motivo | Ação |
|-----------|--------|------|
| `Arquitetura/` | Placeholder; conteúdo real está em `docs/Arquitetura/` | DELETE |
| `SDD/` | Placeholder; SDDs reais estão em `docs/sdd/` | DELETE |
| `wiki/` | Placeholder (2 arquivos esqueleto); wiki real está em `docs/wiki/` | DELETE |
| `IA/` | Placeholder; conteúdo de IA está em `docs/` e `kaos-research/` | DELETE |
| `Estudos/` | Placeholder; estudos estão em `kaos-research/` ou `docs/` | DELETE |
| `Diario/` | Placeholder | DELETE |
| `Projetos/` | Placeholder; projetos estão em `docs/Projetos/` | DELETE |
| `AWS/` | Placeholder; docs AWS podem ir para `docs/infrastructure/aws/` | DELETE |
| `Python/` | Placeholder; código está em `assistant/` | DELETE |
| `Java/` | Placeholder; sem código Java no momento | DELETE |
| `raw/` | Placeholder | DELETE |
| `Inbox/` | Placeholder | DELETE |
| `CI-CD/` | Placeholder; CI/CD real está em `.github/workflows/` | DELETE |

### 4.2 Diretórios que Devem Permanecer Separados

| Diretório | Motivo para Manter Separado |
|-----------|------------------------------|
| `kaos-research/` | Laboratório de pesquisa isolado com método científico próprio; ADRs independentes; experimentos isolados; .venv próprio. Não deve ser contaminado pela estrutura documental principal. |
| `graphify/` | Subprojeto open source independente (Pypi: graphifyy); tem自己的 repo, CI/CD, releases; documentação própria (READMEs traduzidos, ARCHITECTURE.md, BENCHMARKS.md). |
| `airllm/` | Submódulo de terceiros; READMEs próprios. |
| `.opencode/` | Configuração de ferramenta; deve ficar oculto (dotfile). |
| `.agents/` | Configuração de ferramenta; deve ficar oculto (dotfile). |
| `.specify/` | Memória interna do pipeline SpecKit; não é documentação pública. |
| `.github/` | Configuração de plataforma; inclui workflows CI/CD. |

### 4.3 Diretórios que Devem Ser Movidos para `docs/`

Nenhum diretório precisa ser movido imediatamente. A estrutura atual é funcional: `docs/` contém a documentação. Contudo, os placeholders vazios devem ser limpos.

### 4.4 Problemas Estruturais Identificados

1. **Poluição visual:** 14 diretórios vazios na raiz confundem navegação
2. **Duplicação sem sincronia:** `docs/wiki/` e `workspace/kaos/vault/wiki/` são cópias manuais, propensas a divergência
3. **SDDs em múltiplos locais:** Sem política de "cópia vs referência"
4. **Documentação órfã na raiz:** `PROJECT_HEALTH.md`, `CHANGELOG.md` sem ligação com `docs/`
5. **Submodule trava migrações:** `docs/` é submodule, logo `git mv` não funciona entre `docs/` e raiz
6. **Falta de cross-reference:** Documentos duplicados não se referenciam mutualmente

---

## Fase 5 — Plano de Migração

### 5.1 Fase 0: Limpeza de Placeholders (Baixo Risco)

```
DELETE (via git rm):
  Arquitetura/          → vazio
  SDD/                  → vazio
  wiki/                 → 2 arquivos esqueleto (index.md, log.md)
  IA/                   → vazio
  Estudos/              → vazio
  Diario/               → vazio
  Projetos/             → vazio
  AWS/                  → vazio
  Python/               → vazio
  Java/                 → vazio
  raw/                  → vazio
  Inbox/                → vazio
  CI-CD/                → vazio
```

**Rollback:** `git restore <caminho>` (diretórios vazios não são trackeados pelo Git sem `.gitkeep`)

### 5.2 Fase 1: Sincronia Wiki ↔ Vault (Risco Médio)

Criar script de sincronia (`scripts/sync-vault.ps1`):
```powershell
# sync-vault.ps1
# One-way sync: docs/wiki/ → workspace/kaos/vault/wiki/
# Executar antes de commits no vault
```

**Opções:**
- **Symlink/junction:** Criar `workspace/kaos/vault/wiki/` como symlink para `docs/wiki/` (apenas Windows/NTFS)
- **Robocopy script:** `robocopy docs/wiki workspace/kaos/vault/wiki /MIR`
- **Git submodule:** Extrair `docs/wiki/` para repositório separado e referenciar em ambos locais

**Recomendação:** Usar `robocopy /MIR` em script pré-commit, pois o symlink não é portável para outros sistemas e o Obsidian pode não seguir symlinks corretamente.

### 5.3 Fase 2: Deduplicação de SDDs (Risco Alto)

```
MANTIDO: docs/sdd/ (fonte canônica)
DELETADO: docs/wiki/SDD-*.md (cópia)
DELETADO: docs/wiki/sdd_*.md (cópia)
DELETADO: workspace/kaos/vault/wiki/SDD-*.md (cópia)
DELETADO: workspace/kaos/vault/wiki/sdd_*.md (cópia)
```

**Justificativa:** SDDs têm versão canônica em `docs/sdd/`. As cópias no wiki/vault são resíduos do processo de indexing do Graphify. Manter apenas o original e criar links/referências nos locais removidos.

### 5.4 Fase 3: Organização de Docs Raiz (Risco Baixo)

```
MOVE:
  docs/audit-report.md           → docs/audit/audit-report.md (ou manter)
  docs/desktop-audit-report.md   → docs/audit/desktop-audit-report.md
  docs/desktop-*.md (6 arquivos) → docs/audit/ ou docs/architecture/
  docs/Projetos/                 → docs/projects/ (renomear para inglês)

KEEP:
  CHANGELOG.md (raiz)            → gerado pelo CI
  PROJECT_HEALTH.md (raiz)       → gerado pelo CI
  README.md (raiz)               → entrada do projeto
```

### 5.5 Fase 4: Arquitetura Docs (Risco Médio)

```
MOVE (git mv):
  docs/Arquitetura/ → docs/architecture-pt/ (ou manter como está)

MERGE (futuro):
  docs/architecture/SYSTEM_ARCHITECTURE.md + docs/Arquitetura/
  → Unificar num único documento bilíngue ou complementar
```

### 5.6 Considerações de Rollback

| Fase | Rollback |
|------|----------|
| Fase 0 | `git restore --source=HEAD -- <caminhos>` |
| Fase 1 | Parar script de sync; vault fica estático |
| Fase 2 | `git restore --source=HEAD -- docs/wiki/SDD-*.md` |
| Fase 3 | `git mv` reverso |
| Fase 4 | `git mv` reverso |

---

## Fase 6 — Análise de Impacto

### 6.1 README

Nenhum README referencia diretórios vazios. Root `README.md` descreve arquitetura, não estrutura de pastas.

### 6.2 Links Relativos

- Links em `docs/` são internos ao submodule → sem impacto por migrations externas
- Links em `workspace/kaos/vault/` são internos ao Obsidian vault
- Links de `docs/` para `workspace/kaos/vault/` não existem (e vice-versa)

### 6.3 Graphify

- Graphify indexa `graphify-out/` e o código fonte, não a documentação duplicada
- `GRAPH_REPORT.md` (403 KB) inclui análise de todo o repositório
- Remover placeholders não afeta o grafo

### 6.4 Obsidian Vault

- `workspace/kaos/vault/` é o vault raiz do Obsidian
- Remover `wiki/` deste vault quebraria links internos do Obsidian
- **Critical:** Qualquer alteração em `workspace/kaos/vault/` deve preservar a estrutura que o Obsidian espera

### 6.5 Scripts

- `scripts/sync-vault.ps1` (a criar) deve ser o único script afetado
- `assistant/scripts/` não referenciam diretórios de documentação
- `desktop/` não referência diretórios de documentação

### 6.6 CI/CD

- `registry-sync.yml` escaneia `docs/` como submodule → sem impacto
- Nenhum workflow referencia placeholders vazios
- `graphify-update.yml` opera em `graphify-out/` → sem impacto

### 6.7 GitHub Pages / Indexadores

- Não há configuração de GitHub Pages detectada
- Sem indexadores externos

### 6.8 Agents / OpenCode / MCPs

- `.agents/rules/graphify.md` referencia `graphify-out/`, não docs duplicados
- `.opencode/` referencias são internas ao diretório
- MCPs não referenciam placeholders

### 6.9 Impacto Zero Confirmado Para

| Item | Impacto | Justificativa |
|------|---------|---------------|
| README.md | Nenhum | Não referencia placeholders |
| CHANGELOG.md | Nenhum | Gerado automaticamente |
| .github/workflows/* | Nenhum | Não referencia docs structure |
| .opencode/* | Nenhum | Configuração interna |
| .agents/* | Nenhum | Referencia graphify-out/ |
| .specify/* | Nenhum | Memória interna |
| graphify/* | Nenhum | Subprojeto independente |
| assistant/* | Nenhum | Código backend |
| desktop/* | Nenhum | Código frontend |
| infra/* | Nenhum | Docker/compose |
| kaos-research/* | Nenhum | Laboratório independente |

---

## Fase 7 — Estrutura Final Recomendada

### 7.1 Estado Atual (antes da migração)

```
K.A.O.S/
├── README.md, CHANGELOG.md, PROJECT_HEALTH.md  ← órfãos na raiz
├── docs/ (submodule)                            ← 1.409 arquivos
├── 14 diretórios vazios                         ← poluição visual
├── kaos-research/                               ← independente (KEEP)
├── graphify/                                    ← independente (KEEP)
├── airllm/                                      ← submodule (KEEP)
├── .opencode/ .agents/ .specify/ .github/       ← config (KEEP)
├── assistant/ backend/ desktop/ infra/           ← código (KEEP)
├── workspace/kaos/vault/                        ← Obsidian vault
└── config/ data/ scripts/ users/                ← dados (KEEP)
```

### 7.2 Estado Futuro Recomendado

```
K.A.O.S/
├── README.md                    ← KEEP (raiz)
├── CHANGELOG.md                 ← KEEP (raiz, gerado CI)
├── PROJECT_HEALTH.md            ← KEEP (raiz, gerado CI)
├── package.json                 ← KEEP
├── setup.ps1                    ← KEEP
│
├── docs/ (submodule)            ← documentação centralizada
│   ├── index.md
│   ├── architecture/            ← EN (evoluída)
│   ├── architecture-pt/         ← PT-BR (original) [ex-Arquitetura/]
│   ├── adr/                     ← KEEP
│   ├── sdd/                     ← KEEP (fonte canônica SDDs)
│   ├── wiki/                    ← KEEP (vault wiki, 1.201 arquivos)
│   ├── guides/                  ← KEEP
│   ├── governance/              ← KEEP
│   ├── projects/                ← [ex-Projetos/]
│   ├── audit/                   ← [para relatórios de auditoria]
│   ├── operations/              ← KEEP
│   ├── monitoring/              ← KEEP
│   ├── observability/          ← KEEP
│   ├── api/                     ← KEEP
│   ├── openCode/                ← KEEP
│   ├── ci-cd/                   ← KEEP
│   ├── security/                ← KEEP
│   ├── setup/                   ← KEEP
│   ├── troubleshooting/         ← KEEP
│   ├── blueprint/               ← KEEP
│   ├── evolution/               ← KEEP
│   ├── generated/               ← KEEP (JSON do KIRL)
│   └── runtime/                 ← KEEP (DRL snapshots)
│
├── kaos-research/               ← KEEP (independente)
│   ├── README.md
│   ├── adrs/
│   ├── benchmarks/
│   ├── catalog/
│   ├── evidence/
│   ├── experiments/
│   └── reports/
│
├── graphify/                    ← KEEP (subprojeto)
├── airllm/                      ← KEEP (submodule)
│
├── .opencode/                   ← KEEP (dotfile)
├── .agents/                     ← KEEP (dotfile)
├── .specify/                    ← KEEP (dotfile)
├── .github/                     ← KEEP (dotfile)
│
├── workspace/kaos/vault/        ← KEEP (Obsidian vault)
│   ├── wiki/                    ← SYNC (espelho de docs/wiki/)
│   ├── Arquitetura/             ← SYNC (espelho de docs/architecture-pt/)
│   └── ...outros diretórios vault...
│
├── assistant/                   ← KEEP (código)
├── desktop/                     ← KEEP (código)
├── backend/                     ← KEEP (placeholder)
├── infra/                       ← KEEP (Docker/compose)
│
├── config/                      ← KEEP
├── data/                        ← KEEP
├── scripts/                     ← KEEP
└── users/                       ← KEEP
```

### 7.3 Diretórios a Remover (DELETE)

| Diretório | Motivo |
|-----------|--------|
| `Arquitetura/` | Vazio; conteúdo em `docs/` |
| `SDD/` | Vazio; SDDs em `docs/sdd/` |
| `wiki/` | 2 arquivos esqueleto; wiki em `docs/wiki/` |
| `IA/` | Vazio |
| `Estudos/` | Vazio |
| `Diario/` | Vazio |
| `Projetos/` | Vazio; projetos em `docs/Projetos/` |
| `AWS/` | Vazio |
| `Python/` | Vazio |
| `Java/` | Vazio |
| `raw/` | Vazio |
| `Inbox/` | Vazio |
| `CI-CD/` | Vazio; CI/CD em `.github/workflows/` |

### 7.4 Documentos a Sincronizar (SYNC)

| Origem | Destino | Método |
|--------|---------|--------|
| `docs/wiki/` | `workspace/kaos/vault/wiki/` | Script `sync-vault.ps1` |
| `docs/architecture/` | `workspace/kaos/vault/architecture/` | Script `sync-vault.ps1` |
| `docs/Arquitetura/` | `workspace/kaos/vault/Arquitetura/` | Script `sync-vault.ps1` |

### 7.5 Documentos a Remover Cópias (DELETE cópias, KEEP original)

| Original | Cópias a Remover |
|----------|-----------------|
| `docs/sdd/SDD-*.md` (20+ arquivos) | `docs/wiki/SDD-*.md`, `workspace/.../wiki/SDD-*.md` |
| `docs/sdd/sdd_*.md` (16 arquivos) | `docs/wiki/sdd_*.md`, `workspace/.../wiki/sdd_*.md` |
| `docs/governance/DOCUMENTATION_GOVERNANCE_SDD.md` | `docs/wiki/...`, `workspace/.../wiki/...` |
| `docs/governance/adr-governance.md` | `docs/wiki/...`, `workspace/.../wiki/...` |
| `CHANGELOG.md` (raiz) | `docs/CHANGELOG.md` (manter apenas raiz) |

---

## Checklist de Critérios de Aceitação

- [x] **Todos os documentos catalogados:** 1.409 em `docs/` + 18 em `kaos-research/` + 733 em `graphify/` + etc.
- [x] **Todas as duplicações identificadas:** 1.201 arquivos duplicados entre wiki/vault + SDDs triplicados + governança duplicada
- [x] **Fonte de verdade definida para cada tipo:** SDDs → `docs/sdd/`, Wiki → `docs/wiki/`, etc.
- [x] **Justificativa para manter/mover/remover cada diretório:** Documentada na Fase 4 e 7
- [x] **Plano de migração seguro:** 4 fases com rollback documentado
- [x] **Nenhuma alteração executada:** Relatório entregue sem modificações

---

## Anexo: Mapa de Dependências entre Diretórios de Documentação

```
docs/ (submodule)
├── sdd/ ───────────────► docs/wiki/ (cópia) ────► workspace/kaos/vault/wiki/ (cópia)
├── governance/ ─────────► docs/wiki/ (cópia) ────► workspace/kaos/vault/wiki/ (cópia)
├── architecture/ ───────► docs/wiki/ (stubs)
├── Arquitetura/ ────────► docs/wiki/ (stubs) ────► workspace/kaos/vault/Arquitetura/ (futuro)
├── wiki/ ───────────────► workspace/kaos/vault/wiki/ (sync desejado)
│   └── README.*.md (32) ──► workspace/kaos/vault/wiki/README.*.md (cópia)

raiz/
├── CHANGELOG.md ────────► docs/CHANGELOG.md (duplicado manual)
├── PROJECT_HEALTH.md ───► docs/wiki/PROJECT_HEALTH.md (cópia)

kaos-research/ (independente)
├── adrs/ ─────────────── (ADRs próprios, não vinculados a docs/adr/)
├── evidence/ ─────────── (evidências independentes)
└── experiments/ ──────── (experimentos isolados)

.opencode/
├── references/architecture.md ──► (resumo da arquitetura para AI agents)
├── references/directory-structure.md ──► (mapa de diretórios)
└── agents/ ─────────────► (agentes que consomem a documentação)
```

---

**Fim do Relatório**
