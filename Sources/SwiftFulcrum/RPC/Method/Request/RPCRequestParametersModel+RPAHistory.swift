// RPCRequestParametersModel+RPAHistory.swift

import Foundation

extension RPCRequestParametersModel {
    struct RPAHistory: Encodable {
        let prefix: String
        let fromHeight: UInt
        let toHeight: UInt?

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(prefix)
            try container.encode(fromHeight)

            if let toHeight {
                try container.encode(toHeight)
            } else {
                try container.encode(Int(-1))
            }
        }
    }
}
