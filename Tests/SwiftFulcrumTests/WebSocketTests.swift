import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Helpers

final actor MetricsRecorder: MetricsCollectable {
    private(set) var didConnects = 0
    private(set) var didDisconnects = 0
    private(set) var didSends = 0
    private(set) var didReceives = 0
    private(set) var didPings = 0
    func didConnect(url: URL) async { didConnects += 1 }
    func didDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async { didDisconnects += 1 }
    func didSend(url: URL, message: URLSessionWebSocketTask.Message) async { didSends += 1 }
    func didReceive(url: URL, message: URLSessionWebSocketTask.Message) async { didReceives += 1 }
    func didPing(url: URL, error: Swift.Error?) async { didPings += 1 }
}

final actor LoggerProbe {
    struct Entry: Sendable { let level: Log.Level, message: String, metadata: [String:String]? }
    private(set) var entries: [Entry] = []
    func record(_ entry: Entry) { entries.append(entry) }
}

struct RecordingLogger: Log.Handler, Sendable {
    let probe: LoggerProbe
    func log(_ level: Log.Level,
             _ message: @autoclosure () -> String,
             metadata: [String : String]?,
             file: String, function: String, line: UInt) {
        let message = message()
        let entry = LoggerProbe.Entry(level: level, message: message, metadata: metadata)
        Task { @Sendable in await probe.record(entry) }
    }
}

@discardableResult
func waitUntil(timeout: Duration = .seconds(5),
               interval: Duration = .milliseconds(25),
               _ condition: @Sendable () async -> Bool) async -> Bool {
    let start = ContinuousClock.now
    while await !condition() {
        if ContinuousClock.now - start > timeout { return false }
        try? await Task.sleep(for: interval)
    }
    return true
}

func randomFulcrumURL() async throws -> URL {
    let list = try await WebSocket.Server.getServerList()
    guard let url = list.randomElement() else { throw Fulcrum.Error.transport(.setupFailed) }
    return url
}

func nextData(from message: URLSessionWebSocketTask.Message) -> Data? {
    switch message {
    case .data(let d): return d
    case .string(let s): return s.data(using: .utf8)
    @unknown default: return nil
    }
}

func nextData(from stream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>) async throws -> Data {
    var iterator = stream.makeAsyncIterator()
    while let m = try await iterator.next() {
        if let d = nextData(from: m) { return d }
    }
    throw Fulcrum.Error.client(.emptyResponse(nil))
}

// MARK: - WebSocket live tests

@Suite("WebSocket integration tests")
struct WebSocketTests {
    
    // 1) Connect and disconnect against a real server
    @Test
    func connect_and_disconnect_live() async throws {
        var url = try await randomFulcrumURL()
        let metrics = MetricsRecorder()
        let probe = LoggerProbe()
        let logger = RecordingLogger(probe: probe)
        
        let webSocket = WebSocket(
            url: url,
            configuration: .init(metrics: metrics, logger: logger),
            reconnectConfiguration: .init(maximumReconnectionAttempts: 3,
                                          reconnectionDelay: 0,
                                          maximumDelay: 0,
                                          jitterRange: 1...1),
            connectionTimeout: 8.0
        )
        
        do {
            try await webSocket.connect()
        } catch {
            url = try await randomFulcrumURL()
            try await webSocket.reconnect(with: url)
        }
        
        #expect(await webSocket.isConnected)
        #expect(await webSocket.url == url)
        
        await webSocket.disconnect(with: "test")
        let wentDown = await waitUntil { !(await webSocket.isConnected) }
        #expect(wentDown)
        
        #expect(await metrics.didConnects == 1)
        #expect(await metrics.didDisconnects == 1)
        
        _ = await waitUntil { await probe.entries.map(\.message).contains("disconnect") }
        let messages = await probe.entries.map(\.message)
        
        #expect(messages.contains("connect.begin"))
        #expect(messages.contains("connect.succeeded"))
        #expect(messages.contains("disconnect"))
        
        let indexConnect = messages.firstIndex(of: "connect.begin")!
        let indexSuccess = messages.lastIndex(of: "connect.succeeded")!
        let indexDisconnect = messages.lastIndex(of: "disconnect")!
        
        #expect((indexConnect) < (indexSuccess) && (indexSuccess < indexDisconnect))
        
        if let indexReconnect = messages.firstIndex(of: "reconnect.attempt") {
            #expect(indexReconnect > indexConnect)
            if let indexReconnectSuccess = messages.lastIndex(of: "reconnect.succeeded") {
                #expect(indexReconnectSuccess >= indexSuccess)
            }
        }
    }
    
