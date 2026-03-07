// RPCRequestParametersModel.swift

import Foundation

enum RPCRequestParametersModel {
    struct EmptyModel: Encodable {
        func encode(to encoder: Encoder) throws {
            _ = encoder.unkeyedContainer()
        }
    }

    struct SingleValueModel<Value: Encodable>: Encodable {
        let value: Value

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(value)
        }
    }

    struct PairModel<First: Encodable, Second: Encodable>: Encodable {
        let first: First
        let second: Second

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(first)
            try container.encode(second)
        }
    }

    struct TripleModel<First: Encodable, Second: Encodable, Third: Encodable>: Encodable {
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

    struct HistoryModel: Encodable {
        let identifier: String
        let fromHeight: UInt?
        let toHeight: UInt?
        let shouldIncludeUnconfirmed: Bool

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(identifier)
            try container.encode(fromHeight ?? 0)
            if shouldIncludeUnconfirmed {
                try container.encode(Int(-1))
            } else if let toHeight {
                try container.encode(toHeight)
            } else {
                try container.encode(UInt.max)
            }
        }
    }

    struct OptionalTokenFilterModel: Encodable {
        let identifier: String
        let tokenFilter: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.TokenFilter?

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(identifier)
            if let tokenFilter {
                try container.encode(tokenFilter)
            }
        }
    }
}
