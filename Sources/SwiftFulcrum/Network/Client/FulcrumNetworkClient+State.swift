// FulcrumNetworkClient+State.swift

import Foundation

extension FulcrumNetworkClient {
    struct State {
        var negotiatedSession: NegotiatedSession

        init(negotiatedSession: NegotiatedSession = .init()) {
            self.negotiatedSession = negotiatedSession
        }
    }
}

extension FulcrumNetworkClient.State: Sendable {}

extension FulcrumNetworkClient {
    typealias ServerFeatures = SwiftFulcrum.Response.Server.Features

    func resetNegotiatedSession() {
        state.negotiatedSession.negotiationTask?.cancel()
        state.negotiatedSession = .init()
    }
}
