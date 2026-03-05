// FulcrumNetworkClient+State.swift

import Foundation

extension FulcrumNetworkClient {
    struct State {
        var negotiatedSession: NegotiatedSessionModel
        
        init(negotiatedSession: NegotiatedSessionModel = .init()) {
            self.negotiatedSession = negotiatedSession
        }
    }
}

extension FulcrumNetworkClient.State: Sendable {}

extension FulcrumNetworkClient {
    typealias ServerFeatures = SwiftFulcrum.RPC.Response.ResultModel.Server.Features
    
    func resetNegotiatedSession() {
        state.negotiatedSession.negotiationTask?.cancel()
        state.negotiatedSession = .init()
    }
}
