// JSONRPCResponseDecodeModel+NilValueModel.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    protocol NilValueModel {
        static var nilValue: Self { get }
    }
}

extension Optional: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { nil }
}
