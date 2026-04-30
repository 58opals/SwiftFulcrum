// WebSocketConnection~Logging.swift

import Foundation

extension WebSocketConnection {
    func emitLog(
        _ level: SwiftFulcrum.Logging.Level,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = .init(),
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        if LoggingBehaviorState.behavior == .quiet && level.priority <= SwiftFulcrum.Logging.Level.info.priority {
            return
        }
        
        var mergedMetadata = [
            "component": "WebSocketConnection",
            "url": url.absoluteString,
            "network": network.resourceName
        ]
        mergedMetadata.merge(metadata, uniquingKeysWith: { _, new in new })
        logger.log(level, message(), metadata: mergedMetadata, file: file, function: function, line: line)
    }
    
    func registerQuietResponse(for identifier: UUID) {
        quietResponseIdentifiers.insert(identifier)
    }

    func unregisterQuietResponse(for identifier: UUID) {
        quietResponseIdentifiers.remove(identifier)
    }
    
    func consumeQuietResponseIdentifier(for message: URLSessionWebSocketTask.Message) -> Bool {
        let data: Data
        
        switch message {
        case .data(let raw):
            data = raw
        case .string(let string):
            guard let converted = string.data(using: .utf8) else { return false }
            data = converted
        @unknown default:
            return false
        }
        
        guard
            case .uuid(let identifier) = try? SwiftFulcrum.RPC.Response.JSONRPC.extractIdentifier(from: data),
            quietResponseIdentifiers.remove(identifier) != nil
        else { return false }
        
        return true
    }
}
