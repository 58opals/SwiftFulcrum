// SwiftFulcrum.RPC.Method~HeaderFulcrumRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createHeaderRequest(_ header: BlockchainModel.Header, uuid: UUID) -> FulcrumRequest {
        switch header {
        case .get(let blockHash):
            struct ParametersModel: Encodable {
                let blockHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(blockHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(blockHash: blockHash))
        }
    }

    func createHeadersRequest(_ headers: BlockchainModel.Headers, uuid: UUID) -> FulcrumRequest {
        switch headers {
        case .getTip:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .subscribe:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .unsubscribe:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())
        }
    }
}
