// MetricsCollectable_.swift

import Foundation

protocol MetricsCollectable: Sendable {
    func didConnect(url: URL) async
    func didDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async
    func didSend(url: URL, message: URLSessionWebSocketTask.Message) async
    func didReceive(url: URL, message: URLSessionWebSocketTask.Message) async
    func didPing(url: URL, error: Swift.Error?) async
}
