// FulcrumErrorConvertibleModel_.swift

protocol FulcrumErrorConvertibleModel: Swift.Error {
    var asFulcrumError: SwiftFulcrum.Client.Error { get }
}
