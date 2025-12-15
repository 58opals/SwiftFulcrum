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
        
        init(_ configuration: Configuration, reconnectionAttempts: Int = 0, network: Fulcrum.Configuration.Network) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
            self.network = network
            self.serverCatalog = .init()
            self.nextServerIndex = 0
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
                
                if reconnectionAttempts > 0 {
                    let base = pow(2.0, Double(reconnectionAttempts)) * configuration.reconnectionDelay
                    let delay = min(base, configuration.maximumDelay) * .random(in: configuration.jitterRange)
                    try await Task.sleep(for: .seconds(delay))
                }
                
                reconnectionAttempts += 1
                await webSocket.emitLog(
                    .info,
                    "reconnect.attempt",
                    metadata: [
                        "attempt": String(reconnectionAttempts),
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
                    try await webSocket.connect(shouldEmitLifecycle: false, shouldAllowFailover: false)
                    resetReconnectionAttemptCount()
                    await webSocket.emitLog(
                        .info,
                        "reconnect.succeeded",
                        metadata: [
                            "phase": isInitialConnection ? "initial" : "reconnect",
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
                            "error": (error as NSError).localizedDescription,
                            "phase": isInitialConnection ? "initial" : "reconnect",
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
        
        private func buildCandidateRotation(preferredURL: URL?, currentURL: URL) async throws -> [URL] {
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
