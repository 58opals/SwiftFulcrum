// PublicAPIFacadeContractValidator.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrum

@Suite(.tags(.local))
struct PublicAPIFacadeContractValidator {
    @Test("Public facade symbols compile")
    func compilePublicFacadeSymbols() {
        let clientType: SwiftFulcrum.Client.Type = SwiftFulcrum.Client.self
        _ = clientType

        let configurationType: SwiftFulcrum.Client.Configuration.Type = SwiftFulcrum.Client.Configuration.self
        _ = configurationType

        let network: SwiftFulcrum.Client.Configuration.Network = .chipnet
        _ = network

        let tlsDescriptorType: SwiftFulcrum.Client.Configuration.TLSDescriptor.Type =
            SwiftFulcrum.Client.Configuration.TLSDescriptor.self
        _ = tlsDescriptorType

        let callOptionsType: SwiftFulcrum.Client.Call.Options.Type = SwiftFulcrum.Client.Call.Options.self
        _ = callOptionsType

        let subscriptionType: SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        >.Type = SwiftFulcrum.Client.Subscription.self
        _ = subscriptionType

        let diagnosticsCategory: OpalDiagnostics.Category = OpalDiagnostics.Category.fulcrum
        _ = diagnosticsCategory

        let diagnosticsSubcategory: OpalDiagnostics.Category = OpalDiagnostics.Category.swiftFulcrumJSONRPC
        _ = diagnosticsSubcategory

        let diagnosticsEvent: OpalDiagnostics.Event = OpalDiagnostics.Event.swiftFulcrumClientCallBegin
        _ = diagnosticsEvent

        let diagnosticsFieldName = OpalDiagnostics.Field.swiftFulcrumErrorCodeName
        _ = diagnosticsFieldName

        let diagnosticsErrorCode = "jsonrpc.decode_failed"
        _ = diagnosticsErrorCode

        let connectionStateType: SwiftFulcrum.Client.ConnectionState.Type = SwiftFulcrum.Client.ConnectionState.self
        _ = connectionStateType

        let clientErrorType: SwiftFulcrum.Client.Error.Type = SwiftFulcrum.Client.Error.self
        _ = clientErrorType

        let apiType: SwiftFulcrum.API.Type = SwiftFulcrum.API.self
        _ = apiType

        let endpoint = SwiftFulcrum.API.blockchain.headers.tip
        _ = endpoint

        let responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.Type =
            SwiftFulcrum.Response.Blockchain.Headers.Tip.self
        _ = responseType

        let tokenFilter: SwiftFulcrum.CashTokens.TokenFilter = .include
        _ = tokenFilter

        let tokenDataType: SwiftFulcrum.CashTokens.TokenData.Type = SwiftFulcrum.CashTokens.TokenData.self
        _ = tokenDataType

        let tokenNFTType: SwiftFulcrum.CashTokens.TokenData.NFT.Type = SwiftFulcrum.CashTokens.TokenData.NFT.self
        _ = tokenNFTType

        let nft = SwiftFulcrum.CashTokens.TokenData.NFT(capability: .mutable, commitment: "abcd")
        let tokenData = SwiftFulcrum.CashTokens.TokenData(amount: "42", category: "token-category", nft: nft)
        _ = tokenData

        let protocolVersionType: SwiftFulcrum.ProtocolVersion.Type = SwiftFulcrum.ProtocolVersion.self
        _ = protocolVersionType

        let transportStateType: SwiftFulcrum.Transport.State.Type = SwiftFulcrum.Transport.State.self
        _ = transportStateType

        let serverCatalogRepositoryType: SwiftFulcrum.ServerCatalog.Repository.Type = SwiftFulcrum.ServerCatalog.Repository.self
        _ = serverCatalogRepositoryType

        let tlsDescriptor = SwiftFulcrum.Client.Configuration.TLSDescriptor()
        _ = tlsDescriptor

        let configuration = SwiftFulcrum.Client.Configuration(tlsDescriptor: tlsDescriptor)
        _ = configuration

        let unaryRequest: @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.Response.Blockchain.Headers.Tip = { client in
            try await client.request(SwiftFulcrum.API.blockchain.headers.tip)
        }
        _ = unaryRequest

        let streamingRequest: @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        > = { client in
            try await client.subscribe(SwiftFulcrum.API.blockchain.headers.subscribe)
        }
        _ = streamingRequest

        let rawTransactionRequest: @Sendable (SwiftFulcrum.Client) async throws -> String = { client in
            try await client.request(SwiftFulcrum.API.blockchain.transaction.raw(transactionHash: "00"))
        }
        _ = rawTransactionRequest

        let verboseTransactionRequest:
            @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.Response.Blockchain.Transaction.Verbose = { client in
                try await client.request(SwiftFulcrum.API.blockchain.transaction.verbose(transactionHash: "00"))
            }
        _ = verboseTransactionRequest
    }

