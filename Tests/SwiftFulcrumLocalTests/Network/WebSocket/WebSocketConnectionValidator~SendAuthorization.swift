// WebSocketConnectionValidator~SendAuthorization.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("WebSocket rejects unauthorized messages before handing them to URLSession",
          .timeLimit(.minutes(1)), arguments: [false, true])
    func rejectUnauthorizedWebSocketSend(stringPayload: Bool) async throws {
        let webSocket = WebSocketConnection(url: try #require(URL(string: "ws://example.invalid")))
        // Create a genuine, unresumed Foundation task. A mistakenly submitted message would
        // remain queued, so rejection must finish before the session is invalidated below.
        await webSocket.createNewTask()
        let transport = WebSocketTransport(webSocket: webSocket)
        let completion = ClientCancellationValidator.CancellationCompletionState()
        let send = Task {
            do {
                let authorization = SwiftFulcrum.Client.Call.SendAuthorization { false }
                if stringPayload {
                    try await transport.send(string: "public test", sendAuthorization: authorization)
                } else {
                    try await transport.send(data: Data([1, 2, 3]), sendAuthorization: authorization)
                }
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }
        let rejectedBeforeSessionInvalidation = await waitUntil(timeout: .seconds(1)) {
            await completion.isCompleted
        }
        #expect(rejectedBeforeSessionInvalidation)
        #expect(await completion.recordedError == .client(.sendNotAuthorized))
        let session = await webSocket.session
        session.invalidateAndCancel()
        if rejectedBeforeSessionInvalidation {
            await send.value
        } else {
            // A regressed handoff can remain queued on this unresumed Foundation task.
            // Report the failure without waiting for that uncooperative queue to complete.
            send.cancel()
        }
    }
}
