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
    static func getServerList() throws -> [URL] {
        guard let serverListPath = Bundle.module.path(forResource: "servers", ofType: "json") else {
            throw Fulcrum.Error.transport(.setupFailed) }
        let serverListString = try String(contentsOfFile: serverListPath, encoding: .utf8)
        guard let serverListData = serverListString.data(using: .utf8) else { throw Fulcrum.Error.transport(.setupFailed) }
        let serverList = try JSONRPC.Coder.decoder.decode([WebSocket.Server].self, from: serverListData)
        return serverList.compactMap { $0.url }
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
