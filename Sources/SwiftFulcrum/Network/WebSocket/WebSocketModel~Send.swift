// WebSocketModel~Send.swift

import Foundation

extension WebSocketModel {
    func send(data: Data) async throws {
        let message = URLSessionWebSocketTask.Message.data(data)
        var metadata = ["payloadType": "data",
                        "byteCount": String(data.count)]
        if let preview = makePayloadPreview(from: data) { metadata["payloadPreview"] = preview }
        try await sendMessage(message, metadata: metadata)
    }
    
    func send(string: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        var metadata = ["payloadType": "string",
                        "characterCount": String(string.count)]
        if let preview = makePayloadPreview(from: string) { metadata["payloadPreview"] = preview }
        try await sendMessage(message, metadata: metadata)
    }
    
    private func sendMessage(
        _ message: URLSessionWebSocketTask.Message,
        metadata: [String: String]
    ) async throws {
        guard let task else { throw FulcrumClient.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        let messageIdentifier = makeOutgoingMessageIdentifier()
        var metadataWithIdentifier = metadata
        metadataWithIdentifier["messageIdentifier"] = String(messageIdentifier)
        
        emitLog(.info, "send.begin", metadata: metadataWithIdentifier)
        try await task.send(message)
        await metrics?.recordSend(url: url, message: message)
        emitLog(.info, "send.succeeded", metadata: metadataWithIdentifier)
    }
    
    func makePayloadPreview(from data: Data) -> String? {
        guard let decoded = String(data: data, encoding: .utf8) else { return nil }
        return makePayloadPreview(from: decoded)
    }
    
    func makePayloadPreview(from string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let maximumLength = 120
        guard trimmed.count > maximumLength else { return trimmed }
        
        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: maximumLength)
        return "\(trimmed[..<endIndex])…"
    }
}
