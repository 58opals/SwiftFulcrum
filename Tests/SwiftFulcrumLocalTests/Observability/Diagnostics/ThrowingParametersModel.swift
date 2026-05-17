// ThrowingParametersModel.swift

import Foundation

struct ThrowingParametersModel: Encodable {
    func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue(
            "throwing-parameters",
            .init(codingPath: encoder.codingPath, debugDescription: "Intentional test encoding failure.")
        )
    }
}
