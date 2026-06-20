---
type: knowledge
domain: arquitetura
status: active
---

# Arquitetura Geral
*Offline Personal AI Architecture*

> Especificacao de alto nivel da arquitetura geral do assistente de IA offline, detalhando os fluxos de integracao.

## Parent
- [[Viso Geral]]

## Children
- [[Estrutura de Pastas]]
- [[Fluxo de Dados]]
- [[Infraestrutura Docker]]

## Related
- [[EstratÉgia de RepositÓrios Padroes de Projeto EstratÉgia de Testes]]

## Tags
#kaos #arquitetura #system #offline

---

## Conteudo
## Objetivo

Criar uma IA pessoal capaz de:

- Operar offline utilizando modelos locais.
    
- Utilizar o Obsidian como memória de longo prazo.
    
- Consultar conhecimento através de RAG.
    
- Executar integrações externas através do N8N quando houver internet.
    
- Integrar-se com sistemas corporativos desenvolvidos em Spring Boot.
    

---

## Arquitetura

Usuário  
↓  
Python (IA)  
↓  
Spring Boot (Regras de Negócio)  
↓  
N8N (Integrações)

### Python

Responsável por:

- Conversação
    
- Raciocínio
    
- Planejamento
    
- RAG
    
- Consulta ao Obsidian
    
- Escolha de ferramentas
    

Tecnologias:

- Python 3.13
    
- FastAPI
    
- LangGraph
    
- Ollama
    
- Qdrant
    

### Spring Boot

Responsável por:

- Regras de negócio
    
- Segurança
    
- Banco de dados
    
- APIs REST
    
- Eventos de domínio
    

### N8N

Responsável por:

- WhatsApp
    
- Email
    
- GitHub
    
- AWS
    
- CRM
    
- Slack/Discord
    

---

## Fluxo de Exemplo

Usuário:  
"Cadastre João e envie um email de boas-vindas"

1. IA interpreta a intenção.
    
2. IA chama API Spring Boot.
    
3. Spring Boot valida regras e salva dados.
    
4. Spring Boot publica evento.
    
5. N8N recebe webhook.
    
6. N8N envia email e executa integrações.
    

---

## Estrutura do Projeto

ai-assistant/

- api/
    
- agent/
    
- rag/
    
- obsidian/
    
- integrations/
    
- frontend/
    
- docker/
    
- docs/
    

---

## Tecnologias Principais

- Python 3.13
    
- FastAPI
    
- LangGraph
    
- Ollama
    
- Qdrant
    
- Spring Boot
    
- PostgreSQL
    
- N8N
    
- Docker
    
- GitHub Actions
    

---

## Conceito Principal

Python pensa.  
Spring Boot aplica as regras.  
N8N executa ações externas.  
Obsidian armazena conhecimento.

