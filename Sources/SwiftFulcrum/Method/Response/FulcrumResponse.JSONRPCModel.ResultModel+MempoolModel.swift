import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel {
    public struct MempoolModel {
        public struct FlexibleNumberModel: Decodable, Sendable {
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

        public struct GetInfoModel: Decodable, Sendable {
            public let mempoolminfee: FlexibleNumberModel?
            public let minrelaytxfee: FlexibleNumberModel?
            public let incrementalrelayfee: FlexibleNumberModel?
            public let unbroadcastcount: Int?
            public let isFullReplaceByFeeEnabled: Bool?

            enum CodingKeys: String, CodingKey {
                case mempoolminfee
                case minrelaytxfee
                case incrementalrelayfee
                case unbroadcastcount
                case isFullReplaceByFeeEnabled = "fullrbf"
            }
        }

        public typealias FeeHistogram = [FlexibleNumberModel]
        public typealias GetFeeHistogramModel = [FeeHistogram]
    }
}
