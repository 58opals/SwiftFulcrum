# SwiftFulcrum Naming Audit (Strict)

- Generated: 2026-03-03T18:40:45
- Scope: `Sources/`, `Tests/`, `Tools/` (158 Swift files)
- Policy: `lang-swift-naming-conventions`

## Grouped Findings

### Violation: DuplicateRoleSuffix

- Count: 175
- Deterministic rename pattern: when child role token matches any ancestor role token, strip only the child trailing role suffix (`XModel -> X`).
- Collision status: 1 stripped-candidate collisions detected.
- Representative evidence:
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:28` `ScriptHashModel -> ScriptHash`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:38` `AddressModel -> Address`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:53` `BlockModel -> Block`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:58` `HeaderModel -> Header`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:62` `HeadersModel -> Headers`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:68` `TransactionModel -> Transaction`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:80` `DSProofModel -> DSProof`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:88` `UTXOModel -> UTXO`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:101` `CashTokensModel -> CashTokens`
  - `Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:102` `JSONModel -> JSON`

### Violation: FileNameMatrix

- Count: 13
- Representative evidence:
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:1` Filename has multiple "+" segments (unsupported by matrix).
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:5` Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:5` Expected exactly one nested type `ResultModel+Error`.
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:1` Filename has multiple "+" segments (unsupported by matrix).
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:5` Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:5` Expected exactly one nested type `JSONRPCModel+Error`.
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:1` Filename has multiple "+" segments (unsupported by matrix).
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:5` Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  - `Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:5` Expected exactly one nested type `JSONRPCModel+ResultModel`.
  - `Sources/SwiftFulcrum/FulcrumClient+Configuration+ProtocolNegotiationModel.swift:1` Filename has multiple "+" segments (unsupported by matrix).

### Violation: Top-Level Protocol Filename

- Count: 1
- `Sources/SwiftFulcrum/FulcrumClient+Error.swift:124` top-level protocol `FulcrumErrorConvertibleModel` expected in `FulcrumErrorConvertibleModel_.swift`.

### Advisory: PreferredRoleSuffix

- Count: 2
- `Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+MempoolModel.swift:29` `CodingKeys` uses non-preferred role token `Keys` (allowed).
- `Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:40` `CodingKeys` uses non-preferred role token `Keys` (allowed).

## Validation Summary

- Disallowed suffix violations: 0
- Bool predicate-prefix violations: 0
- Files exceeding 199 source lines: 0

## Exhaustive Appendix A: DuplicateRoleSuffix

- Violation: DuplicateRoleSuffix
  Rename: OptionsModel -> Options
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+CallModel.swift:10 declaration `struct OptionsModel`

- Violation: DuplicateRoleSuffix
  Rename: CancellationModel -> Cancellation
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+CallModel.swift:20 declaration `actor CancellationModel`

- Violation: DuplicateRoleSuffix
  Rename: ArgumentModel -> Argument
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+Configuration+ProtocolNegotiationModel.swift:44 declaration `struct ArgumentModel`

- Violation: DuplicateRoleSuffix
  Rename: SnapshotModel -> Snapshot
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+DiagnosticsModel.swift:10 declaration `struct SnapshotModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscriptionModel -> Subscription
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+DiagnosticsModel.swift:29 declaration `struct SubscriptionModel`

- Violation: DuplicateRoleSuffix
  Rename: TransportSnapshotModel -> TransportSnapshot
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/FulcrumClient+DiagnosticsModel.swift:39 declaration `struct TransportSnapshotModel`

- Violation: DuplicateRoleSuffix
  Rename: Client -> Client
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix. Stripped candidate collides with existing sibling type; manual non-colliding rename required.
  Scope: Sources/SwiftFulcrum/FulcrumClient+Error.swift:35 declaration `enum Client`

- Violation: DuplicateRoleSuffix
  Rename: StorageIssueModel -> StorageIssue
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/JSONRPC/JSONRPCModel+Error.swift:11 declaration `enum StorageIssueModel`

- Violation: DuplicateRoleSuffix
  Rename: DecodingFailureReasonModel -> DecodingFailureReason
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/JSONRPC/JSONRPCModel+Error.swift:15 declaration `enum DecodingFailureReasonModel`

- Violation: DuplicateRoleSuffix
  Rename: CoderModel -> Coder
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/JSONRPC/JSONRPCModel.swift:13 declaration `enum CoderModel`

