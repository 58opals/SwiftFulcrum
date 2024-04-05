import Foundation
import Combine

public struct SwiftFulcrum {
    private let storage: Storage
    private let client: Client
    
    public init() throws {
        let servers = WebSocket.Server.samples
        guard let server = servers.randomElement() else { throw WebSocket.Error.initializing(reason: .noURLAvailable, description: "Server list: \(servers)") }
        let websocket = WebSocket(url: server)
        
        self.storage = Storage()
        self.client = Client(webSocket: websocket, storage: storage)
    }
    
    public init(urlString: String) throws {
        guard let url = URL(string: urlString) else { throw WebSocket.Error.initializing(reason: .invalidURL, description: "URL: \(urlString)") }
        guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw WebSocket.Error.initializing(reason: .unsupportedScheme, description: "URL: \(urlString)") }
        let websocket = WebSocket(url: url)
        
        self.storage = Storage()
        self.client = Client(webSocket: websocket, storage: storage)
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
    
    func getResultSubscriber(of method: Method, completion: @escaping (UUID) -> Void) async throws -> AnyCancellable {
        let publisher = try await getResultPublisher(method)
        let subscriber = publisher.sink(receiveValue: completion)
        return subscriber
    }
    
    func getNotificationSubscriber(of method: Method, completion: @escaping (String) -> Void) async throws -> AnyCancellable {
        let publisher = try await getNotificationPublisher(method)
        let subscriber = publisher.sink(receiveValue: completion)
        return subscriber
    }
}

extension SwiftFulcrum {
    public func sendRequest(_ method: Method) async throws -> UUID {
        let uuid = try await client.sendRequest(from: method)
        return uuid
    }
    
    public func storeResultSubscriber(of method: Method, to subscribers: inout Set<AnyCancellable>, completion: @escaping (UUID) -> Void) async throws {
        let subscriber = try await self.getResultSubscriber(of: method, completion: completion)
        subscriber.store(in: &subscribers)
    }
    
    public func storeNotificationSubscriber(of method: Method, to subscribers: inout Set<AnyCancellable>, completion: @escaping (String) -> Void) async throws {
        let subscriber = try await self.getNotificationSubscriber(of: method, completion: completion)
        subscriber.store(in: &subscribers)
    }
}
