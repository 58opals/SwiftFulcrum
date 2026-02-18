// JSONRPCModel.swift

import Foundation

struct JSONRPCModel {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPCModel.CoderModel.decoder
}

extension JSONRPCModel {
    enum CoderModel {
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
    struct DecodeContextModel {
        let methodPath: String?
        init(methodPath: String?) { self.methodPath = methodPath }
    }
}
