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
        guard let serverListPath = Bundle.module.path(forResource: "servers", ofType: "json") else { throw WebSocket.Error.initializing(reason: .cannotGetServerList, description: "Cannot get string from servers.json.") }
        let serverListString = try String(contentsOfFile: serverListPath, encoding: .utf8)
        guard let serverListData = serverListString.data(using: .utf8) else { throw WebSocket.Error.initializing(reason: .cannotGetServerList, description: "Failed to convert server list string to data.") }
        let decoder = JSONDecoder()
        let serverList = try decoder.decode([WebSocket.Server].self, from: serverListData)
        return serverList.compactMap { $0.url }
    }
    
    static func loadServerList() async throws -> [URL] {
        try await Task.detached(priority: .utility) {
            guard let path = Bundle.module.path(forResource: "servers", ofType: "json") else {
                throw WebSocket.Error.initializing(reason: .cannotGetServerList, description: "servers.json missing")
            }
            
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let list = try JSONDecoder().decode([WebSocket.Server].self, from: data)
            
            return list.compactMap(\.url)
        }.value
    }
}
