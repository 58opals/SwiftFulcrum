import Foundation
import Combine

public final class SubscriptionHub {
    private var subscriptions = [UUID: AnyCancellable]()
    
    public func add(_ cancellable: AnyCancellable, for identifier: UUID) {
        subscriptions[identifier] = cancellable
    }
    
    public func cancel(for identifier: UUID) {
        subscriptions[identifier]?.cancel()
        subscriptions.removeValue(forKey: identifier)
    }
    
    public func cancelAll() {
        subscriptions.values.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
}
