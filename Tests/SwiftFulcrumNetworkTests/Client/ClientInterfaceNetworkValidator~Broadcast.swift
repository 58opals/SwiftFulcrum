// ClientInterfaceNetworkValidator~Broadcast.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidator.ClientInterfaceNetworkValidator {
    @Test(
        "Request surfaces rpc errors for invalid broadcasts",
        .timeLimit(.minutes(1))
    )
    func requestAndPropagateBroadcastErrors() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            do {
                _ = try await client.request(
                    method: .blockchain(.transaction(.broadcast(rawTransaction: "00"))),
                    responseType: SwiftFulcrum.Response.Blockchain.Transaction.Broadcast.self,
                    options: .init(timeout: .seconds(15))
                )
                Issue.record("Expected broadcast to fail for invalid raw transaction")
            } catch let error as SwiftFulcrum.Client.Error {
                switch error {
                case .rpc(let rpcError):
                    #expect(!rpcError.message.isEmpty)
                default:
                    Issue.record("Unexpected error type: \(error)")
                }
            }
        }
    }
}
