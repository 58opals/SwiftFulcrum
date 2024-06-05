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
    static var samples: [URL] {
        let jsonString =
"""
[
    {
    "host": "electrum.imaginary.cash",
    "port": 50004
    },
    {
    "host": "bch.imaginary.cash",
    "port": 50004
    },
    {
    "host": "cashnode.bch.ninja",
    "port": 50004
    }
]
"""
        
        do {
            guard let data = jsonString.data(using: .utf8) else { fatalError() }
            let decoder = JSONDecoder()
            let servers = try decoder.decode([WebSocket.Server].self, from: data)
            return servers.compactMap { $0.url }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
