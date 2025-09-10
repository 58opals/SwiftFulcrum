import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("Client resubscription tests")
struct ClientResubscriptionTests {

    @Test
    func resubscribe_on_reconnect_resends_methods() async throws {
        var url = try await randomFulcrumURL()
        let metrics = MetricsRecorder()
        let probe = LoggerProbe()
        let logger = RecordingLoggerProbe(probe: probe)

        let ws = WebSocket(
            url: url,
            configuration: .init(metrics: metrics, logger: logger),
            reconnectConfiguration: .init(maximumReconnectionAttempts: 5,
                                          reconnectionDelay: 0.25,
                                          maximumDelay: 1.0,
                                          jitterRange: 0.9...1.1),
            connectionTimeout: 8.0
        )
        let client = Client(webSocket: ws, metrics: metrics, logger: logger)

        do {
            try await client.start()
        } catch {
            var ok = false
            for _ in 0..<10 {
                let newURL = try await randomFulcrumURL()
                do {
                    try await client.reconnect(with: newURL)
                    ok = await ws.isConnected
                    if ok { break }
                } catch { /* try next */ }
            }
            #expect(ok, "could not find a server with a valid TLS chain")
        }
        #expect(await ws.isConnected)

        typealias Initial = Response.Result.Blockchain.Headers.Subscribe
        typealias Note = Response.Result.Blockchain.Headers.SubscribeNotification
        let (_, _, updates): (UUID, Initial, AsyncThrowingStream<Note, Swift.Error>) =
            try await client.subscribe(method: .blockchain(.headers(.subscribe)))

        let sink = Task {
            for try await _ in updates { /* ignore */ }
        }
        defer { sink.cancel() }

        let storedBefore = await client.subscriptionMethods.count
        #expect(storedBefore == 1)
        let baselineSends = await metrics.didSends

        do {
            try await client.reconnect()
        } catch {
            url = try await randomFulcrumURL()
            try await client.reconnect(with: url)
        }
        #expect(await ws.isConnected)

        let expectedDelta = storedBefore
        let ok = await waitUntil(timeout: .seconds(8)) {
            (await metrics.didSends) >= (baselineSends + expectedDelta)
        }
        #expect(ok, "expected at least \(expectedDelta) resend(s) after reconnect")

        await client.stop()
    }
}

struct RecordingLoggerProbe: Log.Handler, Sendable {
    let probe: LoggerProbe
    func log(_ level: Log.Level, _ message: @autoclosure () -> String,
             metadata: [String : String]?, file: String, function: String, line: UInt) {
        let entry = LoggerProbe.Entry(level: level, message: message(), metadata: metadata)
        Task { @Sendable in await probe.record(entry) }
    }
}
