// WebSocketReconnectorValidator~RotationPolicy.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector rotates through bundled servers", .timeLimit(.minutes(1)))
    func rotateThroughBundledServers() async throws {
        let configuration = WebSocketModel.Reconnector.Configuration.basic
        let servers = try WebSocketModel.Server.decodeBundledServers(for: .mainnet)

        guard let current = servers.first else {
            Issue.record("Bundled servers are unavailable")
            return
        }

        let reconnector = WebSocketModel.Reconnector(configuration, network: .mainnet)
        let rotation = try await reconnector.buildCandidateRotation(preferredURL: nil, currentURL: current)

        #expect(rotation.count == servers.count)
        #expect(rotation.last == current)
        #expect(rotation.dropLast().allSatisfy { $0.absoluteString != current.absoluteString })
    }
}
