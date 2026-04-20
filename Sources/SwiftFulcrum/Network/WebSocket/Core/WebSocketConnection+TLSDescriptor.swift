// WebSocketConnection+TLSDescriptor.swift

import Foundation
import Network

extension WebSocketConnection {
    struct TLSDescriptor: Sendable {
        let options: NWProtocolTLS.Options

        init(options: NWProtocolTLS.Options = .init()) {
            self.options = options
        }

        init(_ descriptor: SwiftFulcrum.Client.Configuration.TLSDescriptor) {
            self.options = descriptor.options
        }
    }
}
