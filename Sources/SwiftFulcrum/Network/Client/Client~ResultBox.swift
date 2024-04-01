import Foundation

extension Client: ClientResultBoxEventHandlable {
    func handleResultID(_ id: UUID) {
        print("Now I, Client, am handling the id: \(id)")
    }
}

extension Client: ClientResultBoxEventSubscribable {
    func setupResultBoxSubscriptions() {
        self.jsonRPC.storage.result.blockchain.relayFee.publisher
            .sink { [weak self] id in
                self?.handleResultID(id)
            }
            .store(in: &self.subscribers)
    }
}
