import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("WebSocket.Reconnector")
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
        let configuration = WebSocket.Configuration(logger: RecordingLogger(probe: loggerProbe))
        
        guard
            let failingURL = URL(string: "wss://fulcrum.jettscythe.xyz:50004"),
            let healthyURL = URL(string: "wss://cash.freeradiants.org:50004")
        else {
            Issue.record("Failed to create test URLs")
            return
        }
        
        let webSocket = WebSocket(
            url: failingURL,
            configuration: configuration,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 3,
                reconnectionDelay: 0.01,
                maximumDelay: 0.01,
                jitterRange: 1.0 ... 1.0
            )
        )
        
        try await webSocket.reconnector.attemptReconnection(for: webSocket, with: healthyURL)
        
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
        let configuration = WebSocket.Configuration(logger: RecordingLogger(probe: loggerProbe))
        
        guard let failingURL = URL(string: "wss://fulcrum.jettscythe.xyz:50004") else {
            Issue.record("Failed to create test URL")
            return
        }
        
        let webSocket = WebSocket(
            url: failingURL,
            configuration: configuration,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 2,
                reconnectionDelay: 0.01,
                maximumDelay: 0.01,
                jitterRange: 1.0 ... 1.0
            )
        )
        
        do {
            try await webSocket.reconnector.attemptReconnection(for: webSocket)
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
    
    func nextResult(withEmitLifecycle: Bool) throws -> Result<Void, Swift.Error> {
        connectCalls.append(withEmitLifecycle)
        guard !queuedResults.isEmpty else { throw WebSocketReconnectorTests.StubError.missingStub }
        return queuedResults.removeFirst()
    }
    
    func connect(withEmitLifecycle: Bool) throws {
        let outcome = try nextResult(withEmitLifecycle: withEmitLifecycle)
        switch outcome {
        case .success: break
        case .failure(let error): throw error
        }
    }
}
