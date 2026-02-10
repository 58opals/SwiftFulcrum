import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumInterfaceLocalTests {
    
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"
    
    @Test("Unary submit rejects subscription methods", .timeLimit(.minutes(1)))
    func submitRejectsSubscriptionMethods() async throws {
        // No network dependency: submit() should reject before attempting to connect.
        let fulcrum = try await Fulcrum(url: "ws://example.com")
        
        let subscriptionMethods: [SwiftFulcrum.Method] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]
        
        for method in subscriptionMethods {
            do {
                _ = try await fulcrum.submit(
                    method: method,
                    responseType: Response.Result.Blockchain.Headers.GetTip.self
                )
                Issue.record("submit should reject subscription methods (method: \(method))")
            } catch let error as Fulcrum.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("submit() cannot be used with subscription methods") == true)
                default:
                    Issue.record("Unexpected Fulcrum.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-Fulcrum error: \(error)")
            }
        }
    }
    
    @Test("subscribe rejects unary methods", .timeLimit(.minutes(1)))
    func subscribeRejectsUnaryMethods() async throws {
        // No network dependency: subscribe() should reject before attempting to connect.
        let fulcrum = try await Fulcrum(url: "ws://example.com")
        
        let unaryMethods: [SwiftFulcrum.Method] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]
        
        for method in unaryMethods {
            do {
                _ = try await fulcrum.subscribe(
                    method: method,
                    initialType: Response.Result.Blockchain.Headers.Subscribe.self,
                    notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
                )
                Issue.record("subscribe() should reject unary methods (method: \(method))")
            } catch let error as Fulcrum.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("subscribe() requires subscription methods") == true)
                default:
                    Issue.record("Unexpected Fulcrum.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-Fulcrum error: \(error)")
            }
        }
    }
    
    @Test("Cancellation cancels underlying token synchronously")
    func cancellationMarksTokenImmediately() async {
        let cancellation = Fulcrum.Call.Cancellation()
        
        #expect(await cancellation.isCancelled == false)
        
        await cancellation.cancel()
        
        #expect(await cancellation.isCancelled)
    }
}
