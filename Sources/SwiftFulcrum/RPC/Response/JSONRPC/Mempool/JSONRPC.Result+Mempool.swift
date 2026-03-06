import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
    public struct Mempool {
        public struct FlexibleNumber: Decodable, Sendable {
            public let value: Double

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let double = try? container.decode(Double.self) { self.value = double; return }
                if let int = try? container.decode(Int.self) { self.value = Double(int); return }
                if let uint = try? container.decode(UInt.self) { self.value = Double(uint); return }
                if let string = try? container.decode(String.self), let double = Double(string) { self.value = double; return }

                throw DecodingError.typeMismatch(
                    Double.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected number or numeric string")
                )
            }
        }

        public struct GetInfo: Decodable, Sendable {
            public let mempoolminfee: FlexibleNumber?
            public let minrelaytxfee: FlexibleNumber?
            public let incrementalrelayfee: FlexibleNumber?
            public let unbroadcastcount: Int?
            public let isFullReplaceByFeeEnabled: Bool?

            enum CodingKeys: String, CodingKey {
                case mempoolminfee
                case minrelaytxfee
                case incrementalrelayfee
                case unbroadcastcount
                case isFullReplaceByFeeEnabled = "fullrbf"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.mempoolminfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: .mempoolminfee)
                self.minrelaytxfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: .minrelaytxfee)
                self.incrementalrelayfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: .incrementalrelayfee)
                self.unbroadcastcount = try container.decodeIfPresent(Int.self, forKey: .unbroadcastcount)
                self.isFullReplaceByFeeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isFullReplaceByFeeEnabled)
            }
        }

        public typealias FeeHistogram = [FlexibleNumber]
        public typealias GetFeeHistogram = [FeeHistogram]
    }
}
