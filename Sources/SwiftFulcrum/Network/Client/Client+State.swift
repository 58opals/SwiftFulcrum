// Client+State.swift

import Foundation

extension Client {
    struct State {
        var negotiatedSession: NegotiatedSessionModel
        
        init(negotiatedSession: NegotiatedSessionModel = .init()) {
            self.negotiatedSession = negotiatedSession
        }
    }
}

extension Client {
    struct NegotiatedSessionModel {
        var negotiatedProtocol: ProtocolVersionModel?
        var serverSoftwareVersion: String?
        var serverFeatures: ServerFeatures?
        var negotiationTask: Task<NegotiatedSessionModel, Swift.Error>?
        
        init(negotiatedProtocol: ProtocolVersionModel? = nil,
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

extension Client.State: Sendable {}
extension Client.NegotiatedSessionModel: Sendable {}

extension Client {
    typealias ServerFeatures = Response.ResultModel.ServerModel.FeaturesModel
    
    func resetNegotiatedSession() {
        state.negotiatedSession.negotiationTask?.cancel()
        state.negotiatedSession = .init()
    }
}
