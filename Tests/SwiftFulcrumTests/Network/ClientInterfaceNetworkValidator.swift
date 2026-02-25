import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.network))
struct ClientInterfaceNetworkValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    // MARK: - Unary
    @Test(
        "Submit returns current blockchain tip",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func submitAndReturnBlockchainTip() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let response = try await client.submit(
                method: .blockchain(.headers(.getTip)),
                responseType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.GetTipModel.self,
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

    @Test(
        "Submit starts FulcrumClient when idle",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func submitAndStartClientWhenIdle() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let client = try await FulcrumClient(url: url.absoluteString)

        // Avoid calling start() directly to exercise prepareClientForRequests.
        let response = try await client.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.GetTipModel.self,
            options: .init(timeout: .seconds(30))
        )

        guard case .single(_, let tip) = response else {
            Issue.record("Expected unary response for headers.getTip")
            return
        }

        #expect(tip.height > 0)
        #expect(await client.isRunning)

        await client.stop()
    }

    // MARK: - Subscriptions
    @Test(
        "Subscriptions expose cancellable header streams",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func subscribeAndCreateCancellableHeaderSubscription() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let cancellation = FulcrumClient.CallModel.CancellationModel()

        try await NetworkTestClient.runWithClient(url) { client in
            let (initial, updates, cancel) = try await client.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                notificationType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
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

    @Test(
        "Subscribes to address status and cancels the stream",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func subscribeAndStopAddressSubscription() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let (initial, updates, cancel) = try await client.subscribe(
                method: .blockchain(.address(.subscribe(address: Self.testAddress))),
                initialType: FulcrumResponse.ResultModel.BlockchainModel.AddressModel.SubscribeModel.self,
                notificationType: FulcrumResponse.ResultModel.BlockchainModel.AddressModel.SubscribeNotificationModel.self,
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

    @Test(
        "LIVE SLOW: Subscribes new header",
        .timeLimit(.minutes(30)),
        .enabled(if: TestExecutionPolicy.shouldRunNetworkSlow, "Slow network tests are disabled. Set SWIFTFULCRUM_RUN_NETWORK=1 and SWIFTFULCRUM_RUN_NETWORK_SLOW=1 (or SWIFTFULCRUM_RUN_LIVE_SLOW=1).")
    )
    func subscribeAndReceiveNewHeaderFromLiveMining() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let (initial, updates, cancel) = try await client.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                notificationType: FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
                options: .init(timeout: .seconds(30))
            )

            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)

            print("Current tip height: \(initial.height)")

            var updateCount = 0
            for try await update in updates {
                if updateCount == 0 {
                    print("SubscriptionModel identifier (method): \(update.subscriptionIdentifier)")
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
    @Test(
        "Submit resolves address metadata over live FulcrumClient",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func submitAndResolveAddressQueries() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let scriptHashResponse = try await client.submit(
                method: .blockchain(.address(.getScriptHash(address: Self.testAddress))),
                responseType: FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetScriptHashModel.self,
                options: .init(timeout: .seconds(15))
            )

            guard case .single(_, let scriptHashResult) = scriptHashResponse else {
                Issue.record("Expected unary response for address.get_scripthash")
                return
            }
            #expect(scriptHashResult.scriptHash.count == 64)

            let balanceResponse = try await client.submit(
                method: .blockchain(.address(.getBalance(address: Self.testAddress, tokenFilter: nil))),
                responseType: FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetBalanceModel.self,
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

    @Test(
        "Submit surfaces rpc errors for invalid broadcasts",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func submitAndPropagateBroadcastErrors() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            do {
                _ = try await client.submit(
                    method: .blockchain(.transaction(.broadcast(rawTransaction: "00"))),
                    responseType: FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.BroadcastModel.self,
                    options: .init(timeout: .seconds(15))
                )
                Issue.record("Expected broadcast to fail for invalid raw transaction")
            } catch let error as FulcrumClient.Error {
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
