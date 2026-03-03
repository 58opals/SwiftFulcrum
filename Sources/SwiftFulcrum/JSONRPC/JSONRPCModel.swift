// JSONRPCModel.swift

import Foundation

struct JSONRPCModel {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPCModel.Coder.decoder
}

extension JSONRPCModel {
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

extension JSONRPCModel {
    struct DecodeContext {
        let methodPath: String?
        init(methodPath: String?) { self.methodPath = methodPath }
    }
}
