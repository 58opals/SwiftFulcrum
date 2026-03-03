// WebSocketModel.swift

import Foundation

actor WebSocketModel {
    var url: URL
    var task: URLSessionWebSocketTask?
    var connectionStateTracker: ConnectionStateTracker
    let network: FulcrumClient.Configuration.NetworkModel
    
    var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    var logger: LogModel.Adapter
    
    var reconnectAttemptCount = 0
    var reconnectSuccessCount = 0
    
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
    
    private let tlsDescriptor: TLSDescriptor?
    var metrics: MetricsClient?
    
    init(url: URL,
         configuration: Configuration = .init(),
         reconnectConfiguration: Reconnector.Configuration = .basic,
         connectionTimeout: TimeInterval = 10,
         sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in try await Task.sleep(for: duration) },
         jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { range in .random(in: range) }) {
        self.url = url
        self.task = nil
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
        self.logger = configuration.logger ?? LogModel.ConsoleAdapter()
        self.tlsDescriptor = configuration.tlsDescriptor
        self.maximumMessageSize = configuration.maximumMessageSize
        
        if let session = configuration.session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = connectionTimeout
            sessionConfiguration.timeoutIntervalForResource = connectionTimeout
            
            if let descriptor = configuration.tlsDescriptor {
                self.session = URLSession(configuration: sessionConfiguration, delegate: descriptor.delegate, delegateQueue: nil)
            } else {
                self.session = URLSession(configuration: sessionConfiguration)
            }
        }
    }
}
