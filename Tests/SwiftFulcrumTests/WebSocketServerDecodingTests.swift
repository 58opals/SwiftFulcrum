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
    
    @Test("validates bundled mainnet server list")
    func validatesBundledMainnetServerList() throws {
        let servers = try WebSocket.Server.decodeBundledServers(for: .mainnet)
        #expect(!servers.isEmpty)
        servers.forEach { url in
            #expect(["wss"].contains(url.scheme))
        }
    }
    
    @Test("validates bundled testnet server list")
    func validatesBundledTestnetServerList() throws {
        let servers = try WebSocket.Server.decodeBundledServers(for: .testnet)
        #expect(!servers.isEmpty)
        servers.forEach { url in
            #expect(["wss"].contains(url.scheme))
        }
    }
    
    @Test("separates mainnet and testnet catalogs")
    func separatesNetworkCatalogs() throws {
        let mainnet = try Set(WebSocket.Server.decodeBundledServers(for: .mainnet))
        let testnet = try Set(WebSocket.Server.decodeBundledServers(for: .testnet))
        #expect(!mainnet.isEmpty)
        #expect(!testnet.isEmpty)
        #expect(mainnet.isDisjoint(with: testnet))
    }
    
    @Test("fetchServerList honors mainnet selection")
    func fetchesMainnetCatalog() async throws {
        let decoded = try Set(WebSocket.Server.decodeBundledServers(for: .mainnet))
        let fetchedList = try await WebSocket.Server.fetchServerList(for: .mainnet)
        let fetched = Set(fetchedList)
        #expect(decoded == fetched)
    }
    
    @Test("fetchServerList honors testnet selection")
    func fetchesTestnetCatalog() async throws {
        let decoded = try Set(WebSocket.Server.decodeBundledServers(for: .testnet))
        let fetchedList = try await WebSocket.Server.fetchServerList(for: .testnet)
        let fetched = Set(fetchedList)
        #expect(decoded == fetched)
    }
}
