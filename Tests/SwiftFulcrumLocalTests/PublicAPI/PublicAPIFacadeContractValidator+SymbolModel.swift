// PublicAPIFacadeContractValidator+SymbolModel.swift

import Foundation

extension PublicAPIFacadeContractValidator {
    struct SymbolModel: Decodable {
        let pathComponents: [String]
    }
}
