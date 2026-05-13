// RPCRequestParametersModel+SingleValue.swift

import Foundation

extension RPCRequestParametersModel {
    struct SingleValue<Value: Encodable>: Encodable {
        let value: Value

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(value)
        }
    }
}
