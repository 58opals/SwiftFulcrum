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
    func resubscribeStoredMethods() async {
        for method in subscriptionMethods.values {
            _ = try? await sendRegularRequest(method: method) { _ in }
        }
    }
}

extension Client {
    func removeStoredSubscriptionMethod(for key: SubscriptionKey) {
        subscriptionMethods.removeValue(forKey: key)
    }
}

extension Client {
    func getSubscriptionIdentifier(for method: Method) -> String? {
        switch method {
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
    
    func getIdentifierFromNotification(methodPath: String, data: Data) -> String? {
        switch methodPath {
        case "blockchain.address.subscribe",
            "blockchain.transaction.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable { let string: String?
                init(from dec: Decoder) throws {
                    let c = try dec.singleValueContainer()
                    self.string = try? c.decode(String.self)
                }
            }
            
            if let first = try? JSONRPC.Coder.decoder.decode(Envelope.self, from: data).params.first?.string {
                return first
            }
            return nil
        case "blockchain.transaction.dsproof.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable {
                let string: String?
                let dsProof: DSProof?
                
                struct DSProof: Decodable { let txid: String }
                
                init(from dec: Decoder) throws {
                    let container = try dec.singleValueContainer()
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
