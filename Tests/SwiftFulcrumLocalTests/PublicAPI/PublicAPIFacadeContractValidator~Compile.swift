// PublicAPIFacadeContractValidator~Compile.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrum

extension PublicAPIFacadeContractValidator {
    @Test("Public facade symbols compile")
    func compilePublicFacadeSymbols() {
        let clientType: SwiftFulcrum.Client.Type = SwiftFulcrum.Client.self
        _ = clientType

        let configurationType: SwiftFulcrum.Client.Configuration.Type = SwiftFulcrum.Client.Configuration.self
        _ = configurationType

        let network: SwiftFulcrum.Client.Configuration.Network = .chipnet
        _ = network

        let callOptionsType: SwiftFulcrum.Client.Call.Options.Type = SwiftFulcrum.Client.Call.Options.self
        _ = callOptionsType

        let subscriptionBufferPolicyType: SwiftFulcrum.Client.SubscriptionBufferPolicy.Type =
            SwiftFulcrum.Client.SubscriptionBufferPolicy.self
        _ = subscriptionBufferPolicyType

        let subscriptionType: SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        >.Type = SwiftFulcrum.Client.Subscription.self
        _ = subscriptionType

        let subscriptionUpdatesType: SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        >.Updates.Type = SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        >.Updates.self
        _ = subscriptionUpdatesType

        let diagnosticsCategory: OpalDiagnostics.Category = OpalDiagnostics.Category.fulcrum
        _ = diagnosticsCategory

        let diagnosticsSubcategory: OpalDiagnostics.Category = OpalDiagnostics.Category.swiftFulcrumJSONRPC
        _ = diagnosticsSubcategory

        let diagnosticsEvent: OpalDiagnostics.Event = OpalDiagnostics.Event.swiftFulcrumClientCallBegin
        _ = diagnosticsEvent

        let diagnosticsErrorCodeField = OpalDiagnostics.Field.errorCode(
            OpalDiagnostics.ErrorCode(rawValue: "jsonrpc.decode_failed")
        )
        _ = diagnosticsErrorCodeField

        let connectionStateType: SwiftFulcrum.Client.ConnectionState.Type = SwiftFulcrum.Client.ConnectionState.self
        _ = connectionStateType

        let clientErrorType: SwiftFulcrum.Client.Error.Type = SwiftFulcrum.Client.Error.self
        _ = clientErrorType

        let apiType: SwiftFulcrum.API.Type = SwiftFulcrum.API.self
        _ = apiType

        let endpoint = SwiftFulcrum.API.blockchain.headers.tip
        _ = endpoint

        let rpaHistoryEndpoint = SwiftFulcrum.API.blockchain.rpa.history(
            prefix: "ab",
            fromHeight: 825_000
        )
        _ = rpaHistoryEndpoint

        let rpaMempoolEndpoint = SwiftFulcrum.API.blockchain.rpa.mempool(
            prefix: "ab"
        )
        _ = rpaMempoolEndpoint

        let responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.Type =
            SwiftFulcrum.Response.Blockchain.Headers.Tip.self
        _ = responseType

        let rpaHistoryResponseType:
            SwiftFulcrum.Response.Blockchain.RPA.History.Type =
                SwiftFulcrum.Response.Blockchain.RPA.History.self
        _ = rpaHistoryResponseType

        let rpaMempoolResponseType:
            SwiftFulcrum.Response.Blockchain.RPA.Mempool.Type =
                SwiftFulcrum.Response.Blockchain.RPA.Mempool.self
        _ = rpaMempoolResponseType

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

        let configuration = SwiftFulcrum.Client.Configuration(network: .chipnet)
        _ = configuration

        let callOptions = SwiftFulcrum.Client.Call.Options(
            timeout: .seconds(10),
            subscriptionBufferPolicy: .bounded(capacity: 256)
        )
        _ = callOptions

        let unboundedSubscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy = .unbounded
        _ = unboundedSubscriptionBufferPolicy

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

        let rpaHistoryRequest:
            @Sendable (SwiftFulcrum.Client) async throws
                -> SwiftFulcrum.Response.Blockchain.RPA.History = { client in
                    try await client.request(
                        SwiftFulcrum.API.blockchain.rpa.history(
                            prefix: "ab",
                            fromHeight: 825_000
                        )
                    )
                }
        _ = rpaHistoryRequest

        let verboseTransactionRequest:
            @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.Response.Blockchain.Transaction.Verbose = { client in
                try await client.request(SwiftFulcrum.API.blockchain.transaction.verbose(transactionHash: "00"))
            }
        _ = verboseTransactionRequest
    }
}
