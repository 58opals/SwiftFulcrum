// WebSocket+Reconnector.swift

import Foundation

extension WebSocket {
    public actor Reconnector {
        public struct Configuration: Sendable {
            public var maximumReconnectionAttempts: Int
            public var reconnectionDelay: TimeInterval
            public var maximumDelay: TimeInterval
            public var jitterRange: ClosedRange<TimeInterval>
            
            public var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }
            
            public static let basic = Self(maximumReconnectionAttempts: 0,
                                           reconnectionDelay: 1.0,
                                           maximumDelay: 30,
                                           jitterRange: 0.8 ... 1.3)
            
            public init(maximumReconnectionAttempts: Int,
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
        private var serverCatalog: [URL]
        private var nextServerIndex: Int
        
        public init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
            self.serverCatalog = .init()
            self.nextServerIndex = 0
        }
        
        func resetReconnectionAttemptCount() {
            reconnectionAttempts = 0
        }
        
        func attemptReconnection(
            for webSocket: any Context,
            with url: URL? = nil,
            cancelReceiver: Bool = true
        ) async throws {
            let currentURL = await webSocket.url
            var preferredEndpoint = url
            var rotation = try await buildCandidateRotation(preferredURL: preferredEndpoint, currentURL: currentURL)
            var rotationCursor = 0
            
            while configuration.isUnlimited || reconnectionAttempts < configuration.maximumReconnectionAttempts {
                if rotation.isEmpty { rotation = [currentURL] }
                if rotationCursor >= rotation.count { rotationCursor = 0 }
                
                let candidateURL = rotation[rotationCursor]
                rotationCursor += 1
                
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
                        "unlimited": String(configuration.isUnlimited),
                        "url": candidateURL.absoluteString
                    ],
                    file: "",
                    function: "",
                    line: 0
                )
                
                do {
                    if cancelReceiver { await webSocket.cancelReceiverTask() }
                    await webSocket.setURL(candidateURL)
                    try await webSocket.connect(withEmitLifecycle: false)
                    resetReconnectionAttemptCount()
                    await webSocket.ensureAutoReceive()
                    try await webSocket.connect(withEmitLifecycle: true)
                    await webSocket.emitLog(
                        .info,
                        "reconnect.succeeded",
                        metadata: ["url": candidateURL.absoluteString],
                        file: "",
                        function: "",
                        line: 0
                    )
                    await webSocket.emitLifecycle(.connected(isReconnect: true))
                    return
                } catch {
                    await webSocket.emitLog(
                        .warning,
                        "reconnect.failed",
                        metadata: [
                            "attempt": String(reconnectionAttempts),
                            "error": (error as NSError).localizedDescription,
                            "url": candidateURL.absoluteString
                        ],
                        file: "",
                        function: "",
                        line: 0
                    )
                }
                
                preferredEndpoint = nil
                rotation = try await buildCandidateRotation(preferredURL: preferredEndpoint, currentURL: currentURL)
                rotationCursor = 0
            }
            
            await webSocket.emitLog(
                .error,
                "reconnect.max_attempts_reached",
                metadata: ["url": currentURL.absoluteString],
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
                serverCatalog = Self.uniqued(try await WebSocket.Server.loadServerList(fallback: fallbacks))
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
            var unique: [URL] = []
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
