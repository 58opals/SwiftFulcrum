// WebSocketModel+ServerModel.swift

import Foundation

extension WebSocketModel {
    struct ServerModel: Decodable, Sendable {
        private enum CodingKeysModel: String, CodingKey {
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
                self.url = try Self.normalizeURL(from: rawURL, codingPath: codingPath)
                return
            }
            
            let container = try decoder.container(keyedBy: CodingKeysModel.self)
            
            if let rawURL = try container.decodeIfPresent(String.self, forKey: .url) {
                self.url = try Self.normalizeURL(from: rawURL, codingPath: container.codingPath)
                return
            }
            
            let host = try container.decodeIfPresent(String.self, forKey: .host)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !host.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .host, in: container, debugDescription: "HostModel must not be empty.")
            }
            
            let port = try container.decodeIfPresent(Int.self, forKey: .port)
            let scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
            
            self.url = try Self.normalizeURL(host: host, port: port, scheme: scheme, codingPath: container.codingPath)
        }
        
        private static func normalizeURL(from rawValue: String, codingPath: [CodingKey]) throws -> URL {
            guard let rawComponents = URLComponents(string: rawValue) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to parse URL string: \(rawValue)"
                ))
            }
            
            var components = rawComponents
            components.scheme = try normalizeScheme(from: rawComponents.scheme, codingPath: codingPath)
            
            guard let result = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from components: \(rawValue)"
                ))
            }
            
            return result
        }
        
        private static func normalizeURL(host: String, port: Int?, scheme: String?, codingPath: [CodingKey]) throws -> URL {
            var components = URLComponents()
            components.host = host
            components.port = port
            components.scheme = try normalizeScheme(from: scheme, codingPath: codingPath)
            
            guard let url = components.url else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: codingPath,
                    debugDescription: "Unable to construct URL from host/port: \(host):\(port.map(String.init) ?? "")"
                ))
            }
            
            return url
        }
        
        private static func normalizeScheme(from rawScheme: String?, codingPath: [CodingKey]) throws -> String {
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

extension WebSocketModel.ServerModel {
    static func decodeBundledServers(for network: FulcrumClient.Configuration.NetworkModel) throws -> [URL] {
        guard let path = Bundle.module.path(forResource: network.resourceName, ofType: "json") else {
            throw FulcrumClient.Error.transport(.setupFailed)
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let list = try JSONRPCModel.CoderModel.decoder.decode([WebSocketModel.ServerModel].self, from: data)
        
        return list.map(\.url)
    }
}
