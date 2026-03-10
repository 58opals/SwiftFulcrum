// PublicAPIFacadeContractValidator.swift

import Foundation
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

        let responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.Type =
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
        _ = responseType

        let protocolVersionType: SwiftFulcrum.ProtocolVersion.Type = SwiftFulcrum.ProtocolVersion.self
        _ = protocolVersionType

        let transportStateType: SwiftFulcrum.Transport.State.Type = SwiftFulcrum.Transport.State.self
        _ = transportStateType

        let serverCatalogRepositoryType: SwiftFulcrum.ServerCatalog.Repository.Type = SwiftFulcrum.ServerCatalog.Repository.self
        _ = serverCatalogRepositoryType

        _ = SwiftFulcrum.Metrics.MetricsClient.self

        let loggingType: SwiftFulcrum.Logging.Type = SwiftFulcrum.Logging.self
        _ = loggingType

        let unaryRequest: @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip = { client in
            try await client.request(
                method: .blockchain(.headers(.getTip)),
                responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
            )
        }
        _ = unaryRequest
    }

    @Test("Facade response protocol aliases compile")
    func facadeResponseAdaptersCompile() throws {
        _ = try DummyResponse(fromRPC: DummyJSONRPC())
        _ = DummyNilAcceptingResponse(nilValue: ())
    }

    @Test(
        "Generated public symbol graph excludes removed wrapper types",
        .enabled(if: Self.hasGeneratedPublicSymbolGraph, "Run `swift package dump-symbol-graph` to enable symbol-graph facade validation.")
    )
    func generatedPublicSymbolGraphExcludesRemovedWrapperTypes() throws {
        let symbolGraph = try loadGeneratedPublicSymbolGraph()
        let publicSymbols = Set(symbolGraph.symbols.map { $0.pathComponents.joined(separator: ".") })

        let requiredSymbols = [
            "SwiftFulcrum.Client",
            "SwiftFulcrum.RPC.Method",
            "SwiftFulcrum.RPC.Response.Result",
            "SwiftFulcrum.ProtocolVersion",
            "SwiftFulcrum.Transport.State",
            "SwiftFulcrum.ServerCatalog.Repository",
            "SwiftFulcrum.Metrics",
            "SwiftFulcrum.Logging",
            "SwiftFulcrum.RPC.JSONRPCResponseAdapter",
            "SwiftFulcrum.RPC.NilAcceptingResponseAdapter"
        ]

        for symbol in requiredSymbols {
            #expect(publicSymbols.contains(symbol))
        }

        let hiddenSymbols = [
            "SwiftFulcrum.Client.RPCResponse",
            "SwiftFulcrum.Client.RPCSingleResponse",
            "SwiftFulcrum.Client.RPCStreamResponse",
            "SwiftFulcrum.RPC.Response.Regular",
            "SwiftFulcrum.RPC.Response.Subscription",
            "SwiftFulcrum.RPC.Response.Error",
            "SwiftFulcrum.RPC.Response.Kind",
            "SwiftFulcrum.RPC.Response.Identifier",
            "SwiftFulcrum.RPC.Response.JSONRPC.Generic"
        ]

        for symbol in hiddenSymbols {
            #expect(publicSymbols.contains(symbol) == false)
        }
    }
}

private struct DummyJSONRPC: Decodable {}

private struct DummyResponse: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
    typealias JSONRPC = DummyJSONRPC

    init(fromRPC jsonrpc: DummyJSONRPC) throws {}
}

private struct DummyNilAcceptingResponse: SwiftFulcrum.RPC.NilAcceptingResponseAdapter {
    typealias JSONRPC = DummyJSONRPC

    init(fromRPC jsonrpc: DummyJSONRPC) throws {}
    init(nilValue: ()) {}
}

private extension PublicAPIFacadeContractValidator {
    static var hasGeneratedPublicSymbolGraph: Bool {
        (try? locateGeneratedPublicSymbolGraph()) != nil
    }

    func loadGeneratedPublicSymbolGraph() throws -> SymbolGraphModel {
        let symbolGraphURL = try Self.locateGeneratedPublicSymbolGraph()
        let data = try Data(contentsOf: symbolGraphURL)
        return try JSONDecoder().decode(SymbolGraphModel.self, from: data)
    }

    static func locateGeneratedPublicSymbolGraph() throws -> URL {
        let buildDirectory = packageRootURL().appending(path: ".build")
        guard let enumerator = FileManager.default.enumerator(
            at: buildDirectory,
            includingPropertiesForKeys: nil
        ) else {
            throw SupportError.missingGeneratedSymbolGraph(buildDirectory.path())
        }

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "SwiftFulcrum.symbols.json" {
                return fileURL
            }
        }

        throw SupportError.missingGeneratedSymbolGraph(buildDirectory.path())
    }

    static func packageRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    struct SymbolGraphModel: Decodable {
        let symbols: [SymbolModel]
    }

    struct SymbolModel: Decodable {
        let pathComponents: [String]
    }

    enum SupportError: Swift.Error {
        case missingGeneratedSymbolGraph(String)
    }
}
