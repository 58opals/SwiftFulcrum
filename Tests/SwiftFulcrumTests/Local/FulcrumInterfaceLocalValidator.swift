import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumInterfaceLocalValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    @Test("Unary submit rejects subscription methods", .timeLimit(.minutes(1)))
    func rejectSubscriptionMethodsOnSubmit() async throws {
        // No network dependency: submit() should reject before attempting to connect.
        let fulcrum = try await FulcrumClient(url: "ws://example.com")

        let subscriptionMethods: [SwiftFulcrum.FulcrumMethodRequest] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]

        for method in subscriptionMethods {
            do {
                _ = try await fulcrum.submit(
                    method: method,
                    responseType: Response.ResultModel.BlockchainModel.HeadersModel.GetTipModel.self
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
        let fulcrum = try await FulcrumClient(url: "ws://example.com")

        let unaryMethods: [SwiftFulcrum.FulcrumMethodRequest] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]

        for method in unaryMethods {
            do {
                _ = try await fulcrum.subscribe(
                    method: method,
                    initialType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                    notificationType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self
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

    @Test("CancellationModel cancels underlying token synchronously")
    func markCancellationTokenImmediately() async {
        let cancellation = FulcrumClient.CallModel.CancellationModel()

        #expect(await cancellation.isCancelled == false)

        await cancellation.cancel()

        #expect(await cancellation.isCancelled)
    }
}
