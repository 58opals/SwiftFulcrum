// WebSocketConnection+TLSDescriptor.swift

import Foundation
import Network

extension WebSocketConnection {
    struct TLSDescriptor: Sendable {
        let options: NWProtocolTLS.Options
        let delegate: URLSessionDelegate?

        init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
            self.options = options
            self.delegate = delegate
        }

        init(_ descriptor: SwiftFulcrum.Client.Configuration.TLSDescriptor) {
            self.options = descriptor.options
            self.delegate = descriptor.delegate
        }
    }
}
