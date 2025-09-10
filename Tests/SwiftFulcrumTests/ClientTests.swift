import Foundation
import Testing
@testable import SwiftFulcrum

/// This suite reuses helpers from your WebSocket tests:
/// - MetricsRecorder
/// - LoggerProbe
/// - RecordingLogger
/// - waitUntil(...)
/// - randomFulcrumURL()

@Suite("Client integration tests")
struct ClientTests {
    private func makeClient(
        url: URL,
        reconnect: WebSocket.Reconnector.Configuration = .init(maximumReconnectionAttempts: 3,
                                                               reconnectionDelay: 0,
                                                               maximumDelay: 0,
                                                               jitterRange: 1...1),
        timeout: TimeInterval = 8.0
    ) -> (Client, WebSocket, MetricsRecorder, LoggerProbe) {
        let metrics = MetricsRecorder()
        let probe = LoggerProbe()
        let logger = RecordingLogger(probe: probe)
        
        let webSocket = WebSocket(
            url: url,
            configuration: .init(metrics: metrics, logger: logger),
            reconnectConfiguration: reconnect,
            connectionTimeout: timeout
        )
        
        let client = Client(webSocket: webSocket, metrics: metrics, logger: logger)
        return (client, webSocket, metrics, probe)
    }
    
    private func makeJSON(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [])
    }
    
    // MARK: 1) Start and stop against a real server
    @Test
    func start_and_stop_live() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, metrics, probe) = makeClient(url: url)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        await client.stop()
        let down = await waitUntil { !(await webSocket.isConnected) }
        #expect(down)
        
        #expect(await metrics.didConnects == 1)
        #expect(await metrics.didDisconnects == 1)
        
        _ = await waitUntil { await probe.entries.contains { $0.message == "disconnect" } }
        let messages = await probe.entries.map(\.message)
        #expect(messages.contains("connect.begin"))
        #expect(messages.contains("connect.succeeded"))
        #expect(messages.contains("disconnect"))
        
        let indexBegin = messages.firstIndex(of: "connect.begin")!
        let indexOK = messages.lastIndex(of: "connect.succeeded")!
        let indexBye = messages.lastIndex(of: "disconnect")!
        #expect((indexBegin < indexOK) && (indexOK < indexBye))
    }
    
    // MARK: 2) Unary request/response via Client.call: blockchain.headers.get_tip
    @Test
    func call_get_tip() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, _, _) = makeClient(url: url)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        let (_, tip): (UUID, Response.Result.Blockchain.Headers.GetTip) =
        try await client.call(method: .blockchain(.headers(.getTip)))
        
        #expect(tip.height > 0)
        #expect(!tip.hex.isEmpty)
        
        await client.stop()
    }
    
    // MARK: 3) Subscribe to headers, then cancel -> sends unsubscribe
    @Test
    func subscribe_headers_then_cancel_sends_unsubscribe() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, metrics, _) = makeClient(url: url)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        let token = Client.Call.Token()
        let (_, initial, stream): (UUID,
                                   Response.Result.Blockchain.Headers.Subscribe,
                                   AsyncThrowingStream<Response.Result.Blockchain.Headers.SubscribeNotification, any Error>) =
        try await client.subscribe(method: .blockchain(.headers(.subscribe)),
                                   options: .init(timeout: .seconds(8), token: token))
        
        #expect(initial.height > 0)
        #expect(!initial.hex.isEmpty)
        
        let sendsBefore = await metrics.didSends
        
        await token.cancel()
        
        let unsubscriptionSent = await waitUntil(timeout: .seconds(4)) {
            (await metrics.didSends) >= sendsBefore + 1
        }
        #expect(unsubscriptionSent)
        
        var iterator = stream.makeAsyncIterator()
        let next = try? await iterator.next()
        #expect(next == nil)
        
        await client.stop()
    }
    
    // MARK: 4) Headers subscription receives routed notification (simulated)
    @Test
    func headers_subscription_receives_notification() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, _, _) = makeClient(url: url)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        let (_, initial, stream): (UUID,
                                   Response.Result.Blockchain.Headers.Subscribe,
                                   AsyncThrowingStream<Response.Result.Blockchain.Headers.SubscribeNotification, any Error>) =
        try await client.subscribe(method: .blockchain(.headers(.subscribe)))
        
        var iterator = stream.makeAsyncIterator()
        
        let nextHeight = initial.height + 1
        let fakeHex = "feedface"
        
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "blockchain.headers.subscribe",
            "params": [ ["height": nextHeight, "hex": fakeHex] ]
        ]
        try await client.handleMessage(.data(makeJSON(payload)))
        
        let notification = try await iterator.next()
        #expect(notification != nil)
        #expect(notification!.subscriptionIdentifier == "blockchain.headers.subscribe")
        #expect(notification!.blocks.count == 1)
        #expect(notification!.blocks[0].height == nextHeight)
        #expect(notification!.blocks[0].hex == fakeHex)
        
        await client.stop()
    }
    
    // MARK: 5) Address subscription uses suffix key and survives reconnect
    @Test
    func address_subscription_routes_and_resubscribes_on_reconnect() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, metrics, _) = makeClient(url: url,
                                                  reconnect: .init(maximumReconnectionAttempts: 5,
                                                                   reconnectionDelay: 0.25,
                                                                   maximumDelay: 1.0,
                                                                   jitterRange: 0.9...1.1))
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        let address = "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"
        let (_, _, stream): (UUID,
                             Response.Result.Blockchain.Address.Subscribe,
                             AsyncThrowingStream<Response.Result.Blockchain.Address.SubscribeNotification, any Error>) =
        try await client.subscribe(method: .blockchain(.address(.subscribe(address: address))))
        
        var iterator = stream.makeAsyncIterator()
        
        let before = await metrics.didSends
        try await client.reconnect()
        #expect(await webSocket.isConnected)
        let resubscriptionSent = await waitUntil(timeout: .seconds(8)) { (await metrics.didSends) > before }
        #expect(resubscriptionSent)
        
        let newStatus = "deadbeefstatus"
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "blockchain.address.subscribe",
            "params": [address, newStatus]
        ]
        try await client.handleMessage(.data(makeJSON(payload)))
        
        let notification = try await iterator.next()
        #expect(notification != nil)
        #expect(notification!.subscriptionIdentifier == address)
        #expect(notification!.status == newStatus)
        
        await client.stop()
    }
    
    // MARK: 6) Unary timeout surfaces Fulcrum.Error.client(.timeout)
    @Test
    func call_times_out() async throws {
        let url = try await randomFulcrumURL()
        let (client, webSocket, _, _) = makeClient(url: url)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        do {
            _ = try await client.call(
                method: .blockchain(.headers(.getTip)),
                options: .init(timeout: .milliseconds(1))
            ) as (UUID, Response.Result.Blockchain.Headers.GetTip)
            Issue.record("expected timeout did not occur")
        } catch let error as Fulcrum.Error {
            if case .client(.timeout) = error { /* ok */ } else {
                Issue.record("unexpected error: \(error)")
            }
        }
        
        await client.stop()
    }
}
