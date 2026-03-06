// Reconnector~AttemptReconnection.swift

import Foundation

extension WebSocketModel.Reconnector {
    func attemptReconnection(
        for webSocket: WebSocketModel,
        with url: URL? = nil,
        shouldCancelReceiver: Bool = true,
        isInitialConnection: Bool = false
    ) async throws {
        resetReconnectionAttemptCount()

        let currentURL = await webSocket.url
        let overrideURL = url
        var rotation = try await buildCandidateRotation(preferredURL: overrideURL, currentURL: currentURL)
        var rotationCursor = 0

        let maximumAttempts: Int
        if configuration.isUnlimited {
            maximumAttempts = Int.max
        } else if serverCatalogLoader.isBundled, overrideURL == nil {
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
        await webSocket.disconnect(with: "Reconnection attempts exhausted.")
        let closeInformation = await webSocket.closeInformation
        throw SwiftFulcrum.Client.Error.transport(
            .connectionClosed(closeInformation.code, closeInformation.reason)
        )
    }
}
