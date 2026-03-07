// FulcrumErrorAdapter_.swift

protocol FulcrumErrorAdapter: Swift.Error {
    var asFulcrumError: SwiftFulcrum.Client.Error { get }
}
