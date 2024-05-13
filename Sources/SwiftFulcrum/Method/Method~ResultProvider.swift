import Foundation

/*
extension Method: FulcrumMethodResultTypable {
    var resultType: ResultType.Type {
        switch self {
        case .blockchain(let blockchain):
            switch blockchain {
                
                // MARK: Blockchain.estimateFee
            case .estimateFee(let numberOfBlocks):
                return Response.Result.Blockchain.EstimateFee.self
                
                // MARK: Blockchain.relayFee
            case .relayFee:
                return Response.Result.Blockchain.RelayFee.self
                
            case .address(let address):
                switch address {
                    
                    // MARK: Blockchain.Address.getBalance
                case .getBalance(let address, let tokenFilter):
                    return Response.Result.Blockchain.Address.GetBalance.self
                    
                    // MARK: Blockchain.Address.getFirstUse
                case .getFirstUse(let address):
                    return Response.Result.Blockchain.Address.GetFirstUse.self
                    
                    // MARK: Blockchain.Address.getHistory
                case .getHistory(let address, let fromHeight, let toHeight, let includeUnconfirmed):
                    return Response.Result.Blockchain.Address.GetHistory.self
                    
                    // MARK: Blockchain.Address.getMempool
                case .getMempool(let address):
                    return Response.Result.Blockchain.Address.GetMempool.self
                    
                    // MARK: Blockchain.Address.getScriptHash
                case .getScriptHash(let address):
                    return Response.Result.Blockchain.Address.GetScriptHash.self
                    
                    // MARK: Blockchain.Address.listUnspent
                case .listUnspent(let address, let tokenFilter):
                    return Response.Result.Blockchain.Address.ListUnspent.self
                    
                    // MARK: Blockchain.Address.subscribe
                case .subscribe(let address):
                    return Response.Result.Blockchain.Address.Subscribe.self
                    
                    // MARK: Blockchain.Address.unsubscribe
                case .unsubscribe(let address):
                    return Response.Result.Blockchain.Address.Unsubscribe.self
                }
                
            case .block(let block):
                switch block {
                    
                    // MARK: Blockchain.Block.header
                case .header(let height, let checkpointHeight):
                    return Response.Result.Blockchain.Block.Header.self
                    
                    // MARK: Blockchain.Block.headers
                case .headers(let startHeight, let count, let checkpointHeight):
                    return Response.Result.Blockchain.Block.Headers.self
                }
                
            case .header(let header):
                switch header {
                    
                    // MARK: Blockchain.Header.get
                case .get(let blockHash):
                    return Response.Result.Blockchain.Header.Get.self
                }
            case .headers(let headers):
                switch headers {
                    
                    // MARK: Blockchain.Headers.getTip
                case .getTip:
                    return Response.Result.Blockchain.Headers.GetTip.self
                    
                    // MARK: Blockchain.Headers.subscribe
                case .subscribe:
                    return Response.Result.Blockchain.Headers.Subscribe.self
                    
                    // MARK: Blockchain.Headers.unsubscribe
                case .unsubscribe:
                    return Response.Result.Blockchain.Headers.Unsubscribe.self
                }
            case .transaction(let transaction):
                switch transaction {
                    
                    // MARK: Blockchain.Transaction.broadcast
                case .broadcast(let rawTransaction):
                    return Response.Result.Blockchain.Transaction.Broadcast.self
                    
                    // MARK: Blockchain.Transaction.get
                case .get(let transactionHash, let verbose):
                    return Response.Result.Blockchain.Transaction.Get.self
                    
                    // MARK: Blockchain.Transaction.getConfirmedBlockHash
                case .getConfirmedBlockHash(let transactionHash, let includeHeader):
                    return Response.Result.Blockchain.Transaction.GetConfirmedBlockHash.self
                    
                    // MARK: Blockchain.Transaction.getHeight
                case .getHeight(let transactionHash):
                    return Response.Result.Blockchain.Transaction.GetHeight.self
                    
                    // MARK: Blockchain.Transaction.getMerkle
                case .getMerkle(let transactionHash):
                    return Response.Result.Blockchain.Transaction.GetMerkle.self
                    
                    // MARK: Blockchain.Transaction.idFromPos
                case .idFromPos(let blockHeight, let transactionPosition, let includeMerkleProof):
                    return Response.Result.Blockchain.Transaction.IDFromPos.self
                    
                    // MARK: Blockchain.Transaction.subscribe
                case .subscribe(let transactionHash):
                    return Response.Result.Blockchain.Transaction.Subscribe.self
                    
                    // MARK: Blockchain.Transaction.unsubscribe
                case .unsubscribe(let transactionHash):
                    return Response.Result.Blockchain.Transaction.Unsubscribe.self
                    
                case .dsProof(let dSProof):
                    switch dSProof {
                        
                        // MARK: Blockchain.Transaction.DSProof.get
                    case .get(let transactionHash):
                        return Response.Result.Blockchain.Transaction.DSProof.Get.self
                        
                        // MARK: Blockchain.Transaction.DSProof.list
                    case .list:
                        return Response.Result.Blockchain.Transaction.DSProof.List.self
                        
                        // MARK: Blockchain.Transaction.DSProof.subscribe
                    case .subscribe(let transactionHash):
                        return Response.Result.Blockchain.Transaction.DSProof.Subscribe.self
                        
                        // MARK: Blockchain.Transaction.DSProof.unsubscribe
                    case .unsubscribe(let transactionHash):
                        return Response.Result.Blockchain.Transaction.DSProof.Unsubscribe.self
                    }
                }
                
            case .utxo(let utxo):
                switch utxo {
                    
                    // MARK: Blockchain.UTXO.getInfo
                case .getInfo(let transactionHash, let outputIndex):
                    return Response.Result.Blockchain.UTXO.GetInfo.self
                }
            }
        case .mempool(let mempool):
            switch mempool {
                
                // MARK: Mempool.getFeeHistogram
            case .getFeeHistogram:
                return Response.Result.Mempool.GetFeeHistogram.self
            }
        }
    }
}
*/
