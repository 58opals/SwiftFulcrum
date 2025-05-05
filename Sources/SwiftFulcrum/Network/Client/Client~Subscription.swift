// Client~Subscription.swift

import Foundation

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
