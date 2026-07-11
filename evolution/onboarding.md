# K.A.O.S Evolution — Developer Onboarding

## How to Add a New Capability

1. **Define the Port** in `assistant/app/domain/ports/`:
   ```python
   class NewCapabilityPort(ABC):
       @abstractmethod
       async def do_thing(self, request) -> result: ...
   ```

2. **Create a Service** in `assistant/app/core/services/`:
   ```python
   class NewCapabilityService:
       def __init__(self):
           self.registry = ProviderRegistry[NewCapabilityPort]("new-cap")
   ```

3. **Implement at least one Adapter** in `assistant/app/providers/`:
   ```python
   class FrameworkAdapter(NewCapabilityPort):
       async def do_thing(self, request): ...
   ```

4. **Create REST API** in `assistant/app/api/`:
   ```python
   router = APIRouter(prefix="/api/new-capability")
   ```

5. **Register in main.py**:
   ```python
   from app.api.new_capability_api import router as new_capability_router
   app.include_router(new_capability_router)
   ```

6. **Create Desktop Store** in `desktop/src/application/stores/`:
   ```typescript
   // Never import frameworks. Only call REST API.
   export const useNewCapabilityStore = create(...)
   ```

## How to Swap a Provider

1. **Implement the new adapter** (implementing the same Port)
2. **Register it** in the service's `ProviderRegistry`
3. **Activate it**: `registry.activate("new-provider")`
4. **No changes needed** in REST API, Desktop, or any other layer

## How to Add a Framework to Research

1. Create experiment dir: `kaos-research/experiments/<framework>/`
2. Write `experiment.py` with hypothesis + benchmark
3. Run and record results in `results.json`
4. Update `capability-matrix.md` with findings
5. If validated, write ADR → implement adapter

## Architecture Rules (Don't Break)

| Rule | Enforcement |
|---|---|
| Desktop never imports frameworks | `verify-no-framework-imports.ps1` |
| Backend never fabricates data | `verify-no-mocks.ps1` |
| Domain ports have no framework deps | Manual review |
| Services use ProviderRegistry | Code review |
| Framework changes require ADR | CI + manual review |
| New capabilities use Ports → Adapters | Code review |

## Service → Framework Map

| Service | Current Provider | Registry Name |
|---|---|---|
| GraphService | GraphifyAdapter | `graphify` |
| MemoryService | PostgresMemoryAdapter | `postgres` |
| RetrievalService | QdrantAdapter | `qdrant` |
| InferenceService | 5 providers | `ollama`, `airllm`, `openai`, `gemini`, `claude` |
| PlannerService | LangGraphAdapter | `langgraph` |
| EvidenceService | EvidenceEngine | `engine` |
| KnowledgeService | Coalescing | (delegates to above) |
