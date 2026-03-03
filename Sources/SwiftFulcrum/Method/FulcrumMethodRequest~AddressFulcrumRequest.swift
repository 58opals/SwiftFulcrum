// FulcrumMethodRequest~AddressFulcrumRequest.swift

import Foundation

extension FulcrumMethodRequest {
    func createAddressRequest(_ address: BlockchainModel.Address, uuid: UUID) -> FulcrumRequest {
        switch address {
        case .getBalance(let address, let tokenFilter):
            struct ParametersModel: Encodable {
                let address: String
                let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokens.TokenFilter?
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                    if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address,
                                              tokenFilter: tokenFilter))

        case .getFirstUse(let address):
            struct ParametersModel: Encodable {
                let address: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address))

        case .getHistory(let address, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
            struct ParametersModel: Encodable {
                let address: String
                let fromHeight: UInt?
                let toHeight: UInt?
                let shouldIncludeUnconfirmed: Bool
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()

                    try container.encode(address)
                    try container.encode(fromHeight ?? 0)
                    if shouldIncludeUnconfirmed { try container.encode(Int(-1)) }
                    else if let toHeight { try container.encode(toHeight) }
                    else { try container.encode(UInt.max) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address,
                                              fromHeight: fromHeight,
                                              toHeight: toHeight,
                                              shouldIncludeUnconfirmed: shouldIncludeUnconfirmed))

        case .getMempool(let address):
            struct ParametersModel: Encodable {
                let address: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address))

        case .getScriptHash(let address):
            struct ParametersModel: Encodable {
                let address: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address))

        case .listUnspent(let address, let tokenFilter):
            struct ParametersModel: Encodable {
                let address: String
                let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokens.TokenFilter?
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                    if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address,
                                              tokenFilter: tokenFilter))

        case .subscribe(let address):
            struct ParametersModel: Encodable {
                let address: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address))

        case .unsubscribe(let address):
            struct ParametersModel: Encodable {
                let address: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(address)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(address: address))
        }
    }
}
