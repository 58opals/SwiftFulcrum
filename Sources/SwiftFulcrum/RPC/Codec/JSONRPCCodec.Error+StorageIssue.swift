// JSONRPCCodec.Error+StorageIssue.swift

import Foundation

extension JSONRPCCodec.Error {
    enum StorageIssue {
        case unknownMethodPath(String)
    }
}
