import Foundation

protocol FulcrumMethodInitializable {}

protocol FulcrumMethodPathable {
    var path: String { get }
}

protocol FulcrumMethodRequestable {
    var request: Request { get }
}

/*
public protocol FulcrumMethodResultTypable {
    associatedtype ResultType
    var resultType: ResultType.Type { get }
}
*/
