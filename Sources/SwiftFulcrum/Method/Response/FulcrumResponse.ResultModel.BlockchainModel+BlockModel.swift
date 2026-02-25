import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct BlockModel {
            public struct HeaderModel: JSONRPCResponse {
                public let hex: String
                public let proof: ProofModel?
                
                public struct ProofModel: Decodable, Sendable {
                    public let branch: [String]
                    public let root: String
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.BlockModel.HeaderModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    switch jsonrpc {
                    case .raw(let raw):
                        self.hex = raw
                        self.proof = nil
                    case .proof(let proof):
                        self.hex = proof.header
                        self.proof = ProofModel(branch: proof.branch,
                                           root: proof.root)
                    }
                }
            }
            
            public struct HeadersModel: JSONRPCResponse {
                public let count: UInt
                public let headers: [String]
                public let hex: String
                public let max: UInt
                public let proof: BlockModel.HeaderModel.ProofModel?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.BlockModel.HeadersModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.count = jsonrpc.count
                    self.hex = jsonrpc.hex
                    self.headers = jsonrpc.headers ?? Self.splitHeaders(hex: jsonrpc.hex)
                    self.max = jsonrpc.max
                    self.proof = {
                        guard let branch = jsonrpc.branch,
                              let root = jsonrpc.root else {
                            return nil
                        }
                        
                        return BlockModel.HeaderModel.ProofModel(branch: branch, root: root)
                    }()
                }
                
                private static func splitHeaders(hex: String) -> [String] {
                    
                    let headerCharacterLength = 160
                    var headers: [String] = .init()
                    var currentIndex = hex.startIndex
                    
                    while currentIndex < hex.endIndex {
                        guard let endIndex = hex.index(currentIndex,
                                                       offsetBy: headerCharacterLength,
                                                       limitedBy: hex.endIndex) else {
                            break
                        }
                        
                        guard hex.distance(from: currentIndex, to: endIndex) == headerCharacterLength else {
                            break
                        }
                        
                        headers.append(String(hex[currentIndex..<endIndex]))
                        currentIndex = endIndex
                    }
                    
                    return headers
                }
            }
        }
        

}
