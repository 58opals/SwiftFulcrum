// JSONRPCCodec+Coder.swift

import Foundation

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
