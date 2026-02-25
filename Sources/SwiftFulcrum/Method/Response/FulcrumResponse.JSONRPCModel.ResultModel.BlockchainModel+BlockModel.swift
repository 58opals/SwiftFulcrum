import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
            public struct BlockModel {
                public typealias HeaderModel = HeaderParametersModel
                public enum HeaderParametersModel: Decodable, Sendable {
                    case raw(String)
                    case proof(ProofModel)
                    
                    public struct ProofModel: Decodable, Sendable {
                        public let branch: [String]
                        public let header: String
                        public let root: String
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .raw(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode(ProofModel.self) {
                            self = .proof(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(HeaderParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or ProofModel dictionary"))
                    }
                }
                
                public struct HeadersModel: Decodable, Sendable {
                    public let count: UInt
                    public let hex: String
                    public let max: UInt
                    public let root: String?
                    public let branch: [String]?
                    public let headers: [String]?
                    
                    private enum CodingKeysModel: String, CodingKey {
                        case count
                        case hex
                        case headers
                        case max
                        case root
                        case branch
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeysModel.self)
                        
                        self.count = try container.decode(UInt.self, forKey: .count)
                        self.max = try container.decode(UInt.self, forKey: .max)
                        self.headers = try container.decodeIfPresent([String].self, forKey: .headers)
                        
                        if let headerList = headers {
                            self.hex = headerList.joined()
                        } else if let legacyHex = try container.decodeIfPresent(String.self, forKey: .hex) {
                            self.hex = legacyHex
                        } else {
                            throw DecodingError.valueNotFound(String.self,
                                                              .init(codingPath: decoder.codingPath,
                                                                    debugDescription: "Expected either hex or headers fields"))
                        }
                        
                        self.root = try container.decodeIfPresent(String.self, forKey: .root)
                        self.branch = try container.decodeIfPresent([String].self, forKey: .branch)
                    }
                }
            }
            

}
