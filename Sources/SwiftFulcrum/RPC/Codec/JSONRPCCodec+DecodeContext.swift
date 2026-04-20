// JSONRPCCodec+DecodeContext.swift

import Foundation

extension JSONRPCCodec {
    struct DecodeContext {
        let methodPath: String?

        init(methodPath: String?) {
            self.methodPath = methodPath
        }
    }
}
