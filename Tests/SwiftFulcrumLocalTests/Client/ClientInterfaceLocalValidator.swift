// ClientInterfaceLocalValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientInterfaceLocalValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    @Test("Unary submit rejects subscription methods", .timeLimit(.minutes(1)))
    func rejectSubscriptionMethodsOnSubmit() async throws {
        // No network dependency: submit() should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(url: "ws://example.com")

        let subscriptionMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]

        for method in subscriptionMethods {
            do {
                _ = try await client.submit(
                    method: method,
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
                )
                Issue.record("submit should reject subscription methods (method: \(method))")
            } catch let error as SwiftFulcrum.Client.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("submit() cannot be used with subscription methods") == true)
                default:
                    Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
            }
        }
    }

    @Test("subscribe rejects unary methods", .timeLimit(.minutes(1)))
    func rejectUnaryMethodsOnSubscribe() async throws {
        // No network dependency: subscribe() should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(url: "ws://example.com")

        let unaryMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]

        for method in unaryMethods {
            do {
                _ = try await client.subscribe(
                    method: method,
                    initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self
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
