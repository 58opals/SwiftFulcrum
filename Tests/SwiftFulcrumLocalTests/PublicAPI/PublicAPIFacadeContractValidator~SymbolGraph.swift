// PublicAPIFacadeContractValidator~SymbolGraph.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrum

extension PublicAPIFacadeContractValidator {
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

extension PublicAPIFacadeContractValidator {
    static var hasGeneratedPublicSymbolGraph: Bool {
        guard let symbolGraphURL = try? locateGeneratedPublicSymbolGraph(),
              let symbolGraphModificationDate = try? readModificationDate(for: symbolGraphURL),
              let latestSourceModificationDate = try? findLatestPublicSurfaceModificationDate() else {
            return false
        }

        return symbolGraphModificationDate >= latestSourceModificationDate
    }
}
