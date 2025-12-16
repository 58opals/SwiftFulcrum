// JSONRPC.swift

import Foundation

struct JSONRPC {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPC.Coder.decoder
}

extension JSONRPC {
    enum Coder {
        static var encoder: JSONEncoder {
            let encoder = JSONEncoder()
            return encoder
        }
        
        static var decoder: JSONDecoder {
            let decoder = JSONDecoder()
            return decoder
        }
    }
}

extension JSONRPC {
    struct DecodeContext {
        let methodPath: String?
        init(methodPath: String?) { self.methodPath = methodPath }
    }
}
