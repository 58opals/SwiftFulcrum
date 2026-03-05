// FulcrumNetworkClient+NegotiatedSessionModel.swift

import Foundation

extension FulcrumNetworkClient {
    struct NegotiatedSessionModel {
        var negotiatedProtocol: SwiftFulcrum.ProtocolVersion?
        var serverSoftwareVersion: String?
        var serverFeatures: ServerFeatures?
        var negotiationTask: Task<NegotiatedSessionModel, Swift.Error>?

        init(negotiatedProtocol: SwiftFulcrum.ProtocolVersion? = nil,
             serverSoftwareVersion: String? = nil,
             serverFeatures: ServerFeatures? = nil,
             negotiationTask: Task<NegotiatedSessionModel, Swift.Error>? = nil) {
            self.negotiatedProtocol = negotiatedProtocol
            self.serverSoftwareVersion = serverSoftwareVersion
            self.serverFeatures = serverFeatures
            self.negotiationTask = negotiationTask
        }
    }
}

extension FulcrumNetworkClient.NegotiatedSessionModel: Sendable {}
