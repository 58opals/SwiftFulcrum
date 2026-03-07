// NilAcceptingResponseAdapter_.swift

extension SwiftFulcrum.RPC {
    public protocol NilAcceptingResponseAdapter: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
        init(nilValue: ())
    }
}
