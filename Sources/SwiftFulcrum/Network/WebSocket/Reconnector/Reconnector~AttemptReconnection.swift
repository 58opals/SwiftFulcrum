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
            let reconnectAttempts = await webSocket.reconnectAttempts
            let reconnectSuccesses = await webSocket.reconnectSuccesses

            reconnectionAttempts += 1
            await OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                event: .swiftFulcrumReconnectAttempt,
                level: .info,
                traceID: traceID,
                fields: webSocket.webSocketDiagnosticFields([
                    .swiftFulcrumField("attempt", reconnectionAttempts),
                    .swiftFulcrumField("reconnect_attempts", reconnectAttempts),
                    .swiftFulcrumField("reconnect_successes", reconnectSuccesses),
                    .swiftFulcrumField("phase", isInitialConnection ? "initial" : "reconnect"),
                    .swiftFulcrumField("unlimited", configuration.isUnlimited),
                    .swiftFulcrumPrivateField("candidate_url", candidateURL.absoluteString)
                ])
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
                let reconnectAttempts = await webSocket.reconnectAttempts
                let reconnectSuccesses = await webSocket.reconnectSuccesses
                resetReconnectionAttemptCount()
                await OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumReconnectSucceeded,
                    level: .info,
                    traceID: traceID,
                    fields: webSocket.webSocketDiagnosticFields([
                        .swiftFulcrumField("reconnect_attempts", reconnectAttempts),
                        .swiftFulcrumField("phase", isInitialConnection ? "initial" : "reconnect"),
                        .swiftFulcrumField("reconnect_successes", reconnectSuccesses),
                        .swiftFulcrumPrivateField("candidate_url", candidateURL.absoluteString)
                    ])
                )
                await webSocket.emitLifecycle(.connected(isReconnect: !isInitialConnection))
                return
            } catch {
                await OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumReconnectFailed,
                    level: .info,
                    traceID: traceID,
                    fields: webSocket.webSocketDiagnosticFields([
                        .swiftFulcrumField("attempt", reconnectionAttempts),
                        .swiftFulcrumField("reconnect_attempts", reconnectAttempts),
                        .swiftFulcrumField("phase", isInitialConnection ? "initial" : "reconnect"),
                        .swiftFulcrumField("reconnect_successes", reconnectSuccesses),
                        .swiftFulcrumPrivateField("candidate_url", candidateURL.absoluteString)
                    ] + OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                )
            }
        }

        await OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumReconnectMaxAttempts,
            level: .info,
            traceID: traceID,
            fields: webSocket.webSocketDiagnosticFields([
                .swiftFulcrumField("phase", isInitialConnection ? "initial" : "reconnect"),
                .swiftFulcrumField("reconnect_attempts", await webSocket.reconnectAttempts),
                .swiftFulcrumField("reconnect_successes", await webSocket.reconnectSuccesses),
                .swiftFulcrumPrivateField("endpoint_url", currentURL.absoluteString)
            ])
        )
        let exhaustionReason = "Reconnection attempts exhausted."
        await webSocket.disconnect(with: exhaustionReason)
        throw SwiftFulcrum.Client.Error.transport(.connectionClosed(.goingAway, exhaustionReason))
    }
}
