// PublicAPIFacadeContractValidator+SupportError.swift

import Foundation

extension PublicAPIFacadeContractValidator {
    enum SupportError: Swift.Error {
        case missingGeneratedSymbolGraph(String)
    }
}
