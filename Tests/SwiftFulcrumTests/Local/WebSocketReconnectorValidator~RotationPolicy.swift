import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("ReconnectorModel rotates through bundled servers", .timeLimit(.minutes(1)))
    func rotateThroughBundledServers() async throws {
        let configuration = WebSocketModel.ReconnectorModel.Configuration.basic
        let servers = try WebSocketModel.ServerModel.decodeBundledServers(for: .mainnet)

        guard let current = servers.first else {
            Issue.record("Bundled servers are unavailable")
            return
        }

        let reconnector = WebSocketModel.ReconnectorModel(configuration, network: .mainnet)
        let rotation = try await reconnector.buildCandidateRotation(preferredURL: nil, currentURL: current)

        #expect(rotation.count == servers.count)
        #expect(rotation.last == current)
        #expect(rotation.dropLast().allSatisfy { $0.absoluteString != current.absoluteString })
    }
}
