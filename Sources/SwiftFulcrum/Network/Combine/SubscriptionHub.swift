import Foundation
import Combine

public final class SubscriptionHub {
    private var subscriptions = [UUID: AnyCancellable]()
    
    func add(_ cancellable: AnyCancellable, for identifier: UUID) {
        subscriptions[identifier] = cancellable
    }
    
    func cancel(for identifier: UUID) {
        subscriptions[identifier]?.cancel()
        subscriptions.removeValue(forKey: identifier)
    }
    
    func cancelAll() {
        subscriptions.values.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
}
