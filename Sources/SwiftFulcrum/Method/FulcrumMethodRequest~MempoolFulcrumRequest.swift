// FulcrumMethodRequest~MempoolFulcrumRequest.swift

import Foundation

extension FulcrumMethodRequest {
    func createMempoolRequest(_ mempool: MempoolModel, uuid: UUID) -> FulcrumRequest {
        switch mempool {
        case .getInfo:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .getFeeHistogram:
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
