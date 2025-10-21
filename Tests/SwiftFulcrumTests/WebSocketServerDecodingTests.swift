import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("WebSocket.Server decoding")
struct WebSocketServerDecodingTests {
    @Test("decodes explicit websocket URLs")
    func decodesExplicitURLs() throws {
        let urlString = "wss://example.com:50004"
        let payload = Data("[{\"url\":\"\(urlString)\"}]".utf8)
        let servers = try JSONDecoder().decode([WebSocket.Server].self, from: payload)
        #expect(servers.count == 1)
        
        guard let expected = URL(string: urlString) else {
            throw Fulcrum.Error.client(.invalidURL(urlString))
        }
        
        #expect(servers[0].url == expected)
    }
    
    @Test("normalizes HTTPS endpoints to WSS")
    func normalizesHTTPSEndpoints() throws {
        let urlStringHTTPS = "https://example.com:443"
        let urlStringWSS = "wss://example.com:443"
        let payload = Data("[{\"url\":\"\(urlStringHTTPS)\"}]".utf8)
        let servers = try JSONDecoder().decode([WebSocket.Server].self, from: payload)
        #expect(servers.count == 1)
        
        guard let expected = URL(string: urlStringWSS) else {
            throw Fulcrum.Error.client(.invalidURL(urlStringWSS))
        }
        
        #expect(servers[0].url == expected)
    }
    
    @Test("validates bundled server list")
    func validatesBundledServerList() throws {
        let servers = try WebSocket.Server.decodeBundledServers()
        servers.forEach { url in
            #expect(["wss"].contains(url.scheme))
        }
    }
}
