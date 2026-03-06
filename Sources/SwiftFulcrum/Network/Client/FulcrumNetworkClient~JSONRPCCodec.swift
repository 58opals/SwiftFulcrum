// FulcrumNetworkClient~JSONRPCCodec.swift

import Foundation

extension FulcrumNetworkClient: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FulcrumNetworkClient, rhs: FulcrumNetworkClient) -> Bool {
        lhs.id == rhs.id
    }
}

extension FulcrumNetworkClient {
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
            return try? JSONRPCCodec.Coder.decoder
                .decode(EnvelopeModel.self, from: data).params.first?.string
            
        case .transactionDoubleSpendProof:
            struct EnvelopeModel: Decodable { let params: [DecodableValueModel] }
            struct DecodableValueModel: Decodable {
                let string: String?
                let dsProof: DSProof?
                struct DSProof: Decodable { let txid: String }
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    self.string = try? container.decode(String.self)
                    self.dsProof = try? container.decode(DSProof.self)
                }
            }
            if let first = try? JSONRPCCodec.Coder.decoder.decode(EnvelopeModel.self, from: data).params.first {
                if let string = first.string { return string }
                if let proof = first.dsProof { return proof.txid }
            }
            return nil
            
        case .headers:
            return nil   
        }
    }
}
