// JSONRPCResponseDecodeModel+CodingKey.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct CodingKey: Swift.CodingKey, Hashable, Sendable {
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
