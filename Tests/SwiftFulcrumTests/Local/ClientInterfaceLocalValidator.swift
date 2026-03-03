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
        let client = try await FulcrumClient(url: "ws://example.com")

        let subscriptionMethods: [SwiftFulcrum.FulcrumMethodRequest] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]

        for method in subscriptionMethods {
            do {
                _ = try await client.submit(
                    method: method,
                    responseType: FulcrumResponse.ResultModel.Blockchain.Headers.GetTip.self
                )
                Issue.record("submit should reject subscription methods (method: \(method))")
            } catch let error as FulcrumClient.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("submit() cannot be used with subscription methods") == true)
                default:
                    Issue.record("Unexpected FulcrumClient.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-FulcrumClient error: \(error)")
            }
        }
    }

    @Test("subscribe rejects unary methods", .timeLimit(.minutes(1)))
    func rejectUnaryMethodsOnSubscribe() async throws {
        // No network dependency: subscribe() should reject before attempting to connect.
        let client = try await FulcrumClient(url: "ws://example.com")

        let unaryMethods: [SwiftFulcrum.FulcrumMethodRequest] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]

        for method in unaryMethods {
            do {
                _ = try await client.subscribe(
                    method: method,
                    initialType: FulcrumResponse.ResultModel.Blockchain.Headers.Subscribe.self,
                    notificationType: FulcrumResponse.ResultModel.Blockchain.Headers.SubscribeNotification.self
                )
                Issue.record("subscribe() should reject unary methods (method: \(method))")
            } catch let error as FulcrumClient.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("subscribe() requires subscription methods") == true)
                default:
                    Issue.record("Unexpected FulcrumClient.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-FulcrumClient error: \(error)")
            }
        }
    }

    @Test("Cancellation cancels underlying token synchronously")
    func markCancellationTokenImmediately() async {
        let cancellation = FulcrumClient.CallModel.Cancellation()

        #expect(await cancellation.isCancelled == false)

        await cancellation.cancel()

        #expect(await cancellation.isCancelled)
    }
}
