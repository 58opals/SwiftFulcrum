// Client~JSONRPCModel.swift

import Foundation

extension Client {
    struct SubscriptionKeyModel {
        let methodPath: SubscriptionPathConfiguration
        let identifier: String?
        
        var string: String { identifier.map {"\(methodPath.rawValue):\($0)"} ?? methodPath.rawValue }
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

extension Client.SubscriptionKeyModel: Hashable, Sendable {}

extension Client {
    static func makeSubscriptionIdentifier(methodPath: String, data: Data) -> String? {
        guard let subscriptionPath = SubscriptionPathConfiguration(rawValue: methodPath) else { return nil }
        return makeSubscriptionIdentifier(methodPath: subscriptionPath, data: data)
    }
    
    static func makeSubscriptionIdentifier(methodPath: SubscriptionPathConfiguration, data: Data) -> String? {
        switch methodPath {
        case .scriptHash, .address, .transaction:
            struct EnvelopeModel: Decodable { let params: [DecodableValueModel] }
            struct DecodableValueModel: Decodable {
                let string: String?
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    self.string = try? container.decode(String.self)
                }
            }
            return try? JSONRPCModel.CoderModel.decoder
                .decode(EnvelopeModel.self, from: data).params.first?.string
            
        case .transactionDoubleSpendProof:
            struct EnvelopeModel: Decodable { let params: [DecodableValueModel] }
            struct DecodableValueModel: Decodable {
                let string: String?
                let dsProof: DSProofModel?
                struct DSProofModel: Decodable { let txid: String }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    self.string = try? container.decode(String.self)
                    self.dsProof = try? container.decode(DSProofModel.self)
                }
            }
            if let first = try? JSONRPCModel.CoderModel.decoder.decode(EnvelopeModel.self, from: data).params.first {
                if let string = first.string { return string }
                if let proof = first.dsProof { return proof.txid }
            }
            return nil
            
        case .headers:
            return nil   
        }
    }
}
