// ClientErrorEquatableValidator+SameMessageOne.swift

import Foundation

extension ClientErrorEquatableValidator {
    struct SameMessageOne: LocalizedError {
        var errorDescription: String? { "shared failure" }
    }
}
