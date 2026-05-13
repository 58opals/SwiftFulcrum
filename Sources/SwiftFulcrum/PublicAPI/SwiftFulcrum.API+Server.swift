// SwiftFulcrum.API+Server.swift

extension SwiftFulcrum.API {
    public struct Server: Sendable {
        public var ping: Request<SwiftFulcrum.Response.Server.Ping> {
            .init(method: .server(.ping))
        }

        public func version(
            clientName: String,
            protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument
        ) -> Request<SwiftFulcrum.Response.Server.Version> {
            .init(method: .server(.version(clientName: clientName, protocolNegotiation: protocolNegotiation)))
        }

        public var features: Request<SwiftFulcrum.Response.Server.Features> {
            .init(method: .server(.features))
        }
    }
}
