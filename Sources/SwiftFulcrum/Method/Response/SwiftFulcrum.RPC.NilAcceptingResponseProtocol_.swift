// JSONRPCNilAcceptingResponse_.swift

public extension SwiftFulcrum.RPC {
    protocol NilAcceptingResponseProtocol: SwiftFulcrum.RPC.ResponseProtocol {
        init(nilValue: ())
    }
}
