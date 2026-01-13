// MetricsCollectable_.swift

import Foundation

public protocol MetricsCollectable: Sendable {
    func recordConnect(url: URL, network: Fulcrum.Configuration.Network) async
    func recordDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
    func recordSend(url: URL, message: URLSessionWebSocketTask.Message) async
    func recordReceive(url: URL, message: URLSessionWebSocketTask.Message) async
    func recordPing(url: URL, error: Swift.Error?) async
    func recordDiagnosticsUpdate(url: URL, snapshot: Fulcrum.Diagnostics.Snapshot) async
    func recordSubscriptionRegistryUpdate(url: URL, subscriptions: [Fulcrum.Diagnostics.Subscription]) async
}
