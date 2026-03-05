// SwiftFulcrum+LegacyBaseAlias.swift

// Stable bridge aliases prevent recursive lookup when nested compatibility
// aliases reuse legacy names under the SwiftFulcrum namespace root.
public typealias SwiftFulcrumLegacyClient = FulcrumClient
public typealias SwiftFulcrumLegacyMethod = FulcrumMethodRequest
public typealias SwiftFulcrumLegacyResponse = FulcrumResponse
public typealias SwiftFulcrumLegacyResponseProtocol = JSONRPCResponse
public typealias SwiftFulcrumLegacyNilAcceptingResponseProtocol = JSONRPCNilAcceptingResponse
public typealias SwiftFulcrumLegacyProtocolVersion = ProtocolVersionModel
public typealias SwiftFulcrumLegacyTransportState = FulcrumTransportState
public typealias SwiftFulcrumLegacyServerCatalogRepository = FulcrumServerCatalogRepository
public typealias SwiftFulcrumLegacyMetricsClientProtocol = MetricsClient
public typealias SwiftFulcrumLegacyLogging = LogModel
