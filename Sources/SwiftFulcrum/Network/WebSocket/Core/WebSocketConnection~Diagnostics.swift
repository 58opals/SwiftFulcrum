// WebSocketConnection~Diagnostics.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func webSocketDiagnosticFields(_ fields: [OpalDiagnostics.Field] = []) -> [OpalDiagnostics.Field] {
        [
            .swiftFulcrumEndpointURL(url),
            .swiftFulcrumNetwork(network)
        ] + fields
    }
}
