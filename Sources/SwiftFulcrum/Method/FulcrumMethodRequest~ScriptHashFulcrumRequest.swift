// FulcrumMethodRequest~ScriptHashFulcrumRequest.swift

import Foundation

extension FulcrumMethodRequest {
    func createScriptHashRequest(
        _ scripthash: BlockchainModel.ScriptHash,
        uuid: UUID
    ) -> FulcrumRequest {
        switch scripthash {
        case .getBalance(let scripthash, let tokenFilter):
            struct ParametersModel: Encodable {
                let scripthash: String
                let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokens.TokenFilter?
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                    if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash,
                                              tokenFilter: tokenFilter))

        case .getFirstUse(let scripthash):
            struct ParametersModel: Encodable {
                let scripthash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash))

        case .getHistory(let scripthash, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
            struct ParametersModel: Encodable {
                let scripthash: String
                let fromHeight: UInt?
                let toHeight: UInt?
                let shouldIncludeUnconfirmed: Bool
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()

                    try container.encode(scripthash)
                    try container.encode(fromHeight ?? 0)
                    if shouldIncludeUnconfirmed { try container.encode(Int(-1)) }
                    else if let toHeight { try container.encode(toHeight) }
                    else { try container.encode(UInt.max) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash,
                                              fromHeight: fromHeight,
                                              toHeight: toHeight,
                                              shouldIncludeUnconfirmed: shouldIncludeUnconfirmed))

        case .getMempool(let scripthash):
            struct ParametersModel: Encodable {
                let scripthash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash))

        case .listUnspent(let scripthash, let tokenFilter):
            struct ParametersModel: Encodable {
                let scripthash: String
                let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokens.TokenFilter?
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                    if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash,
                                              tokenFilter: tokenFilter))

        case .subscribe(let scripthash):
            struct ParametersModel: Encodable {
                let scripthash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash))

        case .unsubscribe(let scripthash):
            struct ParametersModel: Encodable {
                let scripthash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(scripthash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(scripthash: scripthash))
        }
    }
}
