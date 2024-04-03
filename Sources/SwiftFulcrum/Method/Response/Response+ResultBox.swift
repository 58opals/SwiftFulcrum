import Foundation
import Combine

extension Storage {
    class ResultBox<Result: FulcrumRegularResponseResultInitializable> {
        var results: [UUID: Result?] = .init()
        var publisher: PassthroughSubject<UUID, Never> = .init()
        
        func store(result: Result?, for id: UUID) throws {
            guard self.results[id] == nil else { throw Storage.Error.resultExistence(issue: .alreadyExists, id: id) }
            self.results[id] = result
            self.publisher.send(id)
        }
        
        func getResult(for id: UUID) throws -> Result? {
            guard let result = self.results[id] else { throw Storage.Error.resultExistence(issue: .notFound, id: id) }
            return result
        }
    }
    
    class NotificationBox<Notification: FulcrumSubscriptionResponseResultInitializable> {
        typealias SubscriptionIdentifier = String
        
        var notifications: [SubscriptionIdentifier: [Notification?]] = [:]
        var publisher: PassthroughSubject<SubscriptionIdentifier, Never> = .init()
        
        func store(notification: Notification?, for subscriptionIdentifier: SubscriptionIdentifier) throws {
            self.notifications[subscriptionIdentifier, default: []].append(notification)
            self.publisher.send(subscriptionIdentifier)
        }
        
        func getNotifications(for subscriptionIdentifier: SubscriptionIdentifier) throws -> [Notification?] {
            guard let notifications = self.notifications[subscriptionIdentifier] else { throw Storage.Error.notificationExistence(issue: .notFound, identifier: subscriptionIdentifier) }
            return notifications
        }
    }
}

extension Response.Result {
    struct Box {
        var blockchain = Blockchain()
        var mempool = Mempool()
        
        struct Blockchain {
            var address = Address()
            var block = Block()
            var header = Header()
            var headers = Headers()
            var transaction = Transaction()
            var utxo = UTXO()
            
            struct Address {
                var getBalance = Storage.ResultBox<Response.Result.Blockchain.Address.GetBalance>()
                var getFirstUse = Storage.ResultBox<Response.Result.Blockchain.Address.GetFirstUse>()
                var getHistory = Storage.ResultBox<Response.Result.Blockchain.Address.GetHistory>()
                var getMempool = Storage.ResultBox<Response.Result.Blockchain.Address.GetMempool>()
                var getScriptHash = Storage.ResultBox<Response.Result.Blockchain.Address.GetScriptHash>()
                var listUnspent = Storage.ResultBox<Response.Result.Blockchain.Address.ListUnspent>()
                var subscribe = Storage.ResultBox<Response.Result.Blockchain.Address.Subscribe>()
                var notification = Storage.NotificationBox<Response.Result.Blockchain.Address.SubscribeNotification>()
                var unsubscribe = Storage.ResultBox<Response.Result.Blockchain.Address.Unsubscribe>()
            }
            
            struct Block {
                var header = Storage.ResultBox<Response.Result.Blockchain.Block.Header>()
                var headers = Storage.ResultBox<Response.Result.Blockchain.Block.Headers>()
            }
            
            struct Header {
                var get = Storage.ResultBox<Response.Result.Blockchain.Header.Get>()
            }
            
            struct Headers {
                var getTip = Storage.ResultBox<Response.Result.Blockchain.Headers.GetTip>()
                var subscribe = Storage.ResultBox<Response.Result.Blockchain.Headers.Subscribe>()
                var notification = Storage.NotificationBox<Response.Result.Blockchain.Headers.SubscribeNotification>()
                var unsubscribe = Storage.ResultBox<Response.Result.Blockchain.Headers.Unsubscribe>()
            }
            
            struct Transaction {
                var dsProof = DSProof()
                
                struct DSProof {
                    var get = Storage.ResultBox<Response.Result.Blockchain.Transaction.DSProof.Get>()
                    var list = Storage.ResultBox<Response.Result.Blockchain.Transaction.DSProof.List>()
                    var subscribe = Storage.ResultBox<Response.Result.Blockchain.Transaction.DSProof.Subscribe>()
                    var notification = Storage.NotificationBox<Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification>()
                    var unsubscribe = Storage.ResultBox<Response.Result.Blockchain.Transaction.DSProof.Unsubscribe>()
                }
                
                var broadcast = Storage.ResultBox<Response.Result.Blockchain.Transaction.Broadcast>()
                var get = Storage.ResultBox<Response.Result.Blockchain.Transaction.Get>()
                var getConfirmedBlockHash = Storage.ResultBox<Response.Result.Blockchain.Transaction.GetConfirmedBlockHash>()
                var getHeight = Storage.ResultBox<Response.Result.Blockchain.Transaction.GetHeight>()
                var getMerkle = Storage.ResultBox<Response.Result.Blockchain.Transaction.GetMerkle>()
                var idFromPos = Storage.ResultBox<Response.Result.Blockchain.Transaction.IDFromPos>()
                var subscribe = Storage.ResultBox<Response.Result.Blockchain.Transaction.Subscribe>()
                var notification = Storage.NotificationBox<Response.Result.Blockchain.Transaction.SubscribeNotification>()
                var unsubscribe = Storage.ResultBox<Response.Result.Blockchain.Transaction.Unsubscribe>()
            }
            
            struct UTXO {
                var getInfo = Storage.ResultBox<Response.Result.Blockchain.UTXO.GetInfo>()
            }
            
            var estimateFee = Storage.ResultBox<Response.Result.Blockchain.EstimateFee>()
            var relayFee = Storage.ResultBox<Response.Result.Blockchain.RelayFee>()
        }
        
        struct Mempool {
            var getFeeHistogram = Storage.ResultBox<Response.Result.Mempool.GetFeeHistogram>()
        }
    }
}
