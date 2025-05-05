// JSONRPC.swift

import Foundation

struct JSONRPC {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPC.Coder.decoder
}

extension JSONRPC {
    enum Coder {
        static let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            return encoder
        }()
        static let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            return decoder
        }()
    }
}
