import Foundation
import Combine

extension SwiftFulcrum {
    func blockchainEstimateFee(for numberOfBlocks: Method.Blockchain.numberOfBlocks) {
        
    }
}

extension SwiftFulcrum: SwiftFulcrumPublicCommunicatable {
    func sendRequest(_ method: Method) async throws -> UUID {
        let uuid = try await client.sendRequest(from: method)
        return uuid
    }
    
    mutating func submitRequest<ResultType>(_ method: Method, resultType: ResultType.Type, behavior: @escaping (Swift.Result<ResultType, Swift.Error>) -> Void) async {
        do {
            let requestedID = try await self.sendRequest(method)
            try await self.storeResultSubscriber(of: method, to: &self.subscribers) { [self] id in
                do {
                    guard id == requestedID else { throw SwiftFulcrum.Error.custom(description: "Requested ID:\(requestedID) isn't matched with published ID: \(id).") }
                    let result: ResultType = try self.getResult(for: method, of: id)
                    behavior(.success(result))
                } catch {
                    behavior(.failure(error))
                }
            }
        } catch {
            behavior(.failure(error))
        }
    }
    
    mutating func submitSubscription<NotificationType>(_ method: Method, notificationType: NotificationType.Type, behavior: @escaping (Swift.Result<NotificationType, Swift.Error>) -> Void) async {
        do {
            let requestedID = try await self.sendRequest(method)
            _ = requestedID
            
            try await self.storeNotificationSubscriber(of: method, to: &self.subscribers) { [self] id in
                do {
                    let notifications: [NotificationType] = try self.getNotification(for: method, of: id)
                    for notification in notifications {
                        behavior(.success(notification))
                    }
                } catch {
                    behavior(.failure(error))
                }
            }
        } catch {
            behavior(.failure(error))
        }
    }
}

