// MetricsCollectable_.swift

import Foundation

public protocol MetricsCollectable: Sendable {
    func didConnect(url: URL, network: Fulcrum.Configuration.Network) async
    func didDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
    func didSend(url: URL, message: URLSessionWebSocketTask.Message) async
    func didReceive(url: URL, message: URLSessionWebSocketTask.Message) async
    func didPing(url: URL, error: Swift.Error?) async
    func didUpdateDiagnostics(url: URL, snapshot: Fulcrum.Diagnostics.Snapshot) async
    func didUpdateSubscriptionRegistry(url: URL, subscriptions: [Fulcrum.Diagnostics.Subscription]) async
}
