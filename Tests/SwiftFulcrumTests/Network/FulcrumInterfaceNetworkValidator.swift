import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.network))
struct FulcrumInterfaceNetworkValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    // MARK: - Unary
    @Test("Submit returns current blockchain tip", .timeLimit(.minutes(1)))
    func submitAndReturnBlockchainTip() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
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

    @Test("Submit starts Fulcrum when idle", .timeLimit(.minutes(1)))
    func submitAndStartFulcrumWhenIdle() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()
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

    // MARK: - Subscriptions
    @Test("Subscriptions expose cancellable header streams", .timeLimit(.minutes(1)))
    func subscribeAndCreateCancellableHeaderSubscription() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()
        let cancellation = Fulcrum.Call.Cancellation()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
            let (initial, updates, cancel) = try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30), cancellation: cancellation)
            )

            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)

            await cancel()

            #expect(await cancellation.isCancelled)

            let terminated = await NetworkTestClient.detectStreamTermination(
                updates,
                within: .seconds(10)
            )
            #expect(terminated)
        }
    }

    @Test("Subscribes to address status and cancels the stream", .timeLimit(.minutes(1)))
    func subscribeAndStopAddressSubscription() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
            let (initial, updates, cancel) = try await fulcrum.subscribe(
                method: .blockchain(.address(.subscribe(address: Self.testAddress))),
                initialType: Response.Result.Blockchain.Address.Subscribe.self,
                notificationType: Response.Result.Blockchain.Address.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )

            // nil is valid for never-seen addresses; if present, it should be non-empty.
            #expect(initial.status?.isEmpty != true)

            await cancel()

            let terminated = await NetworkTestClient.detectStreamTermination(
                updates,
                within: .seconds(10)
            )
            #expect(terminated)
        }
    }

    @Test("LIVE SLOW: Subscribes new header", .timeLimit(.minutes(30)))
    func subscribeAndReceiveNewHeaderFromLiveMining() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
            let (initial, updates, cancel) = try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )

            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)

            print("Current tip height: \(initial.height)")

            var updateCount = 0
            for try await update in updates {
                if updateCount == 0 {
                    print("Subscription identifier (method): \(update.subscriptionIdentifier)")
                    print("Number of blocks: \(update.blocks.count)")
                    for block in update.blocks {
                        #expect(block.height > 0)
                        #expect(block.hex.count == 160)

                        print("\(block.height): \(block.hex)")
                    }
                    updateCount += 1
                }

                break
            }

            await cancel()

            let terminated = await NetworkTestClient.detectStreamTermination(
                updates,
                within: .seconds(10)
            )
            #expect(terminated)
        }
    }

    // MARK: - Misc RPC
    @Test("Submit resolves address metadata over live Fulcrum", .timeLimit(.minutes(1)))
    func submitAndResolveAddressQueries() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
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
    func submitAndPropagateBroadcastErrors() async throws {
        let url = try await NetworkTestClient.pickRandomFulcrumURL()

        try await NetworkTestClient.runWithFulcrum(url) { fulcrum in
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
