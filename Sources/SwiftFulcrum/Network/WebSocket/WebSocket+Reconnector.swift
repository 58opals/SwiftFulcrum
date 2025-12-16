// WebSocket+Reconnector.swift

import Foundation

extension WebSocket {
    actor Reconnector {
        struct Configuration: Sendable {
            var maximumReconnectionAttempts: Int
            var reconnectionDelay: TimeInterval
            var maximumDelay: TimeInterval
            var jitterRange: ClosedRange<TimeInterval>
            
            var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }
            
            static let basic = Self(maximumReconnectionAttempts: 1,
                                    reconnectionDelay: 1.5,
                                    maximumDelay: 30,
                                    jitterRange: 0.8 ... 1.3)
            
            init(maximumReconnectionAttempts: Int,
                 reconnectionDelay: TimeInterval,
                 maximumDelay: TimeInterval,
                 jitterRange: ClosedRange<TimeInterval>) {
                self.maximumReconnectionAttempts = maximumReconnectionAttempts
                self.reconnectionDelay = reconnectionDelay
                self.maximumDelay = maximumDelay
                self.jitterRange = jitterRange
            }
        }
        
        private let configuration: Configuration
        private var reconnectionAttempts: Int
        private let network: Fulcrum.Configuration.Network
        private var serverCatalog: [URL]
        private var nextServerIndex: Int
        
        private let sleep: @Sendable (Duration) async throws -> Void
        private let jitter: @Sendable (ClosedRange<Double>) -> Double
        
        var attemptCount: Int { reconnectionAttempts }
        
