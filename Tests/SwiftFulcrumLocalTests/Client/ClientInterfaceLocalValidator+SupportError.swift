// ClientInterfaceLocalValidator+SupportError.swift

import Foundation

extension ClientInterfaceLocalValidator {
    enum SupportError: Swift.Error {
        case missingRequestIdentifier
    }
}
