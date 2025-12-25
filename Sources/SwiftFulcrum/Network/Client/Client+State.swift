// Client+State.swift

import Foundation

extension Client {
    struct State {
        var negotiatedSession: NegotiatedSession
        
        init(negotiatedSession: NegotiatedSession = .init()) {
            self.negotiatedSession = negotiatedSession
        }
    }
}

extension Client {
    struct NegotiatedSession {
        var negotiatedProtocol: ProtocolVersion?
        var serverSoftwareVersion: String?
        var serverFeatures: ServerFeatures?
        var negotiationTask: Task<NegotiatedSession, Swift.Error>?
        
        init(negotiatedProtocol: ProtocolVersion? = nil,
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

extension Client.State: Sendable {}
extension Client.NegotiatedSession: Sendable {}

extension Client {
    typealias ServerFeatures = Response.Result.Server.Features
    
    func resetNegotiatedSession() {
        state.negotiatedSession.negotiationTask?.cancel()
        state.negotiatedSession = .init()
    }
}
