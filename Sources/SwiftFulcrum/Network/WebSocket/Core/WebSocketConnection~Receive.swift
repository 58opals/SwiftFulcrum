// WebSocketConnection~Receive.swift

import Foundation

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
            emitLog(.info,
                    "message_stream.reuse",
                    metadata: ["automaticResumption": String(shouldEnableAutomaticResumption)])
            if shouldEnableAutomaticResumption && receivedTask == nil { startReader() }
            return stream
        }
        
        emitLog(.info,
                "message_stream.create",
                metadata: ["automaticResumption": String(shouldEnableAutomaticResumption)])
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
        emitLog(.info, "message_stream.reset")
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
    
    private func makePayloadMetadata(for message: URLSessionWebSocketTask.Message) -> [String: String] {
        switch message {
        case .data(let data):
            var metadata = [
                "payloadType": "data",
                "length": String(data.count)
            ]
            if let preview = makePayloadPreview(from: data) {
                metadata["payloadPreview"] = preview
            }
            return metadata
        case .string(let string):
            var metadata = [
                "payloadType": "string",
                "length": String(string.count)
            ]
            if let preview = makePayloadPreview(from: string) {
                metadata["payloadPreview"] = preview
            }
            return metadata
        @unknown default:
            return [
                "payloadType": "unknown",
                "length": "0"
            ]
        }
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
                var metadata = makePayloadMetadata(for: message)
                metadata["messageIdentifier"] = String(makeIncomingMessageIdentifier())
                if !consumeQuietResponseIdentifier(for: message) {
                    emitLog(.info,
                            "receive.message",
                            metadata: metadata)
                }
                switch messageContinuation?.yield(with: .success(message)) {
                case .some(.enqueued): break
                default:
                    messageContinuation?.finish()
                    messageContinuation = nil
                    break
                }
                await metrics?.recordReceive(url: url, message: message)
            } catch let urlError as URLError where urlError.code == .cancelled {
                break
            } catch {
                if Task.isCancelled { break }
                emitLog(.warning, "receive.failed_reconnecting",
                        metadata: ["error": (error as NSError).localizedDescription])
                do {
                    await updateConnectionState(.reconnecting)
                    try await reconnector.attemptReconnection(for: self, shouldCancelReceiver: false)
                    emitLog(.info, "receive.reconnected")
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
