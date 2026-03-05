import Testing
import SwiftFulcrum

@Suite(.tags(.local))
struct PublicAPIFacadeContractValidator {
    @Test("Facade namespace aliases compile")
    func facadeAliasesCompile() {
        let clientType: SwiftFulcrum.Client.Type = SwiftFulcrum.Client.self
        _ = clientType

        let method: SwiftFulcrum.RPC.Method = .blockchain(.headers(.getTip))
        _ = method

        let responseType: SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.GetTip.Type =
            SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.GetTip.self
        _ = responseType

        let protocolVersionType: SwiftFulcrum.ProtocolVersion.Type = SwiftFulcrum.ProtocolVersion.self
        _ = protocolVersionType

        let transportStateType: SwiftFulcrum.Transport.State.Type = SwiftFulcrum.Transport.State.self
        _ = transportStateType

        let serverCatalogRepositoryType: SwiftFulcrum.ServerCatalog.Repository.Type = SwiftFulcrum.ServerCatalog.Repository.self
        _ = serverCatalogRepositoryType

        _ = SwiftFulcrum.Metrics.ClientProtocol.self

        let loggingType: SwiftFulcrum.Logging.Type = SwiftFulcrum.Logging.self
        _ = loggingType
    }

    @Test("Facade response protocol aliases compile")
    func facadeResponseProtocolsCompile() throws {
        _ = try DummyResponse(fromRPC: DummyJSONRPCModel())
        _ = DummyNilAcceptingResponse(nilValue: ())
    }
}

private struct DummyJSONRPCModel: Decodable {}

private struct DummyResponse: SwiftFulcrum.RPC.ResponseProtocol {
    typealias JSONRPCModel = DummyJSONRPCModel

    init(fromRPC jsonrpc: DummyJSONRPCModel) throws {}
}

private struct DummyNilAcceptingResponse: SwiftFulcrum.RPC.NilAcceptingResponseProtocol {
    typealias JSONRPCModel = DummyJSONRPCModel

    init(fromRPC jsonrpc: DummyJSONRPCModel) throws {}
    init(nilValue: ()) {}
}
