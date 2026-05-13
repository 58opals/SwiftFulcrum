// RPCRequestParametersModel+History.swift

import Foundation

extension RPCRequestParametersModel {
    struct History: Encodable {
        let identifier: String
        let fromHeight: UInt?
        let toHeight: UInt?
        let shouldIncludeUnconfirmed: Bool

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(identifier)
            try container.encode(fromHeight ?? 0)
            if let toHeight {
                try container.encode(toHeight)
            } else if shouldIncludeUnconfirmed {
                try container.encode(Int(-1))
            } else {
                try container.encode(UInt.max)
            }
        }
    }
}
