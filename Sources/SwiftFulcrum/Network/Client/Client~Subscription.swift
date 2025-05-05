// Client~Subscription.swift

import Foundation

extension Client {
    func makeUnsubscribeMethod(for key: SubscriptionKey) -> Method? {
        let methodPath = key.methodPath
        guard let identifier = key.identifier else { return nil }
        
        switch methodPath {
            case "blockchain.address.subscribe":
            return .blockchain(.address(.unsubscribe(address: identifier)))
        case "blockchain.headers.subscribe":
            return .blockchain(.headers(.unsubscribe))
        case "blockchain.transaction.subscribe":
            return .blockchain(.transaction(.unsubscribe(transactionHash: identifier)))
        case "blockchain.transaction.dsproof.subscribe":
            return .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: identifier))))
        default:
            return nil
        }
    }
}

extension Client {
    func getSubscriptionIdentifier(for method: Method) -> String? {
        switch method {
        case .blockchain(.address(.subscribe(let address))):
            return address
        case .blockchain(.transaction(.subscribe(let txid))):
            return txid
        default:
            return nil
        }
    }
    
    func getIdentifierFromNotification(methodPath: String, data: Data) -> String? {
        switch methodPath {
        case "blockchain.address.subscribe",
            "blockchain.transaction.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable { let string: String?
                init(from dec: Decoder) throws {
                    let c = try dec.singleValueContainer()
                    self.string = (try? c.decode(String.self))
                }
            }
            
            if let first = try? JSONDecoder().decode(Envelope.self, from: data).params.first?.string {
                return first
            }
            return nil
        default:
            return nil
        }
    }
}
