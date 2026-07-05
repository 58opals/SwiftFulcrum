// FulcrumNetworkClient.Call+TimeoutState.swift

import Foundation

extension FulcrumNetworkClient.Call {
    actor TimeoutState {
        private(set) var timeoutError: SwiftFulcrum.Client.Error?

        var cancellationError: SwiftFulcrum.Client.Error {
            timeoutError ?? SwiftFulcrum.Client.Error.client(.cancelled)
        }

        func mark(_ error: SwiftFulcrum.Client.Error) {
            timeoutError = error
        }
    }
}
