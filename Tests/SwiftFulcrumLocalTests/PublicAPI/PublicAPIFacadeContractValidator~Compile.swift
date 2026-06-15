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
}
