// WebSocketConnection+Server.swift

import Foundation

extension WebSocketConnection {
    struct Server: Decodable, Sendable {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        init(from decoder: Decoder) throws {
            let codingPath = decoder.codingPath
            
            if let singleValue = try? decoder.singleValueContainer(),
               let rawURL = try? singleValue.decode(String.self) {
                self.url = try Self.normalizeURL(from: rawURL, codingPath: codingPath)
                return
            }
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let rawURL = try container.decodeIfPresent(String.self, forKey: .url) {
                self.url = try Self.normalizeURL(from: rawURL, codingPath: container.codingPath)
                return
            }
            
            let host = try container.decodeIfPresent(String.self, forKey: .host)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !host.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .host, in: container, debugDescription: "Host must not be empty.")
            }
            
            let port = try container.decodeIfPresent(Int.self, forKey: .port)
            let scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
            
            self.url = try Self.normalizeURL(host: host, port: port, scheme: scheme, codingPath: container.codingPath)
        }
        
        private static func normalizeURL(from rawValue: String, codingPath: [CodingKey]) throws -> URL {
            let trimmedRawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let rawComponents = URLComponents(string: trimmedRawValue) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to parse URL string: \(rawValue)"
                ))
            }
            
            try validateNoUserInfo(in: rawComponents, codingPath: codingPath)
            var components = rawComponents
            components.scheme = try normalizeScheme(from: rawComponents.scheme, codingPath: codingPath)
            
            guard let result = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from components: \(rawValue)"
                ))
            }
            guard let host = result.host,
                  !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Host must not be empty."
                ))
            }
            _ = try validatePort(result.port, codingPath: codingPath)
            
            return result
        }
        
        private static func normalizeURL(host: String, port: Int?, scheme: String?, codingPath: [CodingKey]) throws -> URL {
            var components = URLComponents()
            components.host = host
            components.port = try validatePort(port, codingPath: codingPath)
            components.scheme = try normalizeScheme(from: scheme, codingPath: codingPath)
            
            guard let url = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from host/port: \(host):\(port.map(String.init) ?? "")"
                ))
            }
            
            return url
        }

        private static func validateNoUserInfo(in components: URLComponents, codingPath: [CodingKey]) throws {
            guard components.user == nil, components.password == nil else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Server URL must not contain user info."
                ))
            }
        }

        private static func validatePort(_ port: Int?, codingPath: [CodingKey]) throws -> Int? {
            guard let port else { return nil }
            guard (1 ... 65_535).contains(port) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Port must be between 1 and 65535."
                ))
            }
            return port
        }
        
        private static func normalizeScheme(from rawScheme: String?, codingPath: [CodingKey]) throws -> String {
            let rawScheme = rawScheme?.trimmingCharacters(in: .whitespacesAndNewlines)
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

extension WebSocketConnection.Server {
    static func decodeBundledServers(for network: SwiftFulcrum.Client.Configuration.Network) throws -> [URL] {
        guard let path = Bundle.module.path(forResource: network.resourceName, ofType: "json") else {
            throw SwiftFulcrum.Client.Error.transport(.setupFailed)
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let list = try JSONRPCCodec.Coder.decoder.decode([WebSocketConnection.Server].self, from: data)
        
        return list.map(\.url)
    }
}
