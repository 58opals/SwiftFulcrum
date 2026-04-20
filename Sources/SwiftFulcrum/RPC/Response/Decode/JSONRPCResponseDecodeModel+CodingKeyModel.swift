// JSONRPCResponseDecodeModel+CodingKeyModel.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct CodingKeyModel: CodingKey, Hashable, Sendable {
        let stringValue: String
        let intValue: Int? = nil

        init(_ stringValue: String) {
            self.stringValue = stringValue
        }

        init?(stringValue: String) {
            self.init(stringValue)
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
