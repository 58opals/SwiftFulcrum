import Testing
import SwiftFulcrum

@Suite(.tags(.local))
struct LegacyPublicAPICompatibilityValidator {
    @Test("Legacy and facade aliases resolve to identical underlying types")
    func legacyAliasesResolveToSameTypeIdentity() {
        #expect(ObjectIdentifier(FulcrumClient.self) == ObjectIdentifier(SwiftFulcrum.Client.self))
        #expect(ObjectIdentifier(FulcrumMethodRequest.self) == ObjectIdentifier(SwiftFulcrum.RPC.Method.self))
        #expect(ObjectIdentifier(FulcrumResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.Response.self))
        #expect(ObjectIdentifier(JSONRPCResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.ResponseProtocol.self))
        #expect(ObjectIdentifier(JSONRPCNilAcceptingResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.NilAcceptingResponseProtocol.self))
        #expect(ObjectIdentifier(ProtocolVersionModel.self) == ObjectIdentifier(SwiftFulcrum.ProtocolVersion.self))
        #expect(ObjectIdentifier(FulcrumTransportState.self) == ObjectIdentifier(SwiftFulcrum.Transport.State.self))
        #expect(ObjectIdentifier(FulcrumServerCatalogRepository.self) == ObjectIdentifier(SwiftFulcrum.ServerCatalog.Repository.self))
        #expect(ObjectIdentifier(MetricsClient.self) == ObjectIdentifier(SwiftFulcrum.Metrics.ClientProtocol.self))
        #expect(ObjectIdentifier(LogModel.self) == ObjectIdentifier(SwiftFulcrum.Logging.self))

        #expect(ObjectIdentifier(SwiftFulcrum.FulcrumClient.self) == ObjectIdentifier(SwiftFulcrum.Client.self))
        #expect(ObjectIdentifier(SwiftFulcrum.FulcrumMethodRequest.self) == ObjectIdentifier(SwiftFulcrum.RPC.Method.self))
        #expect(ObjectIdentifier(SwiftFulcrum.FulcrumResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.Response.self))
        #expect(ObjectIdentifier(SwiftFulcrum.JSONRPCResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.ResponseProtocol.self))
        #expect(ObjectIdentifier(SwiftFulcrum.JSONRPCNilAcceptingResponse.self) == ObjectIdentifier(SwiftFulcrum.RPC.NilAcceptingResponseProtocol.self))
        #expect(ObjectIdentifier(SwiftFulcrum.ProtocolVersionModel.self) == ObjectIdentifier(SwiftFulcrum.ProtocolVersion.self))
        #expect(ObjectIdentifier(SwiftFulcrum.FulcrumTransportState.self) == ObjectIdentifier(SwiftFulcrum.Transport.State.self))
        #expect(ObjectIdentifier(SwiftFulcrum.FulcrumServerCatalogRepository.self) == ObjectIdentifier(SwiftFulcrum.ServerCatalog.Repository.self))
        #expect(ObjectIdentifier(SwiftFulcrum.MetricsClient.self) == ObjectIdentifier(SwiftFulcrum.Metrics.ClientProtocol.self))
        #expect(ObjectIdentifier(SwiftFulcrum.LogModel.self) == ObjectIdentifier(SwiftFulcrum.Logging.self))
    }
}