    @Test(
        "Generated public symbol graph excludes removed wrapper types",
        .enabled(if: Self.hasGeneratedPublicSymbolGraph, "Run `swift package dump-symbol-graph` to enable symbol-graph facade validation.")
    )
    func excludeRemovedWrapperTypesFromGeneratedPublicSymbolGraph() throws {
        let symbolGraph = try loadGeneratedPublicSymbolGraph()
        let publicSymbols = Set(symbolGraph.symbols.map { $0.pathComponents.joined(separator: ".") })

        let requiredSymbols = [
            "SwiftFulcrum.Client",
            "SwiftFulcrum.Client.Configuration",
            "SwiftFulcrum.Client.Configuration.TLSDescriptor",
            "SwiftFulcrum.Client.Configuration.TLSDescriptor.init(options:)",
            "SwiftFulcrum.Client.Configuration.init(tlsDescriptor:reconnect:connectionTimeout:maximumMessageSize:bootstrapServers:serverCatalogLoader:network:protocolNegotiation:)",
            "SwiftFulcrum.Client.Call.Options",
            "SwiftFulcrum.Client.Subscription",
            "SwiftFulcrum.Client.ConnectionState",
            "SwiftFulcrum.Client.Error",
            "SwiftFulcrum.API",
            "SwiftFulcrum.API.Request",
            "SwiftFulcrum.API.Subscription",
            "SwiftFulcrum.API.Blockchain.Headers.tip",
            "SwiftFulcrum.API.Blockchain.Transaction.raw(transactionHash:)",
            "SwiftFulcrum.API.Blockchain.Transaction.verbose(transactionHash:)",
            "SwiftFulcrum.Response",
            "SwiftFulcrum.Response.Blockchain.Headers.Tip",
            "SwiftFulcrum.Response.Blockchain.Transaction.Verbose",
            "SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup",
            "SwiftFulcrum.Response.Mempool.Info",
            "SwiftFulcrum.CashTokens",
            "SwiftFulcrum.CashTokens.TokenFilter",
            "SwiftFulcrum.CashTokens.TokenData",
            "SwiftFulcrum.CashTokens.TokenData.NFT",
            "SwiftFulcrum.ProtocolVersion",
            "SwiftFulcrum.Transport.State",
            "SwiftFulcrum.ServerCatalog.Repository"
        ]

        for symbol in requiredSymbols {
            #expect(publicSymbols.contains(symbol))
        }

        let hiddenSymbols = [
            "SwiftFulcrum.Client.RPCResponse",
            "SwiftFulcrum.Client.RPCSingleResponse",
            "SwiftFulcrum.Client.RPCStreamResponse",
            "SwiftFulcrum.Client.Diagnostics",
            "SwiftFulcrum.Client.Diagnostics.Snapshot",
            "SwiftFulcrum.Client.Diagnostics.Subscription",
            "SwiftFulcrum.ClientDiagnosticsTransportState",
            "SwiftFulcrum.Client.makeDiagnosticsSnapshot()",
            "SwiftFulcrum.Client.listSubscriptions()",
            "SwiftFulcrum.RPC.Response.Regular",
            "SwiftFulcrum.RPC.Response.Subscription",
            "SwiftFulcrum.RPC.Response.Error",
            "SwiftFulcrum.RPC.Response.Kind",
            "SwiftFulcrum.RPC.Response.Identifier",
            "SwiftFulcrum.RPC.JSONRPCResponseAdapter",
            "SwiftFulcrum.RPC.NilAcceptingResponseAdapter",
            "SwiftFulcrum.RPC",
            "SwiftFulcrum.RPC.Response",
            "SwiftFulcrum.RPC.Response.JSONRPC",
            "SwiftFulcrum.RPC.Response.JSONRPC.Generic",
            "SwiftFulcrum.RPC.Response.JSONRPC.Result",
            "SwiftFulcrum.RPC.Method",
            "SwiftFulcrum.RPC.Response.Result",
            "SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON",
            "SwiftFulcrum.Client.request(method:responseType:options:)",
            "SwiftFulcrum.Client.subscribe(method:initial:notifications:options:)",
            "SwiftFulcrum.Client.Configuration.urlSession",
            "SwiftFulcrum.Client.Configuration.TLSDescriptor.delegate",
            "SwiftFulcrum.Client.Configuration.TLSDescriptor.init(options:delegate:)",
            "SwiftFulcrum.Client.Configuration.init(tlsDescriptor:reconnect:metrics:logger:isLoggingEnabled:connectionTimeout:maximumMessageSize:bootstrapServers:serverCatalogLoader:network:protocolNegotiation:)",
            "SwiftFulcrum.Client.Configuration.init(tlsDescriptor:reconnect:metrics:logger:isLoggingEnabled:urlSession:connectionTimeout:maximumMessageSize:bootstrapServers:serverCatalogLoader:network:protocolNegotiation:)",
            "SwiftFulcrum.Client.Configuration.metrics",
            "SwiftFulcrum.Client.Configuration.logger",
            "SwiftFulcrum.Client.Configuration.isLoggingEnabled",
            "SwiftFulcrum.Metrics",
            "SwiftFulcrum.Logging",
            "SwiftFulcrum.Metrics.MetricsClient",
            "SwiftFulcrum.Logging.Adapter",
            "SwiftFulcrum.API.Request.server",
            "SwiftFulcrum.API.Request.blockchain",
            "SwiftFulcrum.API.Request.mempool",
            "SwiftFulcrum.API.Subscription.server",
            "SwiftFulcrum.API.Subscription.blockchain",
            "SwiftFulcrum.API.Subscription.mempool",
            "SwiftFulcrum.API.Blockchain.Headers.getTip",
            "SwiftFulcrum.API.Blockchain.Transaction.get(transactionHash:)",
            "SwiftFulcrum.API.Blockchain.Transaction.getVerbose(transactionHash:)",
            "SwiftFulcrum.Response.Mempool.GetInfo",
            "SwiftFulcrum.Response.Mempool.GetFeeHistogram",
            "SwiftFulcrum.Response.Blockchain.Headers.GetTip",
            "SwiftFulcrum.Response.Blockchain.Header.Get",
            "SwiftFulcrum.Response.Blockchain.Address.GetBalance",
            "SwiftFulcrum.Response.Blockchain.Address.GetFirstUse",
            "SwiftFulcrum.Response.Blockchain.Address.GetHistory",
            "SwiftFulcrum.Response.Blockchain.Address.GetMempool",
            "SwiftFulcrum.Response.Blockchain.Address.GetScriptHash",
            "SwiftFulcrum.Response.Blockchain.ScriptHash.GetBalance",
            "SwiftFulcrum.Response.Blockchain.ScriptHash.GetFirstUse",
            "SwiftFulcrum.Response.Blockchain.ScriptHash.GetHistory",
            "SwiftFulcrum.Response.Blockchain.ScriptHash.GetMempool",
            "SwiftFulcrum.Response.Blockchain.UTXO.GetInfo",
            "SwiftFulcrum.Response.Blockchain.Transaction.Get",
            "SwiftFulcrum.Response.Blockchain.Transaction.GetConfirmedBlockHash",
            "SwiftFulcrum.Response.Blockchain.Transaction.GetHeight",
            "SwiftFulcrum.Response.Blockchain.Transaction.GetMerkle",
            "SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Get"
        ]

        for symbol in hiddenSymbols {
            #expect(publicSymbols.contains(symbol) == false)
        }
    }
}