    // 2) Unary request/response: blockchain.headers.get_tip
    @Test
    func request_response_get_tip() async throws {
        var url = try await randomFulcrumURL()
        let webSocket = WebSocket(
            url: url,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 5,
                reconnectionDelay: 0.25,
                maximumDelay: 1.0,
                jitterRange: 0.9...1.1
            ),
            connectionTimeout: 8.0
        )

        do {
            try await webSocket.connect()
        } catch {
            url = try await randomFulcrumURL()
            try await webSocket.reconnect(with: url)
        }
        #expect(await webSocket.isConnected)
        let stream = await webSocket.messages()
        
        let identifier = UUID()
        let request = Method.blockchain(.headers(.getTip)).createRequest(with: identifier)
        guard let body = request.data else { Issue.record("encode failed"); return }
        try await webSocket.send(data: body)
        
        let raw = try await nextData(from: stream)
        let container = try JSONRPC.Coder.decoder.decode(
            Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.GetTip>.self,
            from: raw
        )
        switch try container.getResponseType() {
        case .regular(let response):
            #expect(response.id == identifier)
            #expect(response.result.height > 0)
            #expect(!response.result.hex.isEmpty)
        default:
            Issue.record("unexpected response kind")
        }
        
        await webSocket.disconnect()
    }
    
    // 3) Manual reconnect keeps shared message stream usable
    @Test
    func manual_reconnect_keeps_stream() async throws {
        var url = try await randomFulcrumURL()
        let webSocket = WebSocket(
            url: url,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 5,
                reconnectionDelay: 0.25,
                maximumDelay: 1.0,
                jitterRange: 0.9...1.1
            ),
            connectionTimeout: 8.0
        )

        do {
            try await webSocket.connect()
        } catch {
            url = try await randomFulcrumURL()
            try await webSocket.reconnect(with: url)
        }
        #expect(await webSocket.isConnected)

        let stream = await webSocket.messages(enableAutoResume: true)

        do {
            try await webSocket.reconnect()
        } catch {
            let newURL = try await randomFulcrumURL()
            try await webSocket.reconnect(with: newURL)
            url = newURL
        }
        _ = await webSocket.messages(enableAutoResume: true)

        let reconnected = await waitUntil(timeout: .seconds(8)) { await webSocket.isConnected }
        #expect(reconnected)
        #expect(await webSocket.url == url)

        let identifier = UUID()
        let request = Method.blockchain(.headers(.getTip)).createRequest(with: identifier)
        try await webSocket.send(data: request.data!)
        let raw = try await nextData(from: stream)
        let container = try JSONRPC.Coder.decoder.decode(
            Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.GetTip>.self,
            from: raw
        )
        if case .regular(let response) = try container.getResponseType() {
            #expect(response.id == identifier)
        } else {
            Issue.record("unexpected response kind")
        }

        await webSocket.disconnect()
    }
    
    // 4) Server list loads and contains wss endpoints
    @Test
    func server_list_is_nonempty_and_secure() async throws {
        let list = try await WebSocket.Server.getServerList()
        #expect(!list.isEmpty)
        #expect(list.allSatisfy { $0.scheme?.lowercased() == "wss" })
    }
    
    // 5) Reconnect to a bad endpoint stops after max attempts
    @Test
    func reconnect_fails_after_max_attempts() async throws {
        guard let badURL = URL(string: "wss://127.0.0.1:1") else { Issue.record("bad URL build failed"); return }
        let webSocket = WebSocket(
            url: badURL,
            reconnectConfiguration: .init(maximumReconnectionAttempts: 2,
                                          reconnectionDelay: 0,
                                          maximumDelay: 0,
                                          jitterRange: 1...1),
            connectionTimeout: 1.0
        )
        
        do {
            try await webSocket.reconnect()
            Issue.record("expected failure")
        } catch let error as Fulcrum.Error {
            if case .transport = error { /* ok */ } else { Issue.record("unexpected error: \(error)") }
        }
    }
}