- Violation: DuplicateRoleSuffix
  Rename: DecodeContextModel -> DecodeContext
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/JSONRPC/JSONRPCModel.swift:27 declaration `struct DecodeContextModel`

- Violation: DuplicateRoleSuffix
  Rename: LevelModel -> Level
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel.swift:8 declaration `enum LevelModel`

- Violation: DuplicateRoleSuffix
  Rename: AdapterModel -> Adapter
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel.swift:36 declaration `protocol AdapterModel`

- Violation: DuplicateRoleSuffix
  Rename: NoOperationAdapterModel -> NoOperationAdapter
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel.swift:89 declaration `struct NoOperationAdapterModel`

- Violation: DuplicateRoleSuffix
  Rename: ConsoleAdapterModel -> ConsoleAdapter
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:6 declaration `struct ConsoleAdapterModel`

- Violation: DuplicateRoleSuffix
  Rename: BehaviorModel -> Behavior
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:116 declaration `enum BehaviorModel`

- Violation: DuplicateRoleSuffix
  Rename: ContextModel -> Context
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:121 declaration `enum ContextModel`

- Violation: DuplicateRoleSuffix
  Rename: EntryModel -> Entry
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:136 declaration `struct EntryModel`

- Violation: DuplicateRoleSuffix
  Rename: OutputSinkModel -> OutputSink
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:148 declaration `actor OutputSinkModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptHashModel -> ScriptHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:28 declaration `enum ScriptHashModel`

- Violation: DuplicateRoleSuffix
  Rename: AddressModel -> Address
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:38 declaration `enum AddressModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockModel -> Block
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:53 declaration `enum BlockModel`

- Violation: DuplicateRoleSuffix
  Rename: HeaderModel -> Header
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:58 declaration `enum HeaderModel`

- Violation: DuplicateRoleSuffix
  Rename: HeadersModel -> Headers
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:62 declaration `enum HeadersModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:68 declaration `enum TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: DSProofModel -> DSProof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:80 declaration `enum DSProofModel`

- Violation: DuplicateRoleSuffix
  Rename: UTXOModel -> UTXO
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:88 declaration `enum UTXOModel`

- Violation: DuplicateRoleSuffix
  Rename: CashTokensModel -> CashTokens
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:101 declaration `struct CashTokensModel`

- Violation: DuplicateRoleSuffix
  Rename: JSONModel -> JSON
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:102 declaration `struct JSONModel`

- Violation: DuplicateRoleSuffix
  Rename: NFTModel -> NFT
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:107 declaration `struct NFTModel`

- Violation: DuplicateRoleSuffix
  Rename: CapabilityModel -> Capability
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:111 declaration `enum CapabilityModel`

- Violation: DuplicateRoleSuffix
  Rename: TokenFilterModel -> TokenFilter
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/FulcrumMethodRequest.swift:119 declaration `enum TokenFilterModel`

- Violation: DuplicateRoleSuffix
  Rename: ResultModel -> Result
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:6 declaration `struct ResultModel`

- Violation: DuplicateRoleSuffix
  Rename: IdentifierExtractableModel -> IdentifierExtractable
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel.swift:7 declaration `struct IdentifierExtractableModel`

- Violation: DuplicateRoleSuffix
  Rename: GenericModel -> Generic
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel.swift:12 declaration `struct GenericModel`

- Violation: DuplicateRoleSuffix
  Rename: CodingKeysModel -> CodingKeys
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel.swift:29 declaration `enum CodingKeysModel`

- Violation: DuplicateRoleSuffix
  Rename: NilConstructibleModel -> NilConstructible
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel.swift:94 declaration `protocol NilConstructibleModel`

