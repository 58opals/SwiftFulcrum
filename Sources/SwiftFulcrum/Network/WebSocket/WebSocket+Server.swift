// WebSocket+Server.swift

import Foundation

extension WebSocket {
    struct Server: Decodable {
        let host: String
        let port: Int
        
        var url: URL? {
            var component = URLComponents()
            component.scheme = "wss"
            component.host = self.host
            component.port = self.port
            
            return component.url
        }
    }
}

extension WebSocket.Server {
    private static func decodeBundledServers() throws -> [URL] {
        guard let path = Bundle.module.path(forResource: "servers", ofType: "json") else {
            throw Fulcrum.Error.transport(.setupFailed)
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let list = try JSONRPC.Coder.decoder.decode([WebSocket.Server].self, from: data)
        
        return list.compactMap(\.url)
    }
    
    static func getServerList(fallback: [URL] = []) async throws -> [URL] {
        await Task.yield()
        if let bundled = try? decodeBundledServers(), !bundled.isEmpty { return bundled }
        let sanitized = fallback.filter { ["ws","wss"].contains($0.scheme?.lowercased()) }
        guard !sanitized.isEmpty else { throw Fulcrum.Error.transport(.setupFailed) }
        return sanitized
    }
    
    static func loadServerList(fallback: [URL] = []) async throws -> [URL] {
        try await Task.detached(priority: .utility) {
            if let bundled = try? decodeBundledServers(), !bundled.isEmpty { return bundled }
            let sanitized = fallback.filter { ["ws","wss"].contains($0.scheme?.lowercased()) }
            guard !sanitized.isEmpty else { throw Fulcrum.Error.transport(.setupFailed) }
            return sanitized
        }.value
    }
}
