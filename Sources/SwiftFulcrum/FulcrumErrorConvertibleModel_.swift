// FulcrumErrorConvertibleModel_.swift

protocol FulcrumErrorConvertibleModel: Swift.Error {
    var asFulcrumError: FulcrumClient.Error { get }
}
