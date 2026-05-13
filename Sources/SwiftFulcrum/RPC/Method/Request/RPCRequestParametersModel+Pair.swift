// RPCRequestParametersModel+Pair.swift

import Foundation

extension RPCRequestParametersModel {
    struct Pair<First: Encodable, Second: Encodable>: Encodable {
        let first: First
        let second: Second

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(first)
            try container.encode(second)
        }
    }
}