- Violation: DuplicateRoleSuffix
  Rename: ResultNilProducerModel -> ResultNilProducer
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel.swift:95 declaration `enum ResultNilProducerModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockchainModel -> Blockchain
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+BlockchainModel.swift:4 declaration `struct BlockchainModel`

- Violation: DuplicateRoleSuffix
  Rename: MempoolModel -> Mempool
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+MempoolModel.swift:4 declaration `struct MempoolModel`

- Violation: DuplicateRoleSuffix
  Rename: FlexibleNumberModel -> FlexibleNumber
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+MempoolModel.swift:5 declaration `struct FlexibleNumberModel`

- Violation: DuplicateRoleSuffix
  Rename: GetInfoModel -> GetInfo
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+MempoolModel.swift:22 declaration `struct GetInfoModel`

- Violation: DuplicateRoleSuffix
  Rename: ServerModel -> Server
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:4 declaration `struct ServerModel`

- Violation: DuplicateRoleSuffix
  Rename: PingModel -> Ping
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:5 declaration `struct PingModel`

- Violation: DuplicateRoleSuffix
  Rename: VersionModel -> Version
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:7 declaration `struct VersionModel`

- Violation: DuplicateRoleSuffix
  Rename: FeaturesModel -> Features
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:27 declaration `struct FeaturesModel`

- Violation: DuplicateRoleSuffix
  Rename: HostModel -> Host
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:54 declaration `struct HostModel`

- Violation: DuplicateRoleSuffix
  Rename: ReusablePaymentAddressModel -> ReusablePaymentAddress
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:61 declaration `struct ReusablePaymentAddressModel`

- Violation: DuplicateRoleSuffix
  Rename: AddressModel -> Address
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:4 declaration `struct AddressModel`

- Violation: DuplicateRoleSuffix
  Rename: GetBalanceModel -> GetBalance
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:5 declaration `struct GetBalanceModel`

- Violation: DuplicateRoleSuffix
  Rename: GetFirstUseModel -> GetFirstUse
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:10 declaration `struct GetFirstUseModel`

- Violation: DuplicateRoleSuffix
  Rename: GetHistoryItemModel -> GetHistoryItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:17 declaration `struct GetHistoryItemModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMempoolItemModel -> GetMempoolItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:24 declaration `struct GetMempoolItemModel`

- Violation: DuplicateRoleSuffix
  Rename: ListUnspentItemModel -> ListUnspentItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:33 declaration `struct ListUnspentItemModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeParametersModel -> SubscribeParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+AddressModel.swift:42 declaration `enum SubscribeParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockModel -> Block
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+BlockModel.swift:4 declaration `struct BlockModel`

- Violation: DuplicateRoleSuffix
  Rename: HeaderParametersModel -> HeaderParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+BlockModel.swift:6 declaration `enum HeaderParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: ProofModel -> Proof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+BlockModel.swift:10 declaration `struct ProofModel`

- Violation: DuplicateRoleSuffix
  Rename: HeadersModel -> Headers
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+BlockModel.swift:35 declaration `struct HeadersModel`

- Violation: DuplicateRoleSuffix
  Rename: CodingKeysModel -> CodingKeys
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+BlockModel.swift:43 declaration `enum CodingKeysModel`

- Violation: DuplicateRoleSuffix
  Rename: HeaderModel -> Header
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+HeaderModel.swift:4 declaration `struct HeaderModel`

- Violation: DuplicateRoleSuffix
  Rename: GetModel -> Get
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+HeaderModel.swift:5 declaration `struct GetModel`

- Violation: DuplicateRoleSuffix
  Rename: HeadersModel -> Headers
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+HeadersModel.swift:4 declaration `struct HeadersModel`

- Violation: DuplicateRoleSuffix
  Rename: GetTipModel -> GetTip
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+HeadersModel.swift:5 declaration `struct GetTipModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeParametersModel -> SubscribeParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+HeadersModel.swift:11 declaration `enum SubscribeParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptHashModel -> ScriptHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:4 declaration `struct ScriptHashModel`

- Violation: DuplicateRoleSuffix
  Rename: GetBalanceModel -> GetBalance
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:5 declaration `struct GetBalanceModel`

- Violation: DuplicateRoleSuffix
  Rename: GetFirstUseModel -> GetFirstUse
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:10 declaration `struct GetFirstUseModel`

- Violation: DuplicateRoleSuffix
  Rename: GetHistoryItemModel -> GetHistoryItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:17 declaration `struct GetHistoryItemModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMempoolItemModel -> GetMempoolItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:24 declaration `struct GetMempoolItemModel`

- Violation: DuplicateRoleSuffix
  Rename: ListUnspentItemModel -> ListUnspentItem
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:31 declaration `struct ListUnspentItemModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeParametersModel -> SubscribeParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+ScriptHashModel.swift:40 declaration `enum SubscribeParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:4 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: GetParametersModel -> GetParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:8 declaration `enum GetParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: DetailedModel -> Detailed
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:12 declaration `struct DetailedModel`

- Violation: DuplicateRoleSuffix
  Rename: InputModel -> Input
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:26 declaration `struct InputModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptSigModel -> ScriptSig
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:32 declaration `struct ScriptSigModel`

