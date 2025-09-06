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
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id
    }
}

extension Client.SubscriptionKey: Hashable, Sendable {}

extension Client {
    static func subscriptionIdentifier(methodPath: String, data: Data) -> String? {
        switch methodPath {
        case "blockchain.address.subscribe", "blockchain.transaction.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable {
                let string: String?
                init(from dec: Decoder) throws {
                    let c = try dec.singleValueContainer()
                    self.string = try? c.decode(String.self)
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
                init(from dec: Decoder) throws {
                    let c = try dec.singleValueContainer()
                    self.string = try? c.decode(String.self)
                    self.dsProof = try? c.decode(DSProof.self)
                }
            }
            if let first = try? JSONRPC.Coder.decoder.decode(Envelope.self, from: data).params.first {
                if let s = first.string { return s }
                if let p = first.dsProof { return p.txid }
            }
            return nil

        default:
            return nil
        }
    }
}
