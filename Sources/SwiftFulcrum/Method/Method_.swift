import Foundation

protocol FulcrumMethodInitializable {}

protocol FulcrumMethodPathable {
    var path: String { get }
}

protocol FulcrumMethodRequestable {
    var request: Request { get }
}
