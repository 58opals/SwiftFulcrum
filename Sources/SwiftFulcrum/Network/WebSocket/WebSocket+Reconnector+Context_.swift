// WebSocket+Reconnector+Context_.swift

import Foundation

extension WebSocket.Reconnector {
    public protocol Context: Actor {
        var url: URL { get }
        var closeInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?) { get }
        
        func cancelReceiverTask() async
        func setURL(_ newURL: URL)
        func connect(withEmitLifecycle: Bool) async throws
        func ensureAutoReceive()
        func emitLog(_ level: Log.Level,
                     _ message: @autoclosure () -> String,
                     metadata: [String: String]?,
                     file: String,
                     function: String,
                     line: UInt)
        func emitLifecycle(_ event: WebSocket.Lifecycle.Event)
    }
}

extension WebSocket: WebSocket.Reconnector.Context {}
