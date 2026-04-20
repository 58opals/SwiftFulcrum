// Client+Diagnostics.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum Diagnostics {}
}

extension SwiftFulcrum.Client {
    public func makeDiagnosticsSnapshot() async -> Diagnostics.Snapshot {
        await client.makeDiagnosticsSnapshot()
    }
    
    public func listSubscriptions() async -> [Diagnostics.Subscription] {
        await client.listSubscriptions()
    }
}
