// MetricsClient_.swift

import Foundation

public extension SwiftFulcrum.Metrics {
    protocol MetricsClient: Sendable {
        func recordConnect(url: URL, network: SwiftFulcrum.Client.Configuration.Network) async
        func recordDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
        func recordSend(url: URL, message: URLSessionWebSocketTask.Message) async
        func recordReceive(url: URL, message: URLSessionWebSocketTask.Message) async
        func recordPing(url: URL, error: Swift.Error?) async
        func recordDiagnosticsUpdate(url: URL, snapshot: SwiftFulcrum.Client.Diagnostics.Snapshot) async
        func recordSubscriptionRegistryUpdate(url: URL, subscriptions: [SwiftFulcrum.Client.Diagnostics.Subscription]) async
    }
}
