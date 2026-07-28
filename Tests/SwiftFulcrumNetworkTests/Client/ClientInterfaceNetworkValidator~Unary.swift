// ClientInterfaceNetworkValidator~Unary.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidator.ClientInterfaceNetworkValidator {
    @Test(
        "Request returns current blockchain tip",
        .timeLimit(.minutes(1))
    )
    func requestAndReturnBlockchainTip() async throws {
        let url = try await NetworkTestClient.pickServerURL()

        try await NetworkTestClient.runWithClient(url) { client in
            let tip = try await client.request(
                method: .blockchain(.headers(.getTip)),
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                options: .init(timeout: .seconds(30))
            )

            #expect(tip.height > 0)
            #expect(tip.hex.count == 160)
        }
    }

    @Test(
        "Request starts SwiftFulcrum.Client when idle",
        .timeLimit(.minutes(1))
    )
    func requestAndStartClientWhenIdle() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let client = try await SwiftFulcrum.Client(connectingTo: url)

        do {
            // Avoid calling start() directly to exercise prepareClientForRequests.
            let tip = try await client.request(
                method: .blockchain(.headers(.getTip)),
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                options: .init(timeout: .seconds(30))
            )

            #expect(tip.height > 0)
            #expect(await client.isRunning)
        } catch {
            await client.stop()
            throw error
        }

        await client.stop()
    }
}
