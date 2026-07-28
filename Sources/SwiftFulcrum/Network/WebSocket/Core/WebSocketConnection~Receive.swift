// WebSocketConnection~Receive.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    private func startReader(generationIdentifier: UUID) {
        guard receivedTask == nil,
              readerStartSuppressionCount == 0,
              messageStreamGenerationIdentifier == generationIdentifier else {
            return
        }
        let connection = self
        receivedTask = Task {
            await connection.receiveContinuously(
                generationIdentifier: generationIdentifier
            )
        }
        receiverMessageStreamGenerationIdentifier = generationIdentifier
    }

    func ensureAutomaticReceiving() {
        guard shouldAutomaticallyReceive else { return }
        if sharedMessagesStream == nil {
            _ = makeMessageStream(shouldEnableAutomaticResumption: true)
            return
        }

        if receivedTask == nil, let messageStreamGenerationIdentifier {
            startReader(generationIdentifier: messageStreamGenerationIdentifier)
        }
    }

    func makeMessageStream(shouldEnableAutomaticResumption: Bool = true) -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        shouldAutomaticallyReceive = shouldEnableAutomaticResumption

        if let stream = sharedMessagesStream {
            if shouldEnableAutomaticResumption,
               receivedTask == nil,
               let messageStreamGenerationIdentifier {
                startReader(generationIdentifier: messageStreamGenerationIdentifier)
            }
            return stream
        }

        let generationIdentifier = UUID()
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            self.messageStreamGenerationIdentifier = generationIdentifier
            self.messageContinuation = continuation
            self.startReader(generationIdentifier: generationIdentifier)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { [weak self] in
                    await self?.resetMessageStreamAndReader(
                        generationIdentifier: generationIdentifier
                    )
                }
            }
        }

        sharedMessagesStream = stream

        return stream
    }

    func resetMessageStreamAndReader(generationIdentifier: UUID) async {
        guard messageStreamGenerationIdentifier == generationIdentifier else { return }
        readerStartSuppressionCount += 1
        defer {
            readerStartSuppressionCount -= 1
        }
        if receiverMessageStreamGenerationIdentifier == generationIdentifier {
            await cancelReceiverTask()
        }
        guard messageStreamGenerationIdentifier == generationIdentifier else { return }
        sharedMessagesStream = nil
        messageContinuation = nil
        messageStreamGenerationIdentifier = nil
    }

    func makeOutgoingMessageIdentifier() -> UInt64 {
        nextOutgoingMessageIdentifier &+= 1
        return nextOutgoingMessageIdentifier
    }

    private func makeIncomingMessageIdentifier() -> UInt64 {
        nextIncomingMessageIdentifier &+= 1
        return nextIncomingMessageIdentifier
    }

    private func receiveContinuously(generationIdentifier: UUID) async {
        defer {
            if receiverMessageStreamGenerationIdentifier == generationIdentifier {
                receivedTask = nil
                receiverMessageStreamGenerationIdentifier = nil
            }
        }

        while !Task.isCancelled {
            guard messageStreamGenerationIdentifier == generationIdentifier else { break }
            guard let task = task else { break }

            do {
                let message = try await withTaskCancellationHandler {
                    try await task.receive()
                } onCancel: {
                    task.cancel(with: .goingAway, reason: nil)
                }
                let messageIdentifier = makeIncomingMessageIdentifier()
                OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                    event: .swiftFulcrumWebSocketReceiveMessage,
                    level: .debug,
                    fields: webSocketDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumPayloadFields(for: message) + [
                        .swiftFulcrumField("message_id", messageIdentifier)
                    ])
                )
                guard messageStreamGenerationIdentifier == generationIdentifier,
                      case .some(.enqueued) = messageContinuation?.yield(with: .success(message)) else {
                    finishMessageStream(generationIdentifier: generationIdentifier)
                    return
                }
            } catch let urlError as URLError where urlError.code == .cancelled {
                break
            } catch {
                if Task.isCancelled { break }
                OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                    event: .swiftFulcrumWebSocketReceiveFailed,
                    level: .info,
                    fields: webSocketDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                )
                do {
                    await updateConnectionState(.reconnecting)
                    try await reconnector.attemptReconnection(for: self, attempt: .automaticReconnect)
                    OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                        event: .swiftFulcrumWebSocketReceiveReconnected,
                        level: .info,
                        fields: webSocketDiagnosticFields()
                    )
                    await updateConnectionState(.connected)
                    continue
                } catch {
                    await updateConnectionState(.disconnected)
                    finishMessageStream(
                        generationIdentifier: generationIdentifier,
                        throwing: error
                    )
                    break
                }
            }

            await Task.yield()
        }
    }

    private func finishMessageStream(
        generationIdentifier: UUID,
        throwing error: Swift.Error? = nil
    ) {
        guard messageStreamGenerationIdentifier == generationIdentifier else { return }
        if let error {
            messageContinuation?.finish(throwing: error)
        } else {
            messageContinuation?.finish()
        }
        sharedMessagesStream = nil
        messageContinuation = nil
        messageStreamGenerationIdentifier = nil
    }
}
