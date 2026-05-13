// RPCRequestParametersModel+OptionalTokenFilter.swift

import Foundation

extension RPCRequestParametersModel {
    struct OptionalTokenFilter: Encodable {
        let identifier: String
        let tokenFilter: SwiftFulcrum.CashTokens.TokenFilter?

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(identifier)
            if let tokenFilter {
                try container.encode(tokenFilter)
            }
        }
    }
}
