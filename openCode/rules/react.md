---
description: Regras React para o K.A.O.S
globs: ["desktop/**/*.tsx"]
---
# React Rules

- Function components com `interface Props` explicita (nao inline)
- Default exports apenas para page components
- Named exports para todo o resto (componentes, hooks, utilitarios)
- Hooks customizados prefixados com `use`
- Stores Zustand: `create<State>((set, get) => ({...}))`
- Selectors: hooks derivados para acesso a estado
- Efeitos colaterais em `useEffect` com cleanup
- Event listeners no EventBus com unsubscribe no cleanup
- Componentes puros sempre que possivel (sem estado interno)
- FSD layers: app > pages > widgets > features > entities > shared
- Nenhuma camada importa de camadas superiores
- shared/ nao importa nada do projeto

## Resumo
- Informações pendentes de validação ou auto-geração.

## Objetivo
- Informações pendentes de validação ou auto-geração.

## Responsabilidades
- Informações pendentes de validação ou auto-geração.

## Dependencias
- Informações pendentes de validação ou auto-geração.

## Fluxos
- Informações pendentes de validação ou auto-geração.

## Integracoes
- Informações pendentes de validação ou auto-geração.

## Arquivos Relacionados
- Informações pendentes de validação ou auto-geração.

## Referencias KIRL
- Informações pendentes de validação ou auto-geração.

## Status
- Informações pendentes de validação ou auto-geração.

## Ultima Atualizacao
- Informações pendentes de validação ou auto-geração.
