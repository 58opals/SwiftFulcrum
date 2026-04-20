// Client.Configuration+TLSDescriptor.swift

import Foundation
import Network

extension SwiftFulcrum.Client.Configuration {
    public struct TLSDescriptor: Sendable {
        public let options: NWProtocolTLS.Options

        public init(options: NWProtocolTLS.Options = .init()) {
            self.options = options
        }
    }
}
