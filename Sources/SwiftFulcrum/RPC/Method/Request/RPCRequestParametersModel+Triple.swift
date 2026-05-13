// RPCRequestParametersModel+Triple.swift

import Foundation

extension RPCRequestParametersModel {
    struct Triple<First: Encodable, Second: Encodable, Third: Encodable>: Encodable {
        let first: First
        let second: Second
        let third: Third

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(first)
            try container.encode(second)
            try container.encode(third)
        }
    }
}
