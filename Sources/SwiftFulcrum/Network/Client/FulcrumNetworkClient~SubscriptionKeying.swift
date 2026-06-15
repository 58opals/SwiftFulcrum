// FulcrumNetworkClient~SubscriptionKeying.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func makeUnsubscribeMethod(for key: SubscriptionKey) -> SwiftFulcrum.RPC.Method? {
        switch key.methodPath {
        case .scriptHash:
            guard let id = key.identifier else { return nil }
            return .blockchain(.scripthash(.unsubscribe(scripthash: id)))
        case .address:
            guard let id = key.identifier else { return nil }
            return .blockchain(.address(.unsubscribe(address: id)))
        case .headers:
            return .blockchain(.headers(.unsubscribe))
        case .transaction:
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.unsubscribe(transactionHash: id)))
        case .transactionDoubleSpendProof:
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: id))))
        }
    }
}

extension FulcrumNetworkClient {
    func deriveSubscriptionIdentifier(for method: SwiftFulcrum.RPC.Method) -> String? {
        switch method {
        case .blockchain(.scripthash(.subscribe(scripthash: let scripthash))):
            return scripthash
        case .blockchain(.address(.subscribe(let address))):
            return address
        case .blockchain(.transaction(.subscribe(let txid))):
            return txid
        case .blockchain(.transaction(.dsProof(.subscribe(let txid)))):
            return txid
        default:
            return nil
        }
    }
}
