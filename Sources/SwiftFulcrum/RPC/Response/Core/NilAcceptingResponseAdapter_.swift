// NilAcceptingResponseAdapter_.swift

public extension SwiftFulcrum.RPC {
    protocol NilAcceptingResponseAdapter: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
        init(nilValue: ())
    }
}
