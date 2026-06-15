// FulcrumClientLifecycleValidator~SubscriptionTimeout.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("subscribe(timeout:) cleans up registry", .timeLimit(.minutes(1)))
    func subscribeTimeoutCleansUpSubscriptionRegistry() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let subscribeTask = Task {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when initial response is missing")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)

        await subscribeTask.value

        let subscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(subscriptions.isEmpty)

        await fulcrum.stop()
    }
}
