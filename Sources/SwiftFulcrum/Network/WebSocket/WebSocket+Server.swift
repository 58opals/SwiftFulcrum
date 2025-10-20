// WebSocket+Server.swift

import Foundation

extension WebSocket {
    struct Server: Decodable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case host
            case port
            case scheme
            case url
        }
        
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        init(from decoder: Decoder) throws {
            let codingPath = decoder.codingPath
            
            if let singleValue = try? decoder.singleValueContainer(),
               let rawURL = try? singleValue.decode(String.self) {
                self.url = try Self.normalizedURL(from: rawURL, codingPath: codingPath)
                return
            }
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let rawURL = try container.decodeIfPresent(String.self, forKey: .url) {
                self.url = try Self.normalizedURL(from: rawURL, codingPath: container.codingPath)
                return
            }
            
            let host = try container.decodeIfPresent(String.self, forKey: .host)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !host.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .host, in: container, debugDescription: "Host must not be empty.")
            }
            
            let port = try container.decodeIfPresent(Int.self, forKey: .port)
            let scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
            
            self.url = try Self.normalizedURL(host: host, port: port, scheme: scheme, codingPath: container.codingPath)
        }
        
        private static func normalizedURL(from rawValue: String, codingPath: [CodingKey]) throws -> URL {
            guard let rawComponents = URLComponents(string: rawValue) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to parse URL string: \(rawValue)"
                ))
            }
            
            var components = rawComponents
            components.scheme = try normalizedScheme(from: rawComponents.scheme, codingPath: codingPath)
            
            guard let result = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from components: \(rawValue)"
                ))
            }
            
            return result
        }
        
        private static func normalizedURL(host: String, port: Int?, scheme: String?, codingPath: [CodingKey]) throws -> URL {
            var components = URLComponents()
            components.host = host
            components.port = port
            components.scheme = try normalizedScheme(from: scheme, codingPath: codingPath)
            
            guard let url = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from host/port: \(host):\(port.map(String.init) ?? "")"
                ))
            }
            
            return url
        }
        
        private static func normalizedScheme(from rawScheme: String?, codingPath: [CodingKey]) throws -> String {
            guard let rawScheme, !rawScheme.isEmpty else { return "wss" }
            
            switch rawScheme.lowercased() {
            case "wss", "ws":
                return rawScheme.lowercased()
            case "https":
                return "wss"
            case "http":
                return "ws"
            default:
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unsupported URL scheme: \(rawScheme)"
                ))
            }
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
        
        return list.map(\.url)
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
