// Client.Configuration+TLSDescriptor.swift

import Foundation
import Network

extension SwiftFulcrum.Client.Configuration {
    public struct TLSDescriptor: Sendable {
        public let delegate: URLSessionDelegate?
        public let options: NWProtocolTLS.Options

        public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
            self.options = options
            self.delegate = delegate
        }
    }
}