extension SwiftFulcrum {
    private func getResult<ResultType>(for method: Method, of id: UUID) throws -> ResultType {
        switch method {
            // MARK: - Blockchain
        case .blockchain(let blockchain):
            switch blockchain {
            case .estimateFee(_):
                guard let result = try self.storage.result.blockchain.estimateFee.getResult(for: id) else { throw Error.resultNotFound }
                guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                return typedResult
            case .relayFee:
                guard let result = try self.storage.result.blockchain.relayFee.getResult(for: id) else { throw Error.resultNotFound }
                guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                return typedResult
                // MARK: - Blockchain.Address
            case .address(let address):
                switch address {
                case .getBalance(_, _):
                    guard let result = try self.storage.result.blockchain.address.getBalance.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getFirstUse(_):
                    guard let result = try self.storage.result.blockchain.address.getFirstUse.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getHistory(_, _, _, _):
                    guard let result = try self.storage.result.blockchain.address.getHistory.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getMempool(_):
                    guard let result = try self.storage.result.blockchain.address.getMempool.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getScriptHash(_):
                    guard let result = try self.storage.result.blockchain.address.getScriptHash.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .listUnspent(_, _):
                    guard let result = try self.storage.result.blockchain.address.listUnspent.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .subscribe(_):
                    guard let result = try self.storage.result.blockchain.address.subscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .unsubscribe(_):
                    guard let result = try self.storage.result.blockchain.address.unsubscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                }
                // MARK: - Blockchain.Block
            case .block(let block):
                switch block {
                case .header(_, _):
                    guard let result = try self.storage.result.blockchain.block.header.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .headers(_, _, _):
                    guard let result = try self.storage.result.blockchain.block.headers.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                }
                // MARK: - Blockchain.Header
            case .header(let header):
                switch header {
                case .get(_):
                    guard let result = try self.storage.result.blockchain.header.get.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                }
                // MARK: - Blockchain.Headers
            case .headers(let headers):
                switch headers {
                case .getTip:
                    guard let result = try self.storage.result.blockchain.headers.getTip.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .subscribe:
                    guard let result = try self.storage.result.blockchain.headers.subscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .unsubscribe:
                    guard let result = try self.storage.result.blockchain.headers.unsubscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                }
                // MARK: - Blockchain.Transaction
            case .transaction(let transaction):
                switch transaction {
                case .broadcast(_):
                    guard let result = try self.storage.result.blockchain.transaction.broadcast.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .get(_, _):
                    guard let result = try self.storage.result.blockchain.transaction.get.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getConfirmedBlockHash(_, _):
                    guard let result = try self.storage.result.blockchain.transaction.getConfirmedBlockHash.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getHeight(_):
                    guard let result = try self.storage.result.blockchain.transaction.getHeight.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .getMerkle(_):
                    guard let result = try self.storage.result.blockchain.transaction.getMerkle.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .idFromPos(_, _, _):
                    guard let result = try self.storage.result.blockchain.transaction.idFromPos.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .subscribe(_):
                    guard let result = try self.storage.result.blockchain.transaction.subscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                case .unsubscribe(_):
                    guard let result = try self.storage.result.blockchain.transaction.unsubscribe.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                    // MARK: - Blockchain.Transaction.DSProof
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .get(_):
                        guard let result = try self.storage.result.blockchain.transaction.dsProof.get.getResult(for: id) else { throw Error.resultNotFound }
                        guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                        return typedResult
                    case .list:
                        guard let result = try self.storage.result.blockchain.transaction.dsProof.list.getResult(for: id) else { throw Error.resultNotFound }
                        guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                        return typedResult
                    case .subscribe(_):
                        guard let result = try self.storage.result.blockchain.transaction.dsProof.subscribe.getResult(for: id) else { throw Error.resultNotFound }
                        guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                        return typedResult
                    case .unsubscribe(_):
                        guard let result = try self.storage.result.blockchain.transaction.dsProof.unsubscribe.getResult(for: id) else { throw Error.resultNotFound }
                        guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                        return typedResult
                    }
                }
                // MARK: - Blockchain.UTXO
            case .utxo(let utxo):
                switch utxo {
                case .getInfo(_, _):
                    guard let result = try self.storage.result.blockchain.utxo.getInfo.getResult(for: id) else { throw Error.resultNotFound }
                    guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                    return typedResult
                }
            }
            // MARK: - Mempool
        case .mempool(let mempool):
            switch mempool {
            case .getFeeHistogram:
                guard let result = try self.storage.result.mempool.getFeeHistogram.getResult(for: id) else { throw Error.resultNotFound }
                guard let typedResult = result as? ResultType else { throw Error.resultTypeMismatch }
                return typedResult
            }
        }
    }
    
    private func getNotification<NotificationType>(for method: Method, of id: String) throws -> [NotificationType] {
        switch method {
            // MARK: - Blockchain
        case .blockchain(let blockchain):
            switch blockchain {
                // MARK: - Blockchain.Address
            case .address(let address):
                switch address {
                case .subscribe(_):
                    let notifications = try self.storage.result.blockchain.address.notification.getNotifications(for: id)
                    guard let typedNotifications = notifications as? [NotificationType] else { throw Error.resultTypeMismatch }
                    return typedNotifications
                default:
                    throw Error.custom(description: "Invalid method for getting any notifications.")
                }
                // MARK: - Blockchain.Headers
            case .headers(let headers):
                switch headers {
                case .subscribe:
                    let notifications = try self.storage.result.blockchain.headers.notification.getNotifications(for: id)
                    guard let typedNotifications = notifications as? [NotificationType] else { throw Error.resultTypeMismatch }
                    return typedNotifications
                default:
                    throw Error.custom(description: "Invalid method for getting any notifications.")
                }
                // MARK: - Blockchain.Transaction
            case .transaction(let transaction):
                switch transaction {
                case .subscribe(_):
                    let notifications = try self.storage.result.blockchain.transaction.notification.getNotifications(for: id)
                    guard let typedNotifications = notifications as? [NotificationType] else { throw Error.resultTypeMismatch }
                    return typedNotifications
                    // MARK: - Blockchain.Transaction.DSProof
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .subscribe(_):
                        let notifications = try self.storage.result.blockchain.transaction.dsProof.notification.getNotifications(for: id)
                        guard let typedNotifications = notifications as? [NotificationType] else { throw Error.resultTypeMismatch }
                        return typedNotifications
                    default:
                        throw Error.custom(description: "Invalid method for getting any notifications.")
                    }
                default:
                    throw Error.custom(description: "Invalid method for getting any notifications.")
                }
            default:
                throw Error.custom(description: "Invalid method for getting any notifications.")
            }
        default:
            throw Error.custom(description: "Invalid method for getting any notifications.")
        }
    }
}

extension SwiftFulcrum {
    private func storeResultSubscriber(of method: Method, to subscribers: inout Set<AnyCancellable>, completion: @escaping (UUID) -> Void) async throws {
        let subscriber = try await self.getResultSubscriber(of: method, completion: completion)
        subscriber.store(in: &subscribers)
    }
    
    private func storeNotificationSubscriber(of method: Method, to subscribers: inout Set<AnyCancellable>, completion: @escaping (String) -> Void) async throws {
        let subscriber = try await self.getNotificationSubscriber(of: method, completion: completion)
        subscriber.store(in: &subscribers)
    }
}

