// JSONRPCCodec.swift

import Foundation

struct JSONRPCCodec {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONRPCCodec.Coder.decoder
}
