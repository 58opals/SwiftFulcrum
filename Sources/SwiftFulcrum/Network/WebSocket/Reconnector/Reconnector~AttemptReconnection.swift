// Reconnector~AttemptReconnection.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection.Reconnector {
    func attemptReconnection(
        for webSocket: WebSocketConnection,
        with url: URL? = nil,
        shouldCancelReceiver: Bool = true,
        isInitialConnection: Bool = false
    ) async throws {
        resetReconnectionAttemptCount()
        let traceID = OpalDiagnostics.TraceID()

        let currentURL = await webSocket.url
        let overrideURL = url
        var rotation = try await buildCandidateRotation(preferredURL: overrideURL, currentURL: currentURL)
        var rotationCursor = 0

        let maximumAttempts: Int
        if configuration.isUnlimited {
            maximumAttempts = Int.max
        } else if serverCatalogLoader.usesBundledCatalog, overrideURL == nil {
            maximumAttempts = max(configuration.maximumReconnectionAttempts, rotation.count)
        } else {
            maximumAttempts = configuration.maximumReconnectionAttempts
        }
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
            await webSocket.recordWebSocketEvent(
                SwiftFulcrumDiagnostics.Event.reconnectAttempt,
                category: SwiftFulcrumDiagnostics.Category.reconnect,
                level: .info,
                traceID: traceID,
                fields: [
                    SwiftFulcrumDiagnostics.publicField("attempt", reconnectionAttempts),
                    SwiftFulcrumDiagnostics.publicField("attempt_total", attemptSnapshot.reconnectAttempts),
                    SwiftFulcrumDiagnostics.publicField("success_total", attemptSnapshot.reconnectSuccesses),
                    SwiftFulcrumDiagnostics.publicField("phase", isInitialConnection ? "initial" : "reconnect"),
                    SwiftFulcrumDiagnostics.publicField("unlimited", configuration.isUnlimited),
                    SwiftFulcrumDiagnostics.privateField("candidate_url", candidateURL.absoluteString)
                ]
            )

            do {
                if shouldCancelReceiver { await webSocket.cancelReceiverTask() }
                await webSocket.updateURL(candidateURL)
                try await webSocket.performConnect(
                    shouldEmitLifecycle: false,
                    shouldAllowFailover: false,
                    shouldCancelReceiver: shouldCancelReceiver,
                    failureState: .reconnecting
                )
                await webSocket.recordReconnectSuccess()
                let successSnapshot = await webSocket.makeDiagnosticsSnapshot()
                resetReconnectionAttemptCount()
                await webSocket.recordWebSocketEvent(
                    SwiftFulcrumDiagnostics.Event.reconnectSucceeded,
                    category: SwiftFulcrumDiagnostics.Category.reconnect,
                    level: .info,
                    traceID: traceID,
                    fields: [
                        SwiftFulcrumDiagnostics.publicField("attempt_total", successSnapshot.reconnectAttempts),
                        SwiftFulcrumDiagnostics.publicField("phase", isInitialConnection ? "initial" : "reconnect"),
                        SwiftFulcrumDiagnostics.publicField("success_total", successSnapshot.reconnectSuccesses),
                        SwiftFulcrumDiagnostics.privateField("candidate_url", candidateURL.absoluteString)
                    ]
                )
                await webSocket.emitLifecycle(.connected(isReconnect: !isInitialConnection))
                return
            } catch {
                await webSocket.recordWebSocketEvent(
                    SwiftFulcrumDiagnostics.Event.reconnectFailed,
                    category: SwiftFulcrumDiagnostics.Category.reconnect,
                    level: .error,
                    traceID: traceID,
                    fields: [
                        SwiftFulcrumDiagnostics.publicField("attempt", reconnectionAttempts),
                        SwiftFulcrumDiagnostics.publicField("attempt_total", attemptSnapshot.reconnectAttempts),
                        SwiftFulcrumDiagnostics.publicField("phase", isInitialConnection ? "initial" : "reconnect"),
                        SwiftFulcrumDiagnostics.publicField("success_total", attemptSnapshot.reconnectSuccesses),
                        SwiftFulcrumDiagnostics.privateField("candidate_url", candidateURL.absoluteString)
                    ] + SwiftFulcrumDiagnostics.errorFields(error)
                )
            }
        }

        await webSocket.recordWebSocketEvent(
            SwiftFulcrumDiagnostics.Event.reconnectMaxAttempts,
            category: SwiftFulcrumDiagnostics.Category.reconnect,
            level: .error,
            traceID: traceID,
            fields: [
                SwiftFulcrumDiagnostics.publicField("phase", isInitialConnection ? "initial" : "reconnect"),
                SwiftFulcrumDiagnostics.publicField("attempt_total", await webSocket.makeDiagnosticsSnapshot().reconnectAttempts),
                SwiftFulcrumDiagnostics.privateField("endpoint_url", currentURL.absoluteString)
            ]
        )
        let exhaustionReason = "Reconnection attempts exhausted."
        await webSocket.disconnect(with: exhaustionReason)
        throw SwiftFulcrum.Client.Error.transport(.connectionClosed(.goingAway, exhaustionReason))
    }
}
