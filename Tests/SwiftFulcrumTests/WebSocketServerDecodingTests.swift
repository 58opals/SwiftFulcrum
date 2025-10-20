import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("WebSocket.Server decoding")
struct WebSocketServerDecodingTests {
    enum TestError: Swift.Error {
        case invalidURL(String)
    }
    
    @Test("decodes explicit websocket URLs")
    func decodesExplicitURLs() throws {
        let payload = Data("[{\"url\":\"wss://example.com:50004\"}]".utf8)
        let servers = try JSONDecoder().decode([WebSocket.Server].self, from: payload)
        #expect(servers.count == 1)
        
        guard let expected = URL(string: "wss://example.com:50004") else {
            throw TestError.invalidURL("wss://example.com:50004")
        }
        
        #expect(servers[0].url == expected)
    }
    
    @Test("normalizes HTTPS endpoints to WSS")
    func normalizesHTTPSEndpoints() throws {
        let payload = Data("[{\"url\":\"https://example.com:443\"}]".utf8)
        let servers = try JSONDecoder().decode([WebSocket.Server].self, from: payload)
        #expect(servers.count == 1)
        
        guard let expected = URL(string: "wss://example.com:443") else {
            throw TestError.invalidURL("wss://example.com:443")
        }
        
        #expect(servers[0].url == expected)
    }
    
    @Test("supports legacy host/port records")
    func supportsLegacyHostPort() throws {
        let payload = Data("[{\"host\":\"legacy.example.com\",\"port\":50004}]".utf8)
        let servers = try JSONDecoder().decode([WebSocket.Server].self, from: payload)
        #expect(servers.count == 1)
        
        guard let expected = URL(string: "wss://legacy.example.com:50004") else {
            throw TestError.invalidURL("wss://legacy.example.com:50004")
        }
        
        #expect(servers[0].url == expected)
    }
}
