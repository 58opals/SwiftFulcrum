import Foundation

extension FulcrumNetworkClient {
    struct NegotiatedSession {
        var negotiatedProtocol: SwiftFulcrum.ProtocolVersion?
        var serverSoftwareVersion: String?
        var serverFeatures: ServerFeatures?
        var negotiationTask: Task<NegotiatedSession, Swift.Error>?

        init(negotiatedProtocol: SwiftFulcrum.ProtocolVersion? = nil,
             serverSoftwareVersion: String? = nil,
             serverFeatures: ServerFeatures? = nil,
             negotiationTask: Task<NegotiatedSession, Swift.Error>? = nil) {
            self.negotiatedProtocol = negotiatedProtocol
            self.serverSoftwareVersion = serverSoftwareVersion
            self.serverFeatures = serverFeatures
            self.negotiationTask = negotiationTask
        }
    }
}

extension FulcrumNetworkClient.NegotiatedSession: Sendable {}
