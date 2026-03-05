// MetricsCollectable_.swift

import Foundation

public extension SwiftFulcrum.Metrics {
    protocol ClientProtocol: Sendable {
        func recordConnect(url: URL, network: SwiftFulcrum.Client.Configuration.NetworkModel) async
        func recordDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
        func recordSend(url: URL, message: URLSessionWebSocketTask.Message) async
        func recordReceive(url: URL, message: URLSessionWebSocketTask.Message) async
        func recordPing(url: URL, error: Swift.Error?) async
        func recordDiagnosticsUpdate(url: URL, snapshot: SwiftFulcrum.Client.DiagnosticsModel.Snapshot) async
        func recordSubscriptionRegistryUpdate(url: URL, subscriptions: [SwiftFulcrum.Client.DiagnosticsModel.Subscription]) async
    }
}
