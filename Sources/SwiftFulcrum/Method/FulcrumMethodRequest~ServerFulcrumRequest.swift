// FulcrumMethodRequest~ServerFulcrumRequest.swift

import Foundation

extension FulcrumMethodRequest {
    func createServerRequest(_ server: ServerModel, uuid: UUID) -> FulcrumRequest {
        switch server {
        case .ping:
            struct ParametersModel: Encodable {
                func encode(to encoder: Encoder) throws {
                    _ = encoder.unkeyedContainer()
                }
            }

            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel())

        case .version(let clientName, let negotiationArgument):
            struct ParametersModel: Encodable {
                let clientName: String
                let negotiationArgument: FulcrumClient.Configuration.ProtocolNegotiationModel.Argument

                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(clientName)
                    try container.encode(negotiationArgument)
                }
            }

            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(clientName: clientName,
                                              negotiationArgument: negotiationArgument))

        case .features:
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