private extension PublicAPIFacadeContractValidator {
    static var hasGeneratedPublicSymbolGraph: Bool {
        guard let symbolGraphURL = try? locateGeneratedPublicSymbolGraph(),
              let symbolGraphModificationDate = try? modificationDate(for: symbolGraphURL),
              let latestSourceModificationDate = try? latestPublicSurfaceModificationDate() else {
            return false
        }

        return symbolGraphModificationDate >= latestSourceModificationDate
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

    static func latestPublicSurfaceModificationDate() throws -> Date {
        let packageRoot = packageRootURL()
        let publicSurfaceRoots = [
            packageRoot.appending(path: "Package.swift"),
            packageRoot.appending(path: "Sources")
        ]

        return try publicSurfaceRoots.reduce(.distantPast) { latestDate, rootURL in
            var isDirectory = ObjCBool(false)
            FileManager.default.fileExists(atPath: rootURL.path(), isDirectory: &isDirectory)
            if isDirectory.boolValue {
                return try max(latestDate, latestModificationDate(in: rootURL))
            }
            return try max(latestDate, modificationDate(for: rootURL))
        }
    }

    static func latestModificationDate(in directoryURL: URL) throws -> Date {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey]
        ) else {
            return .distantPast
        }

        var latestDate = Date.distantPast
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
            guard values.isRegularFile == true else { continue }
            latestDate = max(latestDate, values.contentModificationDate ?? .distantPast)
        }

        return latestDate
    }

    static func modificationDate(for fileURL: URL) throws -> Date {
        let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
        return values.contentModificationDate ?? .distantPast
    }

}
