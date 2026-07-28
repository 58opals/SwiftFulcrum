// ClientInterfaceNetworkValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidator {
@Suite(.serialized, .tags(.network))
struct ClientInterfaceNetworkValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    // MARK: - Subscriptions
    @Test(
        "Subscriptions expose cancellable header streams",
        .timeLimit(.minutes(1))
    )
    func subscribeAndCreateCancellableHeaderSubscription() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        try await NetworkTestClient.runWithClient(url) { client in
            let subscription: SwiftFulcrum.Client.Subscription<
                SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
                SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
            > = try await client.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30), cancellation: cancellation)
            )
            let initial = subscription.initial
            let updates = subscription.updates

            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)

            await subscription.cancel()

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
        .timeLimit(.minutes(1))
    )
    func subscribeAndStopAddressSubscription() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let subscription: SwiftFulcrum.Client.Subscription<
                SwiftFulcrum.Response.Blockchain.Address.Subscribe,
                SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification
            > = try await client.subscribe(
                method: .blockchain(.address(.subscribe(address: Self.testAddress))),
                options: .init(timeout: .seconds(30))
            )
            let initial = subscription.initial
            let updates = subscription.updates

            // nil is valid for never-seen addresses; if present, it should be non-empty.
            #expect(initial.status?.isEmpty != true)

            await subscription.cancel()

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
        .enabled(
            if: TestExecutionPolicy.shouldRunNetworkSlow,
            Comment(rawValue: TestExecutionPolicy.slowNetworkDisabledMessage)
        )
    )
    func subscribeAndReceiveNewHeaderFromLiveMining() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let subscription: SwiftFulcrum.Client.Subscription<
                SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
                SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
            > = try await client.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30))
            )
            let initial = subscription.initial
            let updates = subscription.updates

            #expect(initial.height > 0)
            #expect(initial.hex.count == 160)

            var observedUpdateCount = 0
            for try await update in updates {
                #expect(
                    update.subscriptionIdentifier
                        == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
                )
                _ = try #require(update.blocks.first)

                for block in update.blocks {
                    #expect(block.height > 0)
                    #expect(block.hex.count == 160)
                }
                observedUpdateCount += 1

                break
            }

            #expect(observedUpdateCount == 1)

            await subscription.cancel()

            let terminated = await NetworkTestClient.detectStreamTermination(
                updates,
                within: .seconds(10)
            )
            #expect(terminated)
        }
    }

    // MARK: - Misc RPC
    @Test(
        "Request resolves address metadata over live SwiftFulcrum.Client",
        .timeLimit(.minutes(1))
    )
    func requestAndResolveAddressQueries() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let scriptHashResult = try await client.request(
                method: .blockchain(.address(.getScriptHash(address: Self.testAddress))),
                responseType: SwiftFulcrum.Response.Blockchain.Address.ScriptHash.self,
                options: .init(timeout: .seconds(15))
            )

            #expect(scriptHashResult.scriptHash.count == 64)

            let balanceResult = try await client.request(
                method: .blockchain(.address(.getBalance(address: Self.testAddress, tokenFilter: nil))),
                responseType: SwiftFulcrum.Response.Blockchain.Address.Balance.self,
                options: .init(timeout: .seconds(15))
            )

            // Just assert decoding + basic invariants.
            #expect(balanceResult.confirmed >= 0)
            _ = balanceResult.unconfirmed
        }
    }
}
}
