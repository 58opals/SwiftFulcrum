import Foundation

extension Storage {
    enum Error: Swift.Error {
        case requestExistence(issue: RequestIssue, id: UUID)
        case resultExistence(issue: ResultIssue, id: UUID)
        case notificationExistence(issue: NotificationIssue, identifier: String)
        
        enum RequestIssue {
            case alreadyExists
            case notFound
        }
        
        enum ResultIssue {
            case alreadyExists
            case notFound
        }
        
        enum NotificationIssue {
            case alreadyExists
            case notFound
        }
    }
}
