import Foundation
@testable import SwiftFulcrum

/// Records WebSocket metrics for tests.
actor MetricsRecorder: MetricsCollectable {
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

/// Captures log messages during tests.
actor LoggerProbe {
    struct Entry: Sendable {
        let level: Log.Level
        let message: String
        let metadata: [String: String]?
    }
    
    private(set) var entries: [Entry] = []
    
    func record(_ entry: Entry) {
        entries.append(entry)
    }
}

/// Forwards log entries to a ``LoggerProbe``.
struct RecordingLogger: Log.Handler, Sendable {
    let probe: LoggerProbe
    
    func log(
        _ level: Log.Level,
        _ message: @autoclosure () -> String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: UInt
    ) {
        let entry = LoggerProbe.Entry(
            level: level,
            message: message(),
            metadata: metadata
        )
        Task { @Sendable in await probe.record(entry) }
    }
}

/// Waits until the given asynchronous condition becomes ``true``.
/// Returns ``false`` if the timeout elapses before the condition passes.
///
/// - Parameters:
///   - timeout: Maximum duration to wait.
///   - interval: Polling interval.
///   - condition: Asynchronous check to evaluate.
/// - Returns: ``true`` if the condition succeeded before timing out.
@discardableResult
func waitUntil(
    timeout: Duration = .seconds(5),
    interval: Duration = .milliseconds(25),
    _ condition: @Sendable () async -> Bool
) async -> Bool {
    let start = ContinuousClock.now
    while await !condition() {
        if ContinuousClock.now - start > timeout { return false }
        try? await Task.sleep(for: interval)
    }
    return true
}

/// Selects a random Fulcrum server URL for live integration tests.
/// - Throws: ``Fulcrum.Error.transport`` if no servers are available.
func randomFulcrumURL() async throws -> URL {
    let list = try await WebSocket.Server.fetchServerList()
    guard let url = list.randomElement() else {
        throw Fulcrum.Error.transport(.setupFailed)
    }
    return url
}
