Source: K.A.O.S Architecture
Tags: #sdd #llm #provider #openai #claude #gemini #ollama #hybrid
Related: [[index]] [[00_visao_geral]] [[02_fluxo_dados]] [[sdd_knowledge_wiki_layer]] [[sdd_arquitetura_orquestracao]]

# SDD — Provedor Híbrido de LLM (Local + Cloud)

## Objetivo

Desacoplar o K.A.O.S de qualquer provedor de LLM específico, permitindo alternar entre:

- **Local**: Ollama (Qwen3, Llama, Mistral)
- **Cloud**: OpenAI (GPT-5), Anthropic (Claude), Google (Gemini), xAI (Grok)
- **OpenAI-compatible**: Qualquer provedor com API compatível

## Arquitetura

```
Triple Router → LLM Factory → BaseProvider
                ├── OllamaProvider
                ├── OpenAIProvider
                ├── ClaudeProvider
                └── GeminiProvider
```

### Interface BaseProvider

```python
class BaseProvider(ABC):
    @abstractmethod
    async def chat(self, messages, stream=False, temperature=0.7) -> LLMResponse | AsyncIterator[str]: ...
    @abstractmethod
    async def chat_with_tools(self, messages, tools, temperature=0.7) -> LLMResponse: ...
```

### Factory Pattern

```python
class LLMFactory:
    _providers = {"ollama": OllamaProvider, "openai": OpenAIProvider, "anthropic": ClaudeProvider, "gemini": GeminiProvider}

    @classmethod
    def build(cls, provider_name: str, model: str) -> BaseProvider:
        return cls._providers[provider_name](model=model)
```

### MODEL_MAP

```python
MODEL_MAP = {
    "kaos-fast":  ("ollama", "qwen3:4b"),
    "kaos-rag":   ("ollama", "qwen3:8b"),
    "kaos":       ("ollama", "qwen3:14b"),
    "kaos-cloud": ("openai", "gpt-5"),
    "kaos-sonnet": ("anthropic", "claude-sonnet-4"),
    "kaos-gemini": ("gemini", "gemini-2.5-pro"),
}
```

### Fallback Automático

```python
async def chat_with_fallback(model_id, messages, stream=False):
    provider_name, model = LLMFactory.resolve(model_id)
    for fb in [provider_name] + FALLBACK_CHAIN:
        try:
            return await LLMFactory.build(fb, model).chat(messages, stream=stream)
        except Exception:
            continue
    raise RuntimeError("Todos os providers falharam")
```

### Embeddings

Independentes do provider LLM. Continuam usando BGE-M3 / nomic.

### Métricas

```python
@dataclass
class ProviderMetrics:
    provider: str
    model: str
    latency_ms: float
    tokens: int
    cost: float
    fallback_used: bool
    fallback_chain: list[str] | None = None
```
