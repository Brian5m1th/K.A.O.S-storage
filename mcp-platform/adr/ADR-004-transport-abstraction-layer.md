# ADR-004: Transport Abstraction Layer

- **Status:** Proposed
- **Decision Owner:** Brian Smith
- **Review Date:** 2027-07-12
- **Date:** 2026-07-12
- **Supersedes:** None

---

## Context

MCP servers communicate with clients via a transport protocol. The Model Context Protocol specification defines two primary transports:

1. **STDIO** — Subprocess-based, standard input/output, for local servers.
2. **HTTP/SSE** — Server-Sent Events over HTTP, for remote servers.

Additionally, the ecosystem is evolving:
- WebSocket transport (emerging).
- Future transport protocols not yet defined.

The platform **must not** couple business logic to any specific transport implementation. It must be possible to:

- Switch a server from STDIO to HTTP/SSE without changing client code.
- Support multiple transports simultaneously.
- Add new transports without modifying existing code.
- Use MCP servers behind a gateway (K.A.O.S Phase 2) transparently.

## Decision

### Transport Abstraction Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Agent / Client                     │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              Transport Abstraction Layer              │
│                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────┐  │
│  │  STDIO   │  │  HTTP    │  │   SSE    │  │  WS  │  │
│  │ Transport│  │ Transport│  │ Transport│  │  ... │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┘  │
└───────┼──────────────┼──────────────┼─────────────────┘
        │              │              │
        ▼              ▼              ▼
┌─────────────────────────────────────────────────────┐
│                    MCP Server                          │
│  (local subprocess / remote endpoint / container)     │
└─────────────────────────────────────────────────────┘
```

### Transport Interface

Every transport implements the following interface:

```python
class MCPTransport(ABC):
    """Abstract transport layer for MCP communication."""

    @abstractmethod
    async def connect(self) -> bool:
        """Establish the transport connection.
        Returns True if successful."""
        ...

    @abstractmethod
    async def disconnect(self) -> bool:
        """Gracefully close the transport connection."""
        ...

    @abstractmethod
    async def send_request(self, method: str, params: dict) -> dict:
        """Send a JSON-RPC request and wait for the response.
        Raises TransportError on failure."""
        ...

    @abstractmethod
    async def send_notification(self, method: str, params: dict) -> None:
        """Send a JSON-RPC notification (fire-and-forget)."""
        ...

    @abstractmethod
    async def receive_response(self) -> dict | None:
        """Receive the next response from the server.
        Returns None if the stream is closed."""
        ...

    @abstractmethod
    def get_server_info(self) -> dict:
        """Return transport-level server information:
        - type: "stdio" | "http" | "sse" | "websocket"
        - pid: int (for stdio) or endpoint: str (for network transports)
        - connected_at: timestamp
        - latency_ms: float
        """
        ...

    @abstractmethod
    async def health_check(self) -> dict:
        """Check if the transport is healthy.
        Returns {"status": "healthy" | "degraded" | "down", "latency_ms": int, "error": str | None}
        """
        ...
```

### Supported Transports (v1.0)

| Transport | Use Case | Pros | Cons |
|-----------|----------|------|------|
| **STDIO** | Local servers, subprocess-based | Zero network config, low latency, simple | Process lifecycle management, no remote access |
| **HTTP with SSE** | Remote/gateway-backed servers | Remote access, centralized auth, observability | Network latency, more complex setup |
| **HTTP/SSE (Future)** | Web UI, streaming responses | Bidirectional, real-time | More complex than SSE |

### Transport Selection

The transport is selected based on the server's configuration in `registry.yaml`:

```yaml
# STDIO server (default for local tools)
servers:
  - id: filesystem
    protocol:
      default: stdio
      transports:
        - type: stdio
          command: "npx"
          args: ["-y", "@modelcontextprotocol/server-filesystem", "."]
```

```yaml
# HTTP/SSE server (for remote or gateway access)
servers:
  - id: github
    protocol:
      default: sse
      transports:
        - type: stdio
          command: "npx"
          args: ["-y", "@modelcontextprotocol/server-github"]
        - type: sse
          url: "http://localhost:8080/mcp/github"
          headers:
            Authorization: "Bearer ${secrets.github.token}"
```

### Transport Discovery

When a server is initialized:

1. The client checks `server.protocol.default` to determine the primary transport.
2. If the default transport is unavailable, it falls back to the next transport in the list.
3. The transport is instantiated via a factory:

```python
class TransportFactory:
    @staticmethod
    def create(transport_config: dict) -> MCPTransport:
        transport_type = transport_config.get("type", "stdio")
        if transport_type == "stdio":
            return StdioTransport(transport_config)
        elif transport_type == "sse":
            return SSETransport(transport_config)
        elif transport_type == "http":
            return HTTPTransport(transport_config)
        elif transport_type == "websocket":
            return WebSocketTransport(transport_config)
        else:
            raise ValueError(f"Unsupported transport: {transport_type}")
```

### No Business Logic in Transport

The transport layer is **purely mechanical** — it handles byte-level communication only. All higher-level concerns belong in the server abstraction layer:

- Handshake / initialization (`initialize` + `notifications/initialized`).
- Tool discovery (`tools/list`, `tools/call`).
- Error handling and retry.
- Request/response correlation (JSON-RPC `id` matching).
- Timeout and circuit breaking.

## Evidence Supporting This Decision

1. The Model Context Protocol specification explicitly supports STDIO and HTTP/SSE transports.
2. The existing K.A.O.S `_MCPServerProcess` class in `app/core/mcp_manager.py` already implements STDIO transport — this abstraction formalizes and extends that pattern.
3. Claude Code supports `--mcp-config` with both STDIO and HTTP/SSE configurations.
4. OpenCode supports STDIO MCP servers via `.opencode.json`.

## Consequences

### Positive

- New transports can be added without modifying any business logic.
- Servers can be migrated from local to remote transparently.
- The gateway in Phase 2 can expose K.A.O.S MCP servers via SSE.
- Testing is easier — mock transports can be used in tests.

### Negative

- Additional abstraction layer adds minor complexity.
- Each transport must maintain its own connection lifecycle.

### Risks & Mitigations

- **Risk:** Transport abstraction adds latency → **Mitigation:** STDIO transport is zero-overhead; HTTP/SSE overhead is inherent to network, not abstraction.

## Implementation Plan

1. Define `MCPTransport` abstract base class and `TransportError`.
2. Implement `StdioTransport` (reusing patterns from existing `_MCPServerProcess`).
3. Implement `SSETransport` for HTTP/SSE communication.
4. Implement `HTTPTransport` for direct HTTP requests.
5. Implement `TransportFactory`.
6. Integrate transport selection into server initialization flow.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Direct subprocess calls only | Simple | No remote support, couples logic to transport | Must support multiple transports |
| Use a single protocol (e.g., HTTP only) | Uniform interface | STDIO is simpler for local tools | Must support both local and remote |
| Proxy-based (one transport that proxies all) | Single interface | Adds unnecessary hop, increases latency | Direct transport is more efficient |

## Stakeholders

- **Decision Owner:** Brian Smith
- **Consulted:** —
- **Informed:** —
- **Approved by:** Brian Smith, 2026-07-12
