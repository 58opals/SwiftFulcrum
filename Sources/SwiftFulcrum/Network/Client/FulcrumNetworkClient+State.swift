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
    typealias ServerFeatures = FulcrumResponse.ResultModel.ServerModel.FeaturesModel
    
    func resetNegotiatedSession() {
        state.negotiatedSession.negotiationTask?.cancel()
        state.negotiatedSession = .init()
    }
}
