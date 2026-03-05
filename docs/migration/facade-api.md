# SwiftFulcrum Facade API Migration

## Compatibility-first rollout

This release introduces `SwiftFulcrum.*` as the default public API surface while keeping legacy top-level names functional and deprecated.

## Old-to-new mapping

| Legacy API | New facade API |
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

## Module-qualified legacy compatibility

To preserve module-qualified call sites after adding a `SwiftFulcrum` facade root type, this release also includes deprecated nested compatibility aliases:

- `SwiftFulcrum.FulcrumClient`
- `SwiftFulcrum.FulcrumMethodRequest`
- `SwiftFulcrum.FulcrumResponse`
- `SwiftFulcrum.JSONRPCResponse`
- `SwiftFulcrum.JSONRPCNilAcceptingResponse`
- `SwiftFulcrum.ProtocolVersionModel`
- `SwiftFulcrum.FulcrumTransportState`
- `SwiftFulcrum.FulcrumServerCatalogRepository`
- `SwiftFulcrum.MetricsClient`
- `SwiftFulcrum.LogModel`

## Planned removal policy

Legacy top-level APIs and nested legacy compatibility aliases are scheduled for removal in the next major release.

Recommended migration sequence:

1. Move all downstream code to `SwiftFulcrum.*` facade paths in this release window.
2. Remove uses of deprecated legacy names before adopting the next major version.
