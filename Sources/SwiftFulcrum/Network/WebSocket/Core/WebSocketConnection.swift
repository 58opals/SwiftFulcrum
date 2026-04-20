// WebSocketConnection.swift

import Foundation

actor WebSocketConnection {
    var url: URL
    var task: URLSessionWebSocketTask?
    var lastCloseInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?)
    var connectionStateTracker: ConnectionStateTracker
    let network: SwiftFulcrum.Client.Configuration.Network
    
    var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    var logger: SwiftFulcrum.Logging.Adapter
    
    var reconnectAttemptCount = 0
    var reconnectSuccessCount = 0

    var connectTask: Task<Void, Swift.Error>?
    var isConnectionInFlight = false
    var connectWaiters = [CheckedContinuation<Bool, Error>]()
    var isConnected: Bool { get async { await connectionStateTracker.state == .connected } }
    
    var nextOutgoingMessageIdentifier: UInt64 = 0
    var nextIncomingMessageIdentifier: UInt64 = 0
    
    var quietResponseIdentifiers: Set<UUID> = .init()
    
    var receivedTask: Task<Void, Never>?
    var shouldAutomaticallyReceive = false
    
    var lifecycleContinuationsBySubscriberIdentifier: [UUID: AsyncStream<Lifecycle.Event>.Continuation] = .init()
    
    let session: URLSession
    let connectionTimeout: TimeInterval
    let maximumMessageSize: Int
    let connectionEventTracker: WebSocketConnectionEventTracker?
    let sessionDelegateProxy: WebSocketSessionDelegateProxy?
    
    private let tlsDescriptor: TLSDescriptor?
    var metrics: SwiftFulcrum.Metrics.MetricsClient?
    
    init(url: URL,
         configuration: Configuration = .init(),
         reconnectConfiguration: Reconnector.Configuration = .basic,
         connectionTimeout: TimeInterval = 10,
         sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in try await Task.sleep(for: duration) },
         jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { range in .random(in: range) }) {
        self.url = url
        self.task = nil
        self.lastCloseInformation = (.invalid, nil)
        self.connectionStateTracker = .init()
        self.reconnector = Reconnector(
            reconnectConfiguration,
            network: configuration.network,
            serverCatalogLoader: configuration.serverCatalogLoader,
            sleep: sleep,
            jitter: jitter
        )
        self.connectionTimeout = connectionTimeout
        self.network = configuration.network
        
        self.metrics = configuration.metrics
        self.logger = configuration.logger ?? SwiftFulcrum.Logging.ConsoleAdapter()
        self.tlsDescriptor = configuration.tlsDescriptor
        self.maximumMessageSize = configuration.maximumMessageSize
        
        if let session = configuration.session {
            self.session = session
            self.connectionEventTracker = nil
            self.sessionDelegateProxy = nil
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            let connectionEventTracker = WebSocketConnectionEventTracker()
            let sessionDelegateProxy = WebSocketSessionDelegateProxy(
                connectionEventTracker: connectionEventTracker,
                baseDelegate: configuration.tlsDescriptor?.delegate
            )
            
            self.connectionEventTracker = connectionEventTracker
            self.sessionDelegateProxy = sessionDelegateProxy
            self.session = URLSession(
                configuration: sessionConfiguration,
                delegate: sessionDelegateProxy,
                delegateQueue: nil
            )
        }
    }
}
