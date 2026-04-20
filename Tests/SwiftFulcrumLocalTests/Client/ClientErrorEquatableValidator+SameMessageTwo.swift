// ClientErrorEquatableValidator+SameMessageTwo.swift

import Foundation

extension ClientErrorEquatableValidator {
    struct SameMessageTwo: LocalizedError {
        var errorDescription: String? { "shared failure" }
    }
}
