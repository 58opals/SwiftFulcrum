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
    
    static func getServerList() async throws -> [URL] {
        await Task.yield()
        return try decodeBundledServers()
    }
    
    static func loadServerList() async throws -> [URL] {
        try await Task.detached(priority: .utility) {
            guard let path = Bundle.module.path(forResource: "servers", ofType: "json") else {
                throw Fulcrum.Error.transport(.setupFailed)
            }
            
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let list = try JSONRPC.Coder.decoder.decode([WebSocket.Server].self, from: data)
            
            return list.compactMap(\.url)
        }.value
    }
}
