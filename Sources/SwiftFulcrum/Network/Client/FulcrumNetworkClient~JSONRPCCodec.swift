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
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let parameters = object["params"] as? [Any],
              let firstParameter = parameters.first else {
            return nil
        }

        switch methodPath {
        case .scriptHash, .address, .transaction:
            return firstParameter as? String
            
        case .transactionDoubleSpendProof:
            if let string = firstParameter as? String {
                return string
            }
            if let proof = firstParameter as? [String: Any],
               let transactionIdentifier = proof["txid"] as? String {
                return transactionIdentifier
            }
            return nil
            
        case .headers:
            return nil   
        }
    }
}
