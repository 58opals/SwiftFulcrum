// FulcrumNetworkClient+NegotiatedSession.swift

import Foundation

extension FulcrumNetworkClient {
    struct NegotiatedSession {
        var negotiatedProtocol: SwiftFulcrum.ProtocolVersion?
        var serverSoftwareVersion: String?
        var serverFeatures: ServerFeatures?
        var negotiationTask: Task<NegotiatedSession, Swift.Error>?
        var negotiationWaiterCount: Int
        var negotiationCancellationCoordinator: SharedTaskCancellationCoordinator

        init(negotiatedProtocol: SwiftFulcrum.ProtocolVersion? = nil,
             serverSoftwareVersion: String? = nil,
             serverFeatures: ServerFeatures? = nil,
             negotiationTask: Task<NegotiatedSession, Swift.Error>? = nil,
             negotiationWaiterCount: Int = 0,
             negotiationCancellationCoordinator: SharedTaskCancellationCoordinator = .init()) {
            self.negotiatedProtocol = negotiatedProtocol
            self.serverSoftwareVersion = serverSoftwareVersion
            self.serverFeatures = serverFeatures
            self.negotiationTask = negotiationTask
            self.negotiationWaiterCount = negotiationWaiterCount
            self.negotiationCancellationCoordinator = negotiationCancellationCoordinator
        }
    }
}

extension FulcrumNetworkClient.NegotiatedSession: Sendable {}