- Violation: DuplicateRoleSuffix
  Rename: OutputModel -> Output
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:38 declaration `struct OutputModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptPubKeyModel -> ScriptPubKey
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:43 declaration `struct ScriptPubKeyModel`

- Violation: DuplicateRoleSuffix
  Rename: GetConfirmedBlockHashModel -> GetConfirmedBlockHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:72 declaration `struct GetConfirmedBlockHashModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMerkleModel -> GetMerkle
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:80 declaration `struct GetMerkleModel`

- Violation: DuplicateRoleSuffix
  Rename: IDFromPosModel -> IDFromPos
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:86 declaration `struct IDFromPosModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeParametersModel -> SubscribeParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:92 declaration `enum SubscribeParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionHashAndHeightModel -> TransactionHashAndHeight
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:96 declaration `enum TransactionHashAndHeightModel`

- Violation: DuplicateRoleSuffix
  Rename: DSProofModel -> DSProof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:140 declaration `struct DSProofModel`

- Violation: DuplicateRoleSuffix
  Rename: GetModel -> Get
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:141 declaration `struct GetModel`

- Violation: DuplicateRoleSuffix
  Rename: OutpointModel -> Outpoint
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:148 declaration `struct OutpointModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeParametersModel -> SubscribeParameters
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:157 declaration `enum SubscribeParametersModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionHashAndDSProofModel -> TransactionHashAndDSProof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+TransactionModel.swift:161 declaration `enum TransactionHashAndDSProofModel`

- Violation: DuplicateRoleSuffix
  Rename: UTXOModel -> UTXO
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+UTXOModel.swift:4 declaration `struct UTXOModel`

- Violation: DuplicateRoleSuffix
  Rename: GetInfoModel -> GetInfo
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel+UTXOModel.swift:5 declaration `struct GetInfoModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockchainModel -> Blockchain
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+BlockchainModel.swift:4 declaration `struct BlockchainModel`

- Violation: DuplicateRoleSuffix
  Rename: MempoolModel -> Mempool
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+MempoolModel.swift:4 declaration `struct MempoolModel`

- Violation: DuplicateRoleSuffix
  Rename: GetInfoModel -> GetInfo
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+MempoolModel.swift:5 declaration `struct GetInfoModel`

- Violation: DuplicateRoleSuffix
  Rename: GetFeeHistogramModel -> GetFeeHistogram
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+MempoolModel.swift:22 declaration `struct GetFeeHistogramModel`

- Violation: DuplicateRoleSuffix
  Rename: ResultModel -> Result
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+MempoolModel.swift:25 declaration `struct ResultModel`

- Violation: DuplicateRoleSuffix
  Rename: ServerModel -> Server
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:4 declaration `struct ServerModel`

- Violation: DuplicateRoleSuffix
  Rename: PingModel -> Ping
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:5 declaration `struct PingModel`

- Violation: DuplicateRoleSuffix
  Rename: VersionModel -> Version
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:15 declaration `struct VersionModel`

- Violation: DuplicateRoleSuffix
  Rename: FeaturesModel -> Features
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:31 declaration `struct FeaturesModel`

- Violation: DuplicateRoleSuffix
  Rename: HostModel -> Host
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:67 declaration `struct HostModel`

- Violation: DuplicateRoleSuffix
  Rename: ReusablePaymentAddressModel -> ReusablePaymentAddress
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel+ServerModel.swift:81 declaration `struct ReusablePaymentAddressModel`

- Violation: DuplicateRoleSuffix
  Rename: AddressModel -> Address
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:4 declaration `struct AddressModel`

- Violation: DuplicateRoleSuffix
  Rename: GetBalanceModel -> GetBalance
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:5 declaration `struct GetBalanceModel`

- Violation: DuplicateRoleSuffix
  Rename: GetFirstUseModel -> GetFirstUse
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:16 declaration `struct GetFirstUseModel`

- Violation: DuplicateRoleSuffix
  Rename: GetHistoryModel -> GetHistory
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:36 declaration `struct GetHistoryModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:38 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMempoolModel -> GetMempool
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:56 declaration `struct GetMempoolModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:58 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: GetScriptHashModel -> GetScriptHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:76 declaration `struct GetScriptHashModel`

- Violation: DuplicateRoleSuffix
  Rename: ListUnspentModel -> ListUnspent
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:85 declaration `struct ListUnspentModel`

- Violation: DuplicateRoleSuffix
  Rename: ItemModel -> Item
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:88 declaration `struct ItemModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeModel -> Subscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:110 declaration `struct SubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeNotificationModel -> SubscribeNotification
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:128 declaration `struct SubscribeNotificationModel`

- Violation: DuplicateRoleSuffix
  Rename: UnsubscribeModel -> Unsubscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+AddressModel.swift:145 declaration `struct UnsubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockModel -> Block
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+BlockModel.swift:4 declaration `struct BlockModel`

