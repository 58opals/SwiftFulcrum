// ReconnectCompletionState.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

actor ReconnectCompletionState {
    private var completed = false

    func markCompleted() {
        completed = true
    }

    var isCompleted: Bool {
        completed
    }
}

typealias HeadersSubscription = SwiftFulcrum.Client.Subscription<
    SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
    SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
>

typealias ScriptHashSubscription = SwiftFulcrum.Client.Subscription<
    SwiftFulcrum.Response.Blockchain.ScriptHash.Subscribe,
    SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification
>
