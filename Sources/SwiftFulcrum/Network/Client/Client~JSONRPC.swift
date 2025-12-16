// Client~JSONRPC.swift

import Foundation

extension Client {
    struct SubscriptionKey {
        let methodPath: String
        let identifier: String?
        
        var string: String { identifier.map {"\(methodPath):\($0)"} ?? methodPath }
    }
}

extension Client: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id
    }
}

extension Client.SubscriptionKey: Hashable, Sendable {}

extension Client {
    static func makeSubscriptionIdentifier(methodPath: String, data: Data) -> String? {
        switch methodPath {
        case "blockchain.scripthash.subscribe", "blockchain.address.subscribe", "blockchain.transaction.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable {
                let string: String?
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    self.string = try? container.decode(String.self)
                }
            }
            return try? JSONRPC.Coder.decoder
                .decode(Envelope.self, from: data).params.first?.string
            
        case "blockchain.transaction.dsproof.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable {
                let string: String?
                let dsProof: DSProof?
                struct DSProof: Decodable { let txid: String }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    self.string = try? container.decode(String.self)
                    self.dsProof = try? container.decode(DSProof.self)
                }
            }
            if let first = try? JSONRPC.Coder.decoder.decode(Envelope.self, from: data).params.first {
                if let string = first.string { return string }
                if let proof = first.dsProof { return proof.txid }
            }
            return nil
            
        default:
            return nil
        }
    }
}