- Violation: DuplicateRoleSuffix
  Rename: HeaderModel -> Header
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+BlockModel.swift:5 declaration `struct HeaderModel`

- Violation: DuplicateRoleSuffix
  Rename: ProofModel -> Proof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+BlockModel.swift:9 declaration `struct ProofModel`

- Violation: DuplicateRoleSuffix
  Rename: HeadersModel -> Headers
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+BlockModel.swift:28 declaration `struct HeadersModel`

- Violation: DuplicateRoleSuffix
  Rename: EstimateFeeModel -> EstimateFee
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+EstimateFeeModel.swift:4 declaration `struct EstimateFeeModel`

- Violation: DuplicateRoleSuffix
  Rename: HeaderModel -> Header
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeaderModel.swift:4 declaration `struct HeaderModel`

- Violation: DuplicateRoleSuffix
  Rename: GetModel -> Get
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeaderModel.swift:5 declaration `struct GetModel`

- Violation: DuplicateRoleSuffix
  Rename: HeadersModel -> Headers
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:4 declaration `struct HeadersModel`

- Violation: DuplicateRoleSuffix
  Rename: GetTipModel -> GetTip
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:5 declaration `struct GetTipModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeModel -> Subscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:16 declaration `struct SubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeNotificationModel -> SubscribeNotification
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:35 declaration `struct SubscribeNotificationModel`

- Violation: DuplicateRoleSuffix
  Rename: BlockModel -> Block
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:39 declaration `struct BlockModel`

- Violation: DuplicateRoleSuffix
  Rename: UnsubscribeModel -> Unsubscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+HeadersModel.swift:58 declaration `struct UnsubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: RelayFeeModel -> RelayFee
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+RelayFeeModel.swift:4 declaration `struct RelayFeeModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptHashModel -> ScriptHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:4 declaration `struct ScriptHashModel`

- Violation: DuplicateRoleSuffix
  Rename: GetBalanceModel -> GetBalance
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:5 declaration `struct GetBalanceModel`

- Violation: DuplicateRoleSuffix
  Rename: GetFirstUseModel -> GetFirstUse
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:16 declaration `struct GetFirstUseModel`

- Violation: DuplicateRoleSuffix
  Rename: GetHistoryModel -> GetHistory
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:36 declaration `struct GetHistoryModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:38 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMempoolModel -> GetMempool
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:56 declaration `struct GetMempoolModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:58 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: ListUnspentModel -> ListUnspent
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:76 declaration `struct ListUnspentModel`

- Violation: DuplicateRoleSuffix
  Rename: ItemModel -> Item
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:79 declaration `struct ItemModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeModel -> Subscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:101 declaration `struct SubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeNotificationModel -> SubscribeNotification
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:120 declaration `struct SubscribeNotificationModel`

