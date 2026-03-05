// SwiftFulcrum+LegacyCompatibility.swift

public extension SwiftFulcrum {
    @available(*, deprecated, message: "Use SwiftFulcrum.Client instead.")
    typealias FulcrumClient = SwiftFulcrumLegacyClient

    @available(*, deprecated, message: "Use SwiftFulcrum.RPC.Method instead.")
    typealias FulcrumMethodRequest = SwiftFulcrumLegacyMethod

    @available(*, deprecated, message: "Use SwiftFulcrum.RPC.Response instead.")
    typealias FulcrumResponse = SwiftFulcrumLegacyResponse

    @available(*, deprecated, message: "Use SwiftFulcrum.RPC.ResponseProtocol instead.")
    typealias JSONRPCResponse = SwiftFulcrumLegacyResponseProtocol

    @available(*, deprecated, message: "Use SwiftFulcrum.RPC.NilAcceptingResponseProtocol instead.")
    typealias JSONRPCNilAcceptingResponse = SwiftFulcrumLegacyNilAcceptingResponseProtocol

    @available(*, deprecated, message: "Use SwiftFulcrum.ProtocolVersion instead.")
    typealias ProtocolVersionModel = SwiftFulcrumLegacyProtocolVersion

    @available(*, deprecated, message: "Use SwiftFulcrum.Transport.State instead.")
    typealias FulcrumTransportState = SwiftFulcrumLegacyTransportState

    @available(*, deprecated, message: "Use SwiftFulcrum.ServerCatalog.Repository instead.")
    typealias FulcrumServerCatalogRepository = SwiftFulcrumLegacyServerCatalogRepository

    @available(*, deprecated, message: "Use SwiftFulcrum.Metrics.ClientProtocol instead.")
    typealias MetricsClient = SwiftFulcrumLegacyMetricsClientProtocol

    @available(*, deprecated, message: "Use SwiftFulcrum.Logging instead.")
    typealias LogModel = SwiftFulcrumLegacyLogging
}
