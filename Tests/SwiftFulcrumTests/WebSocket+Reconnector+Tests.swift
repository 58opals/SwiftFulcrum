import Foundation
import Testing
@testable import SwiftFulcrum

struct WebSocketReconnectorTests {
    @Test("Reconnector calculates deterministic backoff", .timeLimit(.minutes(1)))
    func calculateDeterministicBackoff() async throws {
        let configuration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 5,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )
        
        let reconnector = WebSocket.Reconnector(
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
        let configuration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 3,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )
        
        let minimumJitterReconnector = WebSocket.Reconnector(
            configuration,
            network: .mainnet,
            jitter: { _ in configuration.jitterRange.lowerBound }
        )
        
        let maximumJitterReconnector = WebSocket.Reconnector(
            configuration,
            network: .mainnet,
            jitter: { _ in configuration.jitterRange.upperBound }
        )
        
        let minimumDelay = await minimumJitterReconnector.makeDelay(for: 1)
        let maximumDelay = await maximumJitterReconnector.makeDelay(for: 2)
        
        #expect(minimumDelay == .seconds(2.4))
        #expect(maximumDelay == .seconds(7.8))
    }
    
    @Test("Reconnector exhausts after maximum attempts", .timeLimit(.minutes(1)))
    func exhaustAfterMaximumAttempts() async throws {
        let configuration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.05,
            maximumDelay: 0.05,
            jitterRange: 1.0 ... 1.0
        )
        
        let servers = try WebSocket.Server.decodeBundledServers(for: .mainnet)
        guard let current = servers.first else {
            Issue.record("Missing bundled servers for reconnection test")
            return
        }
        
        let unreachable = URL(string: "wss://127.0.0.1:9") ?? current
        
        let webSocket = WebSocket(
            url: unreachable,
            reconnectConfiguration: configuration,
            connectionTimeout: 0.2,
            sleep: { _ in },
            jitter: { _ in 1 }
        )
        
        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                with: nil,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnection should exhaust attempts")
        } catch {
            let attempts = await webSocket.reconnector.attemptCount
            let expected = max(configuration.maximumReconnectionAttempts, servers.count + 1)
            #expect(attempts == expected)
        }
    }
    
    @Test("Reconnector rotates through bundled servers", .timeLimit(.minutes(1)))
    func rotateThroughBundledServers() async throws {
        let configuration = WebSocket.Reconnector.Configuration.basic
        let servers = try WebSocket.Server.decodeBundledServers(for: .mainnet)
        
        guard let current = servers.first else {
            Issue.record("Bundled servers are unavailable")
            return
        }
        
        let reconnector = WebSocket.Reconnector(configuration, network: .mainnet)
        let rotation = try await reconnector.buildCandidateRotation(preferredURL: nil, currentURL: current)
        
        #expect(rotation.count == servers.count)
        #expect(rotation.last == current)
        #expect(rotation.dropLast().allSatisfy { $0.absoluteString != current.absoluteString })
    }
}
