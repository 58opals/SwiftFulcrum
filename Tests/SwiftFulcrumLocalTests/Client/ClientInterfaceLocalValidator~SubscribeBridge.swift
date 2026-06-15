// ClientInterfaceLocalValidator~SubscribeBridge.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    @Test("Internal subscribe bridge rejects unary methods", .timeLimit(.minutes(1)))
    func rejectUnaryMethodsOnSubscribe() async throws {
        // No network dependency: the internal RPC bridge should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(connectingTo: try #require(URL(string: "ws://example.com")))

        let unaryMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]

        for method in unaryMethods {
            do {
                _ = try await client.subscribe(
                    method: method,
                    initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self
                )
                Issue.record("subscribe() should reject unary methods (method: \(method))")
            } catch let error as SwiftFulcrum.Client.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("subscribe() requires subscription methods") == true)
                default:
                    Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
            }
        }
    }

    @Test("Cancellation cancels underlying token synchronously")
    func markCancellationTokenImmediately() async {
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        #expect(await cancellation.isCancelled == false)

        await cancellation.cancel()

        #expect(await cancellation.isCancelled)
    }
}
