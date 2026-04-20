// PublicAPIFacadeContractValidator+SymbolGraphModel.swift

import Foundation

extension PublicAPIFacadeContractValidator {
    struct SymbolGraphModel: Decodable {
        let symbols: [SymbolModel]
    }
}
