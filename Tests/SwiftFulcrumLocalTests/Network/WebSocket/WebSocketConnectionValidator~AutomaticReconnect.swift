// WebSocketConnectionValidator~AutomaticReconnect.swift

import Foundation
import SwiftFulcrumTestSupport
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("automatic reconnect exhaustion does not await its receiver task", .timeLimit(.minutes(1)))
    func finishAutomaticReconnectExhaustionWithoutAwaitingReceiverTask() async {
        let unreachable = URL(string: "ws://127.0.0.1:9")!
        let webSocket = WebSocketConnection(
            url: unreachable,
            configuration: .init(
                serverCatalogLoader: .makeConstant([unreachable])
            ),
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 1,
                reconnectionDelay: 0,
                maximumDelay: 0,
                jitterRange: 1 ... 1
            ),
            connectionTimeout: 0.01
        )

        await webSocket.createNewTask()
        let task = await webSocket.task
        task?.resume()
        let stream = await webSocket.makeMessageStream()
        let originalStreamGenerationIdentifier = await webSocket
            .messageStreamGenerationIdentifier

        let didTerminate = await NetworkTestClient.detectStreamTermination(
            stream,
            within: .seconds(2)
        )
        #expect(didTerminate)
        #expect(await webSocket.connectionState == .disconnected)
        let didFinishReceiver = await waitUntil(timeout: .seconds(2)) {
            await webSocket.receivedTask == nil
        }
        #expect(didFinishReceiver)
        #expect(await webSocket.reconnectAttempts == 1)
        let closeInformation = await webSocket.closeInformation
        #expect(closeInformation.code == .goingAway)
        #expect(closeInformation.reason == "Reconnection attempts exhausted.")
        #expect(await webSocket.sharedMessagesStream == nil)
        #expect(await webSocket.messageContinuation == nil)

        let replacementStream = await webSocket.makeMessageStream(
            shouldEnableAutomaticResumption: false
        )
        let replacementStreamGenerationIdentifier = await webSocket
            .messageStreamGenerationIdentifier
        #expect(replacementStreamGenerationIdentifier != nil)
        #expect(
            replacementStreamGenerationIdentifier
                != originalStreamGenerationIdentifier
        )

        let replacementContinuation = await webSocket.messageContinuation
        replacementContinuation?.yield(.string("replacement-stream"))
        var replacementIterator = replacementStream.makeAsyncIterator()
        do {
            let replacementMessage = try #require(
                await replacementIterator.next()
            )
            guard case .string(let value) = replacementMessage else {
                Issue.record("Expected a string on the replacement stream")
                return
            }
            #expect(value == "replacement-stream")
        } catch {
            Issue.record("Replacement stream unexpectedly failed: \(error)")
        }

        if let replacementStreamGenerationIdentifier {
            await webSocket.resetMessageStreamAndReader(
                generationIdentifier: replacementStreamGenerationIdentifier
            )
        }

        let session = await webSocket.session
        session.invalidateAndCancel()
    }
}
