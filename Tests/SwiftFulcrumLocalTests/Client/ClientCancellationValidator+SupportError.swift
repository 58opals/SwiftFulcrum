// ClientCancellationValidator+SupportError.swift

import Foundation

extension ClientCancellationValidator {
    enum SupportError: Swift.Error {
        case missingRequestIdentifier
    }
}
