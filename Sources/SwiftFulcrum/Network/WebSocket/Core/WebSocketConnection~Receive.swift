// WebSocketConnection~Receive.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    private func startReader() {
        guard receivedTask == nil else { return }
        let connection = self
        receivedTask = Task {
            await connection.receiveContinuously()
        }
    }
    
    func ensureAutomaticReceiving() {
        guard shouldAutomaticallyReceive else { return }
        if sharedMessagesStream == nil {
            _ = makeMessageStream(shouldEnableAutomaticResumption: true)
            return
        }
        
        if receivedTask == nil { startReader() }
    }
    
    func makeMessageStream(shouldEnableAutomaticResumption: Bool = true) -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        shouldAutomaticallyReceive = shouldEnableAutomaticResumption
        
        if let stream = sharedMessagesStream {
            if shouldEnableAutomaticResumption && receivedTask == nil { startReader() }
            return stream
        }
        
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            self.messageContinuation = continuation
            self.startReader()
            continuation.onTermination = { @Sendable _ in
                Task { await self.resetMessageStreamAndReader() }
            }
        }
        
        sharedMessagesStream = stream
        
        return stream
    }
    
    func resetMessageStreamAndReader() async {
        await cancelReceiverTask()
        sharedMessagesStream = nil
        messageContinuation = nil
    }
    
    func makeOutgoingMessageIdentifier() -> UInt64 {
        nextOutgoingMessageIdentifier &+= 1
        return nextOutgoingMessageIdentifier
    }
    
    private func makeIncomingMessageIdentifier() -> UInt64 {
        nextIncomingMessageIdentifier &+= 1
        return nextIncomingMessageIdentifier
    }
    
    private func receiveContinuously() async {
        defer { receivedTask = nil }
        
        while !Task.isCancelled {
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
                switch messageContinuation?.yield(with: .success(message)) {
                case .some(.enqueued): break
                default:
                    messageContinuation?.finish()
                    messageContinuation = nil
                    break
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
                    try await reconnector.attemptReconnection(for: self, shouldCancelReceiver: false)
                    OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                        event: .swiftFulcrumWebSocketReceiveReconnected,
                        level: .info,
                        fields: webSocketDiagnosticFields()
                    )
                    await updateConnectionState(.connected)
                    continue
                } catch {
                    await updateConnectionState(.disconnected)
                    messageContinuation?.finish(throwing: error)
                    messageContinuation = nil
                    break
                }
            }
            
            await Task.yield()
        }
    }
}
