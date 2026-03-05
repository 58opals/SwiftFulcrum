// JSONRPCNilAcceptingResponse_.swift

@available(*, deprecated, message: "Use SwiftFulcrum.RPC.NilAcceptingResponseProtocol instead.")
public protocol JSONRPCNilAcceptingResponse: JSONRPCResponse {
    init(nilValue: ())
}
