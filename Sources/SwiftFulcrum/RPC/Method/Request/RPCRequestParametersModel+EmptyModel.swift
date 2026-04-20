// RPCRequestParametersModel+EmptyModel.swift

import Foundation

extension RPCRequestParametersModel {
    struct EmptyModel: Encodable {
        func encode(to encoder: Encoder) throws {
            _ = encoder.unkeyedContainer()
        }
    }
}
