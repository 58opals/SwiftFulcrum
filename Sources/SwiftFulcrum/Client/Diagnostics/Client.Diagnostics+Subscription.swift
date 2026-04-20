// Client.Diagnostics+Subscription.swift

import Foundation

extension SwiftFulcrum.Client.Diagnostics {
    public struct Subscription: Sendable {
        public let methodPath: String
        public let identifier: String?

        public init(methodPath: String, identifier: String?) {
            self.methodPath = methodPath
            self.identifier = identifier
        }
    }
}
