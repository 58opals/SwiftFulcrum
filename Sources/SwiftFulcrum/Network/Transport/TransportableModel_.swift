// TransportableModel_.swift

import Foundation

protocol TransportableModel: Sendable {
    typealias CloseInformation = (code: URLSessionWebSocketTask.CloseCode, reason: String?)
    
    var connectionState: FulcrumClient.ConnectionState { get async }
    var closeInformation: CloseInformation { get async }
    var endpoint: URL { get async }
    
    func connect() async throws
    func disconnect(with reason: String?) async
    func reconnect(with url: URL?) async throws
    
    func send(data: Data) async throws
    func send(string: String) async throws
    
    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>
    func makeLifecycleEvents() async -> AsyncStream<FulcrumTransportState.EventModel>
    func makeConnectionStateEvents() async -> AsyncStream<FulcrumClient.ConnectionState>
    func makeDiagnosticsSnapshot() async -> FulcrumClient.DiagnosticsModel.TransportSnapshot
    
    func updateMetrics(_ collector: MetricsClient?) async
    func updateLogger(_ handler: LogModel.Adapter?) async
    
    func registerQuietResponse(for identifier: UUID) async
}
