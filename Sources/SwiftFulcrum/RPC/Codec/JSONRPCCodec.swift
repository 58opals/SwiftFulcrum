import Foundation

struct JSONRPCCodec {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPCCodec.Coder.decoder
}

extension JSONRPCCodec {
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

extension JSONRPCCodec {
    struct DecodeContext {
        let methodPath: String?
        init(methodPath: String?) { self.methodPath = methodPath }
    }
}
