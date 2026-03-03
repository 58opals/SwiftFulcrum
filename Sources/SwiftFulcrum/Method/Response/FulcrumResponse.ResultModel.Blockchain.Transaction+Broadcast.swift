import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct Broadcast: JSONRPCResponse {
                public let transactionHash: Data
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.Broadcast
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    self.transactionHash = try Self.decodeHex(jsonrpc)
                }
                
                private static func decodeHex(_ hex: String) throws -> Data {
                    let string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard string.count % 2 == 0 else {
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("txid has odd hex length: \(string.count)")
                    }
                    var data = Data(); data.reserveCapacity(string.count / 2)
                    var index = string.startIndex
                    while index < string.endIndex {
                        let currentIndex = string.index(index, offsetBy: 2)
                        let byteString = String(string[index..<currentIndex])
                        guard let byte = UInt8(byteString, radix: 16) else {
                            throw FulcrumResponse.ResultModel.Error.unexpectedFormat("tx contains non-hex: \(byteString)")
                        }
                        data.append(byte)
                        index = currentIndex
                    }
                    guard data.count == 32 else {
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("txid decoded \(data.count) bytes; expected 32")
                    }
                    return data
                }
            }
            

}
