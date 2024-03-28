import Foundation

extension Client {
    enum Error: Swift.Error {
        case requestFailure(type: RequestType)
        
        enum RequestType {
            case regular
            case subscription
        }
    }
}
