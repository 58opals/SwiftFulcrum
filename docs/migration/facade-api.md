# SwiftFulcrum Facade API Hard-Cut Migration

## Release policy

This release hard-cuts legacy public API names.
Only `SwiftFulcrum.*` facade paths are exported.

## Old-to-new mapping

| Removed legacy API | Supported facade API |
| --- | --- |
| `FulcrumClient` | `SwiftFulcrum.Client` |
| `FulcrumMethodRequest` | `SwiftFulcrum.RPC.Method` |
| `FulcrumResponse` | `SwiftFulcrum.RPC.Response` |
| `JSONRPCResponse` | `SwiftFulcrum.RPC.ResponseProtocol` |
| `JSONRPCNilAcceptingResponse` | `SwiftFulcrum.RPC.NilAcceptingResponseProtocol` |
| `ProtocolVersionModel` | `SwiftFulcrum.ProtocolVersion` |
| `FulcrumTransportState` | `SwiftFulcrum.Transport.State` |
| `FulcrumServerCatalogRepository` | `SwiftFulcrum.ServerCatalog.Repository` |
| `MetricsClient` | `SwiftFulcrum.Metrics.ClientProtocol` |
| `LogModel` | `SwiftFulcrum.Logging` |

## Migration checklist

1. Replace all legacy type references with `SwiftFulcrum.*` mappings above.
2. Update imports/usages that previously relied on top-level legacy symbols.
3. Re-run local build/tests to confirm no legacy symbol references remain.