extension SwiftFulcrum {
    private func getResultPublisher(_ method: Method) async throws -> PassthroughSubject<UUID, Never> {
        switch method {
            // MARK: - Blockchain
        case .blockchain(let blockchain):
            switch blockchain {
            case .estimateFee(_): return self.storage.result.blockchain.estimateFee.publisher
            case .relayFee: return self.storage.result.blockchain.relayFee.publisher
                // MARK: - Blockchain.Address
            case .address(let address):
                switch address {
                case .getBalance(_, _): return self.storage.result.blockchain.address.getBalance.publisher
                case .getFirstUse(_): return self.storage.result.blockchain.address.getFirstUse.publisher
                case .getHistory(_, _, _, _): return self.storage.result.blockchain.address.getHistory.publisher
                case .getMempool(_): return self.storage.result.blockchain.address.getMempool.publisher
                case .getScriptHash(_): return self.storage.result.blockchain.address.getScriptHash.publisher
                case .listUnspent(_, _): return self.storage.result.blockchain.address.listUnspent.publisher
                case .subscribe(_): return self.storage.result.blockchain.address.subscribe.publisher
                case .unsubscribe(_): return self.storage.result.blockchain.address.unsubscribe.publisher
                }
                // MARK: - Blockchain.Block
            case .block(let block):
                switch block {
                case .header(_, _): return self.storage.result.blockchain.block.header.publisher
                case .headers(_, _, _): return self.storage.result.blockchain.block.headers.publisher
                }
                // MARK: - Blockchain.Header
            case .header(let header):
                switch header {
                case .get(_): return self.storage.result.blockchain.header.get.publisher
                }
                // MARK: - Blockchain.Headers
            case .headers(let headers):
                switch headers {
                case .getTip: return self.storage.result.blockchain.headers.getTip.publisher
                case .subscribe: return self.storage.result.blockchain.headers.subscribe.publisher
                case .unsubscribe: return self.storage.result.blockchain.headers.unsubscribe.publisher
                }
                // MARK: - Blockchain.Transaction
            case .transaction(let transaction):
                switch transaction {
                case .broadcast(_): return self.storage.result.blockchain.transaction.broadcast.publisher
                case .get(_, _): return self.storage.result.blockchain.transaction.get.publisher
                case .getConfirmedBlockHash(_, _): return self.storage.result.blockchain.transaction.getConfirmedBlockHash.publisher
                case .getHeight(_): return self.storage.result.blockchain.transaction.getHeight.publisher
                case .getMerkle(_): return self.storage.result.blockchain.transaction.getMerkle.publisher
                case .idFromPos(_, _, _): return self.storage.result.blockchain.transaction.idFromPos.publisher
                case .subscribe(_): return self.storage.result.blockchain.transaction.subscribe.publisher
                case .unsubscribe(_): return self.storage.result.blockchain.transaction.unsubscribe.publisher
                    // MARK: - Blockchain.Transaction.DSProof
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .get(_): return self.storage.result.blockchain.transaction.dsProof.get.publisher
                    case .list: return self.storage.result.blockchain.transaction.dsProof.list.publisher
                    case .subscribe(_): return self.storage.result.blockchain.transaction.dsProof.subscribe.publisher
                    case .unsubscribe(_): return self.storage.result.blockchain.transaction.dsProof.unsubscribe.publisher
                    }
                }
                // MARK: - Blockchain.UTXO
            case .utxo(let utxo):
                switch utxo {
                case .getInfo(_, _): return self.storage.result.blockchain.utxo.getInfo.publisher
                }
            }
            // MARK: - Mempool
        case .mempool(let mempool):
            switch mempool {
            case .getFeeHistogram: return self.storage.result.mempool.getFeeHistogram.publisher
            }
        }
    }
    
    private func getNotificationPublisher(_ method: Method) async throws -> PassthroughSubject<String, Never> {
        switch method {
            // MARK: - Blockchain
        case .blockchain(let blockchain):
            switch blockchain {
                // MARK: - Blockchain.Address
            case .address(let address):
                switch address {
                case .subscribe(_): return self.storage.result.blockchain.address.notification.publisher
                default: fatalError()
                }
                // MARK: - Blockchain.Headers
            case .headers(let headers):
                switch headers {
                case .subscribe: return self.storage.result.blockchain.headers.notification.publisher
                default: fatalError()
                }
                // MARK: - Blockchain.Transaction
            case .transaction(let transaction):
                switch transaction {
                case .subscribe(_): return self.storage.result.blockchain.transaction.notification.publisher
                    // MARK: - Blockchain.Transaction.DSProof
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .subscribe(_): return self.storage.result.blockchain.transaction.dsProof.notification.publisher
                    default: fatalError()
                    }
                default: fatalError()
                }
            default: fatalError()
            }
        default: fatalError()
        }
    }
    
    private func getResultSubscriber(of method: Method, completion: @escaping (UUID) -> Void) async throws -> AnyCancellable {
        let publisher = try await getResultPublisher(method)
        let subscriber = publisher.sink(receiveValue: completion)
        return subscriber
    }
    
    private func getNotificationSubscriber(of method: Method, completion: @escaping (String) -> Void) async throws -> AnyCancellable {
        let publisher = try await getNotificationPublisher(method)
        let subscriber = publisher.sink(receiveValue: completion)
        return subscriber
    }
}
