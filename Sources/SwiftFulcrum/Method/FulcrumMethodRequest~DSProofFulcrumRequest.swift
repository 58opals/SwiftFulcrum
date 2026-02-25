// FulcrumMethodRequest~DSProofFulcrumRequest.swift

import Foundation

extension FulcrumMethodRequest {
    func createDSProofRequest(
        _ dSProof: BlockchainModel.TransactionModel.DSProofModel,
        uuid: UUID
    ) -> FulcrumRequest {
        switch dSProof {
        case .get(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .list:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .subscribe(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .unsubscribe(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))
        }
    }
}