- Violation: DuplicateRoleSuffix
  Rename: UnsubscribeModel -> Unsubscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+ScriptHashModel.swift:137 declaration `struct UnsubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: TransactionModel -> Transaction
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+TransactionModel.swift:4 declaration `struct TransactionModel`

- Violation: DuplicateRoleSuffix
  Rename: UTXOModel -> UTXO
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+UTXOModel.swift:4 declaration `struct UTXOModel`

- Violation: DuplicateRoleSuffix
  Rename: GetInfoModel -> GetInfo
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel+UTXOModel.swift:5 declaration `struct GetInfoModel`

- Violation: DuplicateRoleSuffix
  Rename: BroadcastModel -> Broadcast
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+BroadcastModel.swift:4 declaration `struct BroadcastModel`

- Violation: DuplicateRoleSuffix
  Rename: DSProofModel -> DSProof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:4 declaration `struct DSProofModel`

- Violation: DuplicateRoleSuffix
  Rename: GetModel -> Get
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:5 declaration `struct GetModel`

- Violation: DuplicateRoleSuffix
  Rename: OutpointModel -> Outpoint
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:12 declaration `struct OutpointModel`

- Violation: DuplicateRoleSuffix
  Rename: ListModel -> List
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:33 declaration `struct ListModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeModel -> Subscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:43 declaration `struct SubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeNotificationModel -> SubscribeNotification
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:60 declaration `struct SubscribeNotificationModel`

- Violation: DuplicateRoleSuffix
  Rename: UnsubscribeModel -> Unsubscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+DSProofModel.swift:109 declaration `struct UnsubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: GetConfirmedBlockHashModel -> GetConfirmedBlockHash
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetConfirmedBlockHashModel.swift:4 declaration `struct GetConfirmedBlockHashModel`

- Violation: DuplicateRoleSuffix
  Rename: GetHeightModel -> GetHeight
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetHeightModel.swift:4 declaration `struct GetHeightModel`

- Violation: DuplicateRoleSuffix
  Rename: GetMerkleModel -> GetMerkle
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetMerkleModel.swift:4 declaration `struct GetMerkleModel`

- Violation: DuplicateRoleSuffix
  Rename: GetModel -> Get
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetModel.swift:4 declaration `struct GetModel`

