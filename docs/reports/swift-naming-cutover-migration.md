# SwiftFulcrum Naming Cutover Migration

## Scope

This document summarizes the single-cutover naming migration applied to satisfy the strict Swift naming policy from `docs/reports/swift-naming-audit-2026-03-03.md`.

- Compatibility aliases/typealiases were intentionally not introduced.
- The cutover is API-breaking for renamed public symbols.

## Breaking Change Categories

### 1. Duplicate Role Suffix Removal (`*Model -> *` for nested declarations)

Representative changes:

- `FulcrumMethodRequest.BlockchainModel.HeaderModel` -> `FulcrumMethodRequest.BlockchainModel.Header`
- `FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentModel` -> `FulcrumResponse.ResultModel.Blockchain.ScriptHash.ListUnspent`
- `FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.SubscribeModel` -> `FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.Subscribe`
- `WebSocketModel.ReconnectorModel` -> `WebSocketModel.Reconnector`
- `ProtocolVersionModel.RangeModel` -> `ProtocolVersionModel.Range`

### 2. Manual Collision Override

- `FulcrumClient.Error.Client` -> `FulcrumClient.Error.ClientIssue`

### 3. File Matrix Compliance Renames

Representative path changes:

- `FulcrumResponse+ResultModel+Error.swift` -> `FulcrumResponse.ResultModel+Error.swift`
- `FulcrumResponse+JSONRPCModel+Error.swift` -> `FulcrumResponse.JSONRPCModel+Error.swift`
- `FulcrumResponse+JSONRPCModel+ResultModel.swift` -> `FulcrumResponse.JSONRPCModel+Result.swift`
- `FulcrumClient+Configuration+ProtocolNegotiationModel.swift` -> `FulcrumClient.Configuration+ProtocolNegotiationModel.swift`

Log split for matrix compliance:

- `LogModel~ConsoleAdapter.swift` was split into:
  - `LogModel+ConsoleAdapter.swift`
  - `LogModel+Behavior.swift`
  - `LogModel+Context.swift`
  - `LogModel~BehaviorControl.swift`
  - `LogModel.ConsoleAdapter+Entry.swift`
  - `LogModel.ConsoleAdapter+OutputSink.swift`

### 4. Top-level Protocol Filename Compliance

- `FulcrumErrorConvertibleModel` moved to `Sources/SwiftFulcrum/FulcrumErrorConvertibleModel_.swift`.

### 5. Advisory Cleanup

- `CodingKeys`-style response-decoding enums in the flagged JSONRPC response files were migrated to `CodingKeysModel` with explicit `init(from:)` decoding to preserve behavior.

## Consumer Migration Guidance

1. Rebuild against the new API surface and update all compile errors from removed `*Model` nested names.
2. Replace any `FulcrumClient.Error.Client` references with `FulcrumClient.Error.ClientIssue`.
3. If your code referenced internal source paths directly, update them to the matrix-compliant filenames above.
4. Re-run full integration tests for request/response decoding and subscription flows.
