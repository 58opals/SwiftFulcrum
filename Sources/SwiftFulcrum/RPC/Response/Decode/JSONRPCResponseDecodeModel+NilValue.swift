// JSONRPCResponseDecodeModel+NilValue.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    protocol NilValue {
        static var nilValue: Self { get }
    }
}

extension Optional: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { nil }
}
