---
id: provider_routing
type: knowledge
phase: Fase 1
status: in-progress
tags:
- kaos
- normalized
reconstruction_confidence: medium
---

# Provider Routing — K.A.O.S

## Fluxo de Decisão

Cada requisição de chat (`POST /api/chat`) passa pelo seguinte roteamento:

```
Requisição recebida
    │
    ├─ Payload contém "provider" explícito? → usa esse
    │
    └─ Não → usa "default_provider" da config
              │
              ├─ Config não encontrada? → fallback hardcoded: "ollama"
              │
              └─ Provider desabilitado? → erro 400
```

## Implementação

`assistant/app/services/llm_service.py` contém a lógica de roteamento.

```python
class LLMService:
    def get_chat_response(self, message: str, provider: str | None = None):
        provider = self._resolve_provider(provider)
        client = self._get_client(provider)
        return await client.chat(message)

    def _resolve_provider(self, override: str | None) -> str:
        if override:
            return override
        config = self.provider_service.get_config()
        return config.get("default_provider", "ollama")
```

## Registro de Providers

Cada provider implementa uma interface comum:

```python
class BaseLLMClient(ABC):
    @abstractmethod
    async def chat(self, message: str, **kwargs) -> str: ...

    @abstractmethod
    async def stream(self, message: str, **kwargs) -> AsyncIterator[str]: ...
```

Clientes concretos:
- `OllamaClient` → `http://ollama:11434/api/chat`
- `OpenAIClient` → `https://api.openai.com/v1/chat/completions`
- `AnthropicClient` → `https://api.anthropic.com/v1/messages`
- `GoogleClient` → `https://generativelanguage.googleapis.com/v1beta/models/...`

## Configuração

Ver `docs/vault/providers/PROVIDERS.md` para detalhes de configuração de cada provider.

## Fallback Chain

Se um provider falhar (timeout, 500, rate limit), o serviço **não** faz fallback automático para outro — o erro é retornado ao cliente. Fallback entre providers é uma feature futura.
