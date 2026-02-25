import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
            public struct HeaderModel {
                public struct GetModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
            }
            

}
