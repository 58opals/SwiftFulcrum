import Foundation
import Testing
@testable import SwiftFulcrum

struct FulcrumInterfaceTests {
    
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"
    
    // MARK: - Unary
    @Test("Submit returns current blockchain tip", .timeLimit(.minutes(1)))
    func submitReturnsBlockchainTip() async throws {
        let url = try await randomFulcrumURL()
        
        try await withRunningFulcrum(url) { fulcrum in
            let response = try await fulcrum.submit(
                method: .blockchain(.headers(.getTip)),
                responseType: Response.Result.Blockchain.Headers.GetTip.self,
                options: .init(timeout: .seconds(30))
            )
            
            guard let tip = response.extractRegularResponse() else {
                Issue.record("submit should return a single response for getTip")
                return
            }
            
            #expect(tip.height > 0)
            #expect(tip.hex.count == 160)
        }
    }
    
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
    
    @Test("Submit starts Fulcrum when idle", .timeLimit(.minutes(1)))
    func submitStartsFulcrumWhenIdle() async throws {
        let url = try await randomFulcrumURL()
        let fulcrum = try await Fulcrum(url: url.absoluteString)
        
        // Avoid calling start() directly to exercise prepareClientForRequests.
        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: Response.Result.Blockchain.Headers.GetTip.self,
            options: .init(timeout: .seconds(30))
        )
        
        guard case .single(_, let tip) = response else {
            Issue.record("Expected unary response for headers.getTip")
            return
        }
        
        #expect(tip.height > 0)
        #expect(await fulcrum.isRunning)
        
        await fulcrum.stop()
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
    
    // MARK: - Subscriptions
    @Test("Cancellation cancels underlying token synchronously")
    func cancellationMarksTokenImmediately() async {
        let cancellation = Fulcrum.Call.Cancellation()
        
        #expect(await cancellation.isCancelled() == false)
        
        await cancellation.cancel()
        
        #expect(await cancellation.isCancelled())
    }
    
    @Test("Subscriptions expose cancellable header streams", .timeLimit(.minutes(1)))
    func subscribeCreatesCancellableHeaderSubscription() async throws {
        let url = try await randomFulcrumURL()
        let cancellation = Fulcrum.Call.Cancellation()
        
        try await withRunningFulcrum(url) { fulcrum in
            let (initial, updates, cancel) = try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30), cancellation: cancellation)
            )
            
            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)
            
            await cancel()
            
            #expect(await cancellation.isCancelled())
            
            let terminated = await streamTerminates(updates, within: .seconds(10))
            #expect(terminated)
        }
    }
    
    @Test("Subscribes to address status and cancels the stream", .timeLimit(.minutes(1)))
    func subscribeStartsAndStopsAddressSubscription() async throws {
        let url = try await randomFulcrumURL()
        
        try await withRunningFulcrum(url) { fulcrum in
            let (initial, updates, cancel) = try await fulcrum.subscribe(
                method: .blockchain(.address(.subscribe(address: Self.testAddress))),
                initialType: Response.Result.Blockchain.Address.Subscribe.self,
                notificationType: Response.Result.Blockchain.Address.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
            
            // nil is valid for never-seen addresses; if present, it should be non-empty.
            #expect(initial.status?.isEmpty != true)
            
            await cancel()
            
            let terminated = await streamTerminates(updates, within: .seconds(10))
            #expect(terminated)
        }
    }
    
    // MARK: - Misc RPC
    @Test("Submit resolves address metadata over live Fulcrum", .timeLimit(.minutes(1)))
    func submitResolvesAddressQueries() async throws {
        let url = try await randomFulcrumURL()
        
        try await withRunningFulcrum(url) { fulcrum in
            let scriptHashResponse = try await fulcrum.submit(
                method: .blockchain(.address(.getScriptHash(address: Self.testAddress))),
                responseType: Response.Result.Blockchain.Address.GetScriptHash.self,
                options: .init(timeout: .seconds(15))
            )
            
            guard case .single(_, let scriptHashResult) = scriptHashResponse else {
                Issue.record("Expected unary response for address.get_scripthash")
                return
            }
            #expect(scriptHashResult.scriptHash.count == 64)
            
            let balanceResponse = try await fulcrum.submit(
                method: .blockchain(.address(.getBalance(address: Self.testAddress, tokenFilter: nil))),
                responseType: Response.Result.Blockchain.Address.GetBalance.self,
                options: .init(timeout: .seconds(15))
            )
            
            guard case .single(_, let balanceResult) = balanceResponse else {
                Issue.record("Expected unary response for address.get_balance")
                return
            }
            
            // Just assert decoding + basic invariants.
            #expect(balanceResult.confirmed >= 0)
            _ = balanceResult.unconfirmed
        }
    }
    
    @Test("Submit surfaces rpc errors for invalid broadcasts", .timeLimit(.minutes(1)))
    func submitPropagatesBroadcastErrors() async throws {
        let url = try await randomFulcrumURL()
        
        try await withRunningFulcrum(url) { fulcrum in
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.transaction(.broadcast(rawTransaction: "00"))),
                    responseType: Response.Result.Blockchain.Transaction.Broadcast.self,
                    options: .init(timeout: .seconds(15))
                )
                Issue.record("Expected broadcast to fail for invalid raw transaction")
            } catch let error as Fulcrum.Error {
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
