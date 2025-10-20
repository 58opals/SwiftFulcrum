import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(
    "WebSocket.Reconnector",
    .serialized,
    .timeLimit(.minutes(2))
)

struct WebSocketReconnectorTests {
    enum StubError: Swift.Error, Equatable {
        case timedOut
        case missingStub
    }
    
    @Test("retries unhealthy endpoints until a connection succeeds")
    func retriesUntilSuccess() async throws {
        let harness = WebSocketReconnectionHarness.shared
        await harness.reset(results: [
            .failure(StubError.timedOut),
            .success(()),
            .success(())
        ])
        
        let loggerProbe = LoggerProbe()
        
        guard
            let failingURL = URL(string: "wss://fulcrum.jettscythe.xyz:50004"),
            let healthyURL = URL(string: "wss://bch.imaginary.cash:50004")
        else {
            Issue.record("Failed to create test URLs")
            return
        }
        
        let logger = RecordingLogger(probe: loggerProbe)
        let reconnectionConfiguration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 3,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )
        let reconnector = WebSocket.Reconnector(reconnectionConfiguration)
        let webSocket = TestReconnectionContext(
            url: failingURL,
            harness: harness,
            logger: logger
        )
        
        try await reconnector.attemptReconnection(for: webSocket, with: healthyURL)
        
        let entriesSatisfied = await waitUntil(timeout: .seconds(1)) {
            let entries = await loggerProbe.entries
            return entries.contains(where: { $0.message == "reconnect.succeeded" })
        }
        #expect(entriesSatisfied)
        
        let entries = await loggerProbe.entries
        let attemptEntries = entries.filter { $0.message == "reconnect.attempt" }
        #expect(attemptEntries.count == 2)
        #expect(attemptEntries.last?.metadata?["attempt"] == "2")
        
        #expect(entries.contains { $0.message == "reconnect.failed" })
        #expect(entries.contains { $0.message == "reconnect.succeeded" })
        
        let url = await webSocket.url
        #expect(url == healthyURL)
        
        let connectCalls = await harness.connectCalls
        #expect(connectCalls == [false, false, true])
        
        let exhausted = await harness.isExhausted
        #expect(exhausted)
    }
    
    @Test("propagates transport errors after exhausting attempts")
    func failsAfterExhaustingAttempts() async throws {
        let harness = WebSocketReconnectionHarness.shared
        await harness.reset(results: [
            .failure(StubError.timedOut),
            .failure(StubError.timedOut)
        ])
        
        let loggerProbe = LoggerProbe()
        
        guard let failingURL = URL(string: "wss://fulcrum.jettscythe.xyz:50004") else {
            Issue.record("Failed to create test URL")
            return
        }
        
        let logger = RecordingLogger(probe: loggerProbe)
        let reconnectionConfiguration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )
        let reconnector = WebSocket.Reconnector(reconnectionConfiguration)
        let webSocket = TestReconnectionContext(
            url: failingURL,
            harness: harness,
            logger: logger
        )
        
        do {
            try await reconnector.attemptReconnection(for: webSocket)
            Issue.record("Expected reconnection to fail")
        } catch let error as Fulcrum.Error {
            #expect(error == .transport(.connectionClosed(.invalid, nil)))
        }
        
        let entriesSatisfied = await waitUntil(timeout: .seconds(1)) {
            let entries = await loggerProbe.entries
            return entries.contains(where: { $0.message == "reconnect.max_attempts_reached" })
        }
        #expect(entriesSatisfied)
        
        let entries = await loggerProbe.entries
        let attemptEntries = entries.filter { $0.message == "reconnect.attempt" }
        #expect(attemptEntries.count == 2)
        #expect(entries.filter { $0.message == "reconnect.failed" }.count == 2)
        #expect(entries.contains { $0.message == "reconnect.max_attempts_reached" })
        
        let connectCalls = await harness.connectCalls
        #expect(connectCalls == [false, false])
    }
}

private actor WebSocketReconnectionHarness {
    static let shared = WebSocketReconnectionHarness()
    
    private var queuedResults: [Result<Void, Swift.Error>] = []
    private(set) var connectCalls: [Bool] = []
    
    var isExhausted: Bool { queuedResults.isEmpty }
    
    func reset(results: [Result<Void, Swift.Error>]) {
        queuedResults = results
        connectCalls = []
    }
    
    func dequeueResult(withEmitLifecycle: Bool) throws -> Result<Void, Swift.Error> {
        connectCalls.append(withEmitLifecycle)
        guard !queuedResults.isEmpty else { throw WebSocketReconnectorTests.StubError.missingStub }
        return queuedResults.removeFirst()
    }
    
}

private actor TestReconnectionContext: WebSocket.Reconnector.Context {
    private let harness: WebSocketReconnectionHarness
    private let logger: Log.Handler
    
    var url: URL
    var closeInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?) = (.invalid, nil)
    
    init(url: URL, harness: WebSocketReconnectionHarness, logger: Log.Handler) {
        self.url = url
        self.harness = harness
        self.logger = logger
    }
    
    func cancelReceiverTask() async {}
    
    func setURL(_ newURL: URL) { url = newURL }
    
    func connect(withEmitLifecycle: Bool) async throws {
        let outcome = try await harness.dequeueResult(withEmitLifecycle: withEmitLifecycle)
        switch outcome {
        case .success: break
        case .failure(let error): throw error
        }
    }
    
    func ensureAutoReceive() {}
    
    func emitLog(_ level: Log.Level,
                 _ message: @autoclosure () -> String,
                 metadata: [String: String]?,
                 file: String,
                 function: String,
                 line: UInt) {
        var enrichedMetadata = ["component": "WebSocket", "url": url.absoluteString]
        if let metadata {
            for (key, value) in metadata { enrichedMetadata[key] = value }
        }
        
        logger.log(level, message(), metadata: enrichedMetadata, file: file, function: function, line: line)
    }
    
    func emitLifecycle(_ event: WebSocket.Lifecycle.Event) {}
}