        init(_ configuration: Configuration,
             reconnectionAttempts: Int = 0,
             network: Fulcrum.Configuration.Network,
             sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in try await Task.sleep(for: duration) },
             jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { range in .random(in: range) }) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
            self.network = network
            self.serverCatalog = .init()
            self.nextServerIndex = 0
            self.sleep = sleep
            self.jitter = jitter
        }
        
        func resetReconnectionAttemptCount() {
            reconnectionAttempts = 0
        }
        
        func attemptReconnection(
            for webSocket: WebSocket,
            with url: URL? = nil,
            shouldCancelReceiver: Bool = true,
            isInitialConnection: Bool = false
        ) async throws {
            let currentURL = await webSocket.url
            let overrideURL = url
            var rotation = try await buildCandidateRotation(preferredURL: overrideURL, currentURL: currentURL)
            var rotationCursor = 0
            
            let maximumAttempts = configuration.isUnlimited ? Int.max : max(configuration.maximumReconnectionAttempts, rotation.count)
            while reconnectionAttempts < maximumAttempts {
                let candidateURL: URL
                
                if let overrideURL {
                    candidateURL = overrideURL
                } else {
                    if rotation.isEmpty { rotation = [currentURL] }
                    if rotationCursor >= rotation.count { rotationCursor = 0 }
                    
                    candidateURL = rotation[rotationCursor]
                    rotationCursor += 1
                }
                
                if let index = indexOfServer(candidateURL) {
                    nextServerIndex = (index + 1) % max(serverCatalog.count, 1)
                }
                
                if let delay = makeDelay(for: reconnectionAttempts) {
                    try await sleep(delay)
                }
                
                await webSocket.recordReconnectAttempt()
                let attemptSnapshot = await webSocket.makeDiagnosticsSnapshot()
                
                reconnectionAttempts += 1
                await webSocket.emitLog(
                    .info,
                    "reconnect.attempt",
                    metadata: [
                        "attempt": String(reconnectionAttempts),
                        "attemptTotal": String(attemptSnapshot.reconnectAttempts),
                        "successTotal": String(attemptSnapshot.reconnectSuccesses),
                        "phase": isInitialConnection ? "initial" : "reconnect",
                        "unlimited": String(configuration.isUnlimited),
                        "url": candidateURL.absoluteString
                    ],
                    file: "",
                    function: "",
                    line: 0
                )
                
                do {
                    if shouldCancelReceiver { await webSocket.cancelReceiverTask() }
                    await webSocket.updateURL(candidateURL)
                    try await webSocket.connect(
                        shouldEmitLifecycle: false,
                        shouldAllowFailover: false,
                        shouldCancelReceiver: shouldCancelReceiver
                    )
                    await webSocket.recordReconnectSuccess()
                    let successSnapshot = await webSocket.makeDiagnosticsSnapshot()
                    resetReconnectionAttemptCount()
                    await webSocket.emitLog(
                        .info,
                        "reconnect.succeeded",
                        metadata: [
                            "attemptTotal": String(successSnapshot.reconnectAttempts),
                            "phase": isInitialConnection ? "initial" : "reconnect",
                            "successTotal": String(successSnapshot.reconnectSuccesses),
                            "url": candidateURL.absoluteString
                        ],
                        file: "",
                        function: "",
                        line: 0
                    )
                    await webSocket.emitLifecycle(.connected(isReconnect: !isInitialConnection))
                    return
                } catch {
                    await webSocket.emitLog(
                        .warning,
                        "reconnect.failed",
                        metadata: [
                            "attempt": String(reconnectionAttempts),
                            "attemptTotal": String(attemptSnapshot.reconnectAttempts),
                            "error": (error as NSError).localizedDescription,
                            "phase": isInitialConnection ? "initial" : "reconnect",
                            "successTotal": String(attemptSnapshot.reconnectSuccesses),
                            "url": candidateURL.absoluteString
                        ],
                        file: "",
                        function: "",
                        line: 0
                    )
                }
                
                if overrideURL == nil {
                    rotation = try await buildCandidateRotation(preferredURL: nil, currentURL: currentURL)
                    rotationCursor = 0
                }
            }
            
            await webSocket.emitLog(
                .error,
                "reconnect.max_attempts_reached",
                metadata: [
                    "phase": isInitialConnection ? "initial" : "reconnect",
                    "attemptTotal": String(await webSocket.makeDiagnosticsSnapshot().reconnectAttempts),
                    "url": currentURL.absoluteString
                ],
                file: "",
                function: "",
                line: 0
            )
            let closeInformation = await webSocket.closeInformation
            throw Fulcrum.Error.transport(
                .connectionClosed(closeInformation.code, closeInformation.reason)
            )
        }
        
        func buildCandidateRotation(preferredURL: URL?, currentURL: URL) async throws -> [URL] {
            var fallbacks = [currentURL]
            if let preferredURL { fallbacks.append(preferredURL) }
            
            if serverCatalog.isEmpty {
                let network = network
                serverCatalog = Self.uniqued(try await WebSocket.Server.loadServerList(for: network, fallback: fallbacks))
            } else {
                serverCatalog = Self.uniqued(serverCatalog + fallbacks)
            }
            
            guard !serverCatalog.isEmpty else { return [currentURL] }
            
            var rotation = Self.rotated(serverCatalog, offset: nextServerIndex)
            let currentKey = Self.canonical(currentURL)
            
            if rotation.count > 1 {
                rotation.removeAll { Self.canonical($0) == currentKey }
            }
            
            if let preferredURL {
                let preferredKey = Self.canonical(preferredURL)
                rotation.removeAll { Self.canonical($0) == preferredKey }
                rotation.insert(preferredURL, at: 0)
            }
            
            if rotation.isEmpty {
                return [currentURL]
            }
            
            if !rotation.contains(where: { Self.canonical($0) == currentKey }) {
                rotation.append(currentURL)
            }
            
            return rotation
        }
        
        func makeDelay(for attempt: Int) -> Duration? {
            guard attempt > 0 else { return nil }
            
            let base = pow(2.0, Double(attempt)) * configuration.reconnectionDelay
            let capped = min(base, configuration.maximumDelay)
            let jitteredSeconds = capped * jitter(configuration.jitterRange)
            let roundedSeconds = Self.roundToNanosecondPrecision(jitteredSeconds)
            
            return .seconds(roundedSeconds)
        }
        
        private static func roundToNanosecondPrecision(_ seconds: Double) -> Double {
            guard seconds.isFinite else { return seconds }
            
            let nsPerSecond = 1_000_000_000.0
            return (seconds * nsPerSecond).rounded(.toNearestOrAwayFromZero) / nsPerSecond
        }
        
        private func indexOfServer(_ url: URL) -> Int? {
            let key = Self.canonical(url)
            return serverCatalog.firstIndex { Self.canonical($0) == key }
        }
        
        private static func canonical(_ url: URL) -> String { url.absoluteString }
        
        private static func uniqued(_ urls: [URL]) -> [URL] {
            var seen = Set<String>()
            var unique: [URL] = .init()
            unique.reserveCapacity(urls.count)
            
            for url in urls {
                let key = canonical(url)
                if seen.insert(key).inserted {
                    unique.append(url)
                }
            }
            
            return unique
        }
        
        private static func rotated(_ urls: [URL], offset: Int) -> [URL] {
            guard !urls.isEmpty else { return urls }
            let normalizedOffset = ((offset % urls.count) + urls.count) % urls.count
            guard normalizedOffset != 0 else { return urls }
            return Array(urls[normalizedOffset...] + urls[..<normalizedOffset])
        }
    }
}
