import Foundation

final class Storage {
    var request: RequestBox = .init()
    var result: Response.Result.Box = .init()
    
    func getResult(of id: UUID) throws -> (any FulcrumRegularResponseResultInitializable)? {
        let request = try request.getRequest(for: id)
        let method = request.requestedMethod
        
        switch method {
        case .blockchain(let blockchain):
            switch blockchain {
            case .estimateFee(_):
                return try result.blockchain.estimateFee.getResult(for: id)
            case .relayFee:
                return try result.blockchain.relayFee.getResult(for: id)
                
            case .address(let address):
                switch address {
                case .getBalance(_, _):
                    return try result.blockchain.address.getBalance.getResult(for: id)
                case .getFirstUse(_):
                    return try result.blockchain.address.getFirstUse.getResult(for: id)
                case .getHistory(_, _, _, _):
                    return try result.blockchain.address.getHistory.getResult(for: id)
                case .getMempool(_):
                    return try result.blockchain.address.getMempool.getResult(for: id)
                case .getScriptHash(_):
                    return try result.blockchain.address.getScriptHash.getResult(for: id)
                case .listUnspent(_, _):
                    return try result.blockchain.address.listUnspent.getResult(for: id)
                case .subscribe(_):
                    return try result.blockchain.address.subscribe.getResult(for: id)
                case .unsubscribe(_):
                    return try result.blockchain.address.unsubscribe.getResult(for: id)
                }
                
            case .block(let block):
                switch block {
                case .header(_, _):
                    return try result.blockchain.block.header.getResult(for: id)
                case .headers(_, _, _):
                    return try result.blockchain.block.headers.getResult(for: id)
                }
                
            case .header(let header):
                switch header {
                case .get(_):
                    return try result.blockchain.header.get.getResult(for: id)
                }
                
            case .headers(let headers):
                switch headers {
                case .getTip:
                    return try result.blockchain.headers.getTip.getResult(for: id)
                case .subscribe:
                    return try result.blockchain.headers.subscribe.getResult(for: id)
                    //return try result.blockchain.headers.notification.getNotifications(for: )
                case .unsubscribe:
                    return try result.blockchain.headers.unsubscribe.getResult(for: id)
                }
                
            case .transaction(let transaction):
                switch transaction {
                case .broadcast(_):
                    return try result.blockchain.transaction.broadcast.getResult(for: id)
                    
                case .get(_, _):
                    return try result.blockchain.transaction.get.getResult(for: id)
                    
                case .getConfirmedBlockHash(_, _):
                    return try result.blockchain.transaction.getConfirmedBlockHash.getResult(for: id)
                    
                case .getHeight(_):
                    return try result.blockchain.transaction.getHeight.getResult(for: id)
                    
                case .getMerkle(_):
                    return try result.blockchain.transaction.getMerkle.getResult(for: id)
                    
                case .idFromPos(_, _, _):
                    return try result.blockchain.transaction.idFromPos.getResult(for: id)
                    
                case .subscribe(_):
                    return try result.blockchain.transaction.subscribe.getResult(for: id)
                    
                case .unsubscribe(_):
                    return try result.blockchain.transaction.unsubscribe.getResult(for: id)
                    
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .get(_):
                        return try result.blockchain.transaction.dsProof.get.getResult(for: id)
                    case .list:
                        return try result.blockchain.transaction.dsProof.list.getResult(for: id)
                        
                    case .subscribe(_):
                        return try result.blockchain.transaction.subscribe.getResult(for: id)
                        
                    case .unsubscribe(_):
                        return try result.blockchain.transaction.unsubscribe.getResult(for: id)
                    }
                }
                
            case .utxo(let utxo):
                switch utxo {
                case .getInfo(_, _):
                    return try result.blockchain.utxo.getInfo.getResult(for: id)
                }
            }
        case .mempool(let mempool):
            switch mempool {
            case .getFeeHistogram:
                return try result.mempool.getFeeHistogram.getResult(for: id)
            }
        }
    }
}
