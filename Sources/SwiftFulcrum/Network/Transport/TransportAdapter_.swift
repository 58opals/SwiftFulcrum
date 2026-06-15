// TransportAdapter_.swift

import Foundation

protocol TransportAdapter: Sendable {
    typealias CloseInformation = (code: URLSessionWebSocketTask.CloseCode, reason: String?)

    var connectionState: SwiftFulcrum.Client.ConnectionState { get async }
    var closeInformation: CloseInformation { get async }
    var endpoint: URL { get async }
    var reconnectAttempts: Int { get async }
    var reconnectSuccesses: Int { get async }

    func connect() async throws
    func disconnect(with reason: String?) async
    func reconnect(with url: URL?) async throws

    func send(data: Data) async throws
    func send(string: String) async throws

    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>
    func makeLifecycleEvents() async -> AsyncStream<SwiftFulcrum.Transport.State.Event>
    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState>
}
