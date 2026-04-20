// WebSocketConnectionEventTracker+Entry.swift

import Foundation

extension WebSocketConnectionEventTracker {
    struct Entry {
        var result: Result<Void, Swift.Error>?
        var waitersByIdentifier: [UUID: CheckedContinuation<Void, Swift.Error>] = .init()
    }
}
