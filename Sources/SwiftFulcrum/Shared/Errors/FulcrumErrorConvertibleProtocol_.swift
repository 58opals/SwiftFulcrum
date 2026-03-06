protocol FulcrumErrorConvertibleProtocol: Swift.Error {
    var asFulcrumError: SwiftFulcrum.Client.Error { get }
}
