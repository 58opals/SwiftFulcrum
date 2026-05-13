// RPCRequestParametersModel+Empty.swift

import Foundation

extension RPCRequestParametersModel {
    struct Empty: Encodable {
        func encode(to encoder: Encoder) throws {
            _ = encoder.unkeyedContainer()
        }
    }
}
