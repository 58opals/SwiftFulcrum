import Foundation

extension SwiftFulcrum.RPC.Method {
    func createBlockchainRequest(_ blockchain: Blockchain, uuid: UUID) -> FulcrumRequest {
        switch blockchain {
        case .estimateFee(let numberOfBlocks):
            struct ParametersModel: Encodable {
                let numberOfBlocks: Int
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(numberOfBlocks)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(numberOfBlocks: numberOfBlocks))

        case .relayFee:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .scripthash(let scripthash):
            return createScriptHashRequest(scripthash, uuid: uuid)
        case .address(let address):
            return createAddressRequest(address, uuid: uuid)
        case .block(let block):
            return createBlockRequest(block, uuid: uuid)
        case .header(let header):
            return createHeaderRequest(header, uuid: uuid)
        case .headers(let headers):
            return createHeadersRequest(headers, uuid: uuid)
        case .transaction(let transaction):
            return createTransactionRequest(transaction, uuid: uuid)
        case .utxo(let utxo):
            return createUTXORequest(utxo, uuid: uuid)
        }
    }
}