- Violation: DuplicateRoleSuffix
  Rename: InputModel -> Input
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetModel.swift:18 declaration `struct InputModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptSigModel -> ScriptSig
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetModel.swift:31 declaration `struct ScriptSigModel`

- Violation: DuplicateRoleSuffix
  Rename: OutputModel -> Output
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetModel.swift:42 declaration `struct OutputModel`

- Violation: DuplicateRoleSuffix
  Rename: ScriptPubKeyModel -> ScriptPubKey
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+GetModel.swift:53 declaration `struct ScriptPubKeyModel`

- Violation: DuplicateRoleSuffix
  Rename: IDFromPosModel -> IDFromPos
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+IDFromPosModel.swift:4 declaration `struct IDFromPosModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeModel -> Subscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+SubscribeModel.swift:4 declaration `struct SubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: SubscribeNotificationModel -> SubscribeNotification
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+SubscribeNotificationModel.swift:4 declaration `struct SubscribeNotificationModel`

- Violation: DuplicateRoleSuffix
  Rename: UnsubscribeModel -> Unsubscribe
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.ResultModel.BlockchainModel.TransactionModel+UnsubscribeModel.swift:4 declaration `struct UnsubscribeModel`

- Violation: DuplicateRoleSuffix
  Rename: OptionsModel -> Options
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/Client/FulcrumNetworkClient+CallModel.swift:10 declaration `struct OptionsModel`

- Violation: DuplicateRoleSuffix
  Rename: TokenModel -> Token
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/Client/FulcrumNetworkClient+CallModel.swift:20 declaration `actor TokenModel`

- Violation: DuplicateRoleSuffix
  Rename: DSProofModel -> DSProof
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/Client/FulcrumNetworkClient~JSONRPCModel.swift:40 declaration `struct DSProofModel`

- Violation: DuplicateRoleSuffix
  Rename: ConnectionStateTrackerModel -> ConnectionStateTracker
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+ConnectionStateTrackerModel.swift:6 declaration `actor ConnectionStateTrackerModel`

- Violation: DuplicateRoleSuffix
  Rename: LifecycleModel -> Lifecycle
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+LifecycleModel.swift:6 declaration `enum LifecycleModel`

- Violation: DuplicateRoleSuffix
  Rename: EventModel -> Event
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+LifecycleModel.swift:10 declaration `enum EventModel`

- Violation: DuplicateRoleSuffix
  Rename: ReconnectorModel -> Reconnector
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+ReconnectorModel.swift:6 declaration `actor ReconnectorModel`

- Violation: DuplicateRoleSuffix
  Rename: ServerModel -> Server
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+ServerModel.swift:6 declaration `struct ServerModel`

- Violation: DuplicateRoleSuffix
  Rename: CodingKeysModel -> CodingKeys
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+ServerModel.swift:7 declaration `enum CodingKeysModel`

- Violation: DuplicateRoleSuffix
  Rename: TLSDescriptorModel -> TLSDescriptor
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/Network/WebSocket/WebSocketModel+TLSDescriptorModel.swift:7 declaration `struct TLSDescriptorModel`

- Violation: DuplicateRoleSuffix
  Rename: RangeModel -> Range
  Reason: Child trailing role token duplicates an ancestor trailing role token; strip repeated child role suffix.
  Scope: Sources/SwiftFulcrum/ProtocolVersionModel+RangeModel.swift:4 declaration `struct RangeModel`

## Exhaustive Appendix B: FileNameMatrix

- Violation: FileNameMatrix
  Rename: FulcrumClient+Configuration+ProtocolNegotiationModel.swift -> see deterministic matrix remediation
  Reason: Filename has multiple "+" segments (unsupported by matrix).
  Scope: Sources/SwiftFulcrum/FulcrumClient+Configuration+ProtocolNegotiationModel.swift:1

- Violation: FileNameMatrix
  Rename: FulcrumClient+Configuration+ProtocolNegotiationModel.swift -> see deterministic matrix remediation
  Reason: Expected exactly one nested type `Configuration+ProtocolNegotiationModel`.
  Scope: Sources/SwiftFulcrum/FulcrumClient+Configuration+ProtocolNegotiationModel.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumClient+Configuration+ProtocolNegotiationModel.swift -> see deterministic matrix remediation
  Reason: Expected top-level `extension FulcrumClient` for `Type+...` pattern.
  Scope: Sources/SwiftFulcrum/FulcrumClient+Configuration+ProtocolNegotiationModel.swift:5

- Violation: FileNameMatrix
  Rename: LogModel~ConsoleAdapter.swift -> see deterministic matrix remediation
  Reason: `Type~Feature.swift` must not declare a primary nested declaration.
  Scope: Sources/SwiftFulcrum/Log/LogModel~ConsoleAdapter.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+Error.swift -> see deterministic matrix remediation
  Reason: Filename has multiple "+" segments (unsupported by matrix).
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:1

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+Error.swift -> see deterministic matrix remediation
  Reason: Expected exactly one nested type `JSONRPCModel+Error`.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+Error.swift -> see deterministic matrix remediation
  Reason: Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+Error.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+ResultModel.swift -> see deterministic matrix remediation
  Reason: Filename has multiple "+" segments (unsupported by matrix).
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:1

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+ResultModel.swift -> see deterministic matrix remediation
  Reason: Expected exactly one nested type `JSONRPCModel+ResultModel`.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+JSONRPCModel+ResultModel.swift -> see deterministic matrix remediation
  Reason: Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+JSONRPCModel+ResultModel.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+ResultModel+Error.swift -> see deterministic matrix remediation
  Reason: Filename has multiple "+" segments (unsupported by matrix).
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:1

- Violation: FileNameMatrix
  Rename: FulcrumResponse+ResultModel+Error.swift -> see deterministic matrix remediation
  Reason: Expected exactly one nested type `ResultModel+Error`.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:5

- Violation: FileNameMatrix
  Rename: FulcrumResponse+ResultModel+Error.swift -> see deterministic matrix remediation
  Reason: Expected top-level `extension FulcrumResponse` for `Type+...` pattern.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse+ResultModel+Error.swift:5

## Exhaustive Appendix C: Top-Level Protocol Filename

- Violation: FileNameMatrix
  Rename: FulcrumClient+Error.swift -> FulcrumErrorConvertibleModel_.swift
  Reason: Top-level protocols must use `Protocol_.swift` naming.
  Scope: Sources/SwiftFulcrum/FulcrumClient+Error.swift:124 declaration `protocol FulcrumErrorConvertibleModel`

## Exhaustive Appendix D: PreferredRoleSuffix Advisories

- Advisory: PreferredRoleSuffix
  Name: CodingKeys
  Suggestion: CodingKeysModel
  Reason: Non-preferred suffix is allowed when descriptive, but preferred-role suffixes are recommended.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+MempoolModel.swift:29

- Advisory: PreferredRoleSuffix
  Name: CodingKeys
  Suggestion: CodingKeysModel
  Reason: Non-preferred suffix is allowed when descriptive, but preferred-role suffixes are recommended.
  Scope: Sources/SwiftFulcrum/Method/Response/FulcrumResponse.JSONRPCModel.ResultModel+ServerModel.swift:40

