// MetricsCollectable_.swift

import Foundation

@available(*, deprecated, message: "Use SwiftFulcrum.Metrics.ClientProtocol instead.")
public protocol MetricsClient: Sendable {
    func recordConnect(url: URL, network: FulcrumClient.Configuration.NetworkModel) async
    func recordDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
    func recordSend(url: URL, message: URLSessionWebSocketTask.Message) async
    func recordReceive(url: URL, message: URLSessionWebSocketTask.Message) async
    func recordPing(url: URL, error: Swift.Error?) async
    func recordDiagnosticsUpdate(url: URL, snapshot: FulcrumClient.DiagnosticsModel.Snapshot) async
    func recordSubscriptionRegistryUpdate(url: URL, subscriptions: [FulcrumClient.DiagnosticsModel.Subscription]) async
}
