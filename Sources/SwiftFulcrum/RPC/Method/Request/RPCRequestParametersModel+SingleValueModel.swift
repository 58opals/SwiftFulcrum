// RPCRequestParametersModel+SingleValueModel.swift

import Foundation

extension RPCRequestParametersModel {
    struct SingleValueModel<Value: Encodable>: Encodable {
        let value: Value

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(value)
        }
    }
}
