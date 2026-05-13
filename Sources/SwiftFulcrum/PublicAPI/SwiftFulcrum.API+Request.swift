// SwiftFulcrum.API+Request.swift

extension SwiftFulcrum.API {
    public struct Request<ResponsePayload: Decodable & Sendable>: Sendable {
        let method: SwiftFulcrum.RPC.Method

        init(method: SwiftFulcrum.RPC.Method) {
            self.method = method
        }
    }
}
