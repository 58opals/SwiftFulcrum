import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector calculates deterministic backoff", .timeLimit(.minutes(1)))
    func calculateDeterministicBackoff() async throws {
        let configuration = WebSocketModel.Reconnector.Configuration(
            maximumReconnectionAttempts: 5,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )

        let reconnector = WebSocketModel.Reconnector(
            configuration,
            network: .mainnet,
            jitter: { _ in 1 }
        )

        let initialDelay = await reconnector.makeDelay(for: 0)
        #expect(initialDelay == nil)

        let firstDelay = await reconnector.makeDelay(for: 1)
        let secondDelay = await reconnector.makeDelay(for: 2)
        let thirdDelay = await reconnector.makeDelay(for: 3)
        let cappedDelay = await reconnector.makeDelay(for: 5)

        #expect(firstDelay == .seconds(3))
        #expect(secondDelay == .seconds(6))
        #expect(thirdDelay == .seconds(12))
        #expect(cappedDelay == .seconds(30))
    }

    @Test("Reconnector applies jitter bounds", .timeLimit(.minutes(1)))
    func applyJitterBounds() async throws {
        let configuration = WebSocketModel.Reconnector.Configuration(
            maximumReconnectionAttempts: 3,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )

        let minimumJitterReconnector = WebSocketModel.Reconnector(
            configuration,
            network: .mainnet,
            jitter: { _ in configuration.jitterRange.lowerBound }
        )

        let maximumJitterReconnector = WebSocketModel.Reconnector(
            configuration,
            network: .mainnet,
            jitter: { _ in configuration.jitterRange.upperBound }
        )

        let minimumDelay = await minimumJitterReconnector.makeDelay(for: 1)
        let maximumDelay = await maximumJitterReconnector.makeDelay(for: 2)

        #expect(minimumDelay == .seconds(2.4))
        #expect(maximumDelay == .seconds(7.8))
    }
}
