import Foundation

struct JSONRPC {
    typealias MethodPath = String
    typealias SubscriptionIdentifier = String
    
    let decoder = JSONDecoder()
}

extension JSONRPC {
    struct IdentifiableResponse: Decodable { let id: UUID }
    struct MethodableResponse: Decodable { let method: MethodPath }
    struct ErrorableResponse: Decodable { let error: Response.Error.Result }
    
    func isDecodable<T: Decodable>(as type: T.Type, from data: Data) -> Bool {
        do { _ = try decoder.decode(T.self, from: data); return true }
        catch { return false }
    }
    
    func isRegularResponse(_ data: Data) -> Bool { isDecodable(as: IdentifiableResponse.self, from: data) }
    func extractID(from data: Data) throws -> UUID {
        let response = try decoder.decode(IdentifiableResponse.self, from: data)
        return response.id
    }
    
    func isSubscriptionResponse(_ data: Data) -> Bool { isDecodable(as: MethodableResponse.self, from: data) }
    func extractMethodPath(from data: Data) throws -> MethodPath {
        let response = try decoder.decode(MethodableResponse.self, from: data)
        let methodString = response.method
        
        return methodString
    }
    
    func isErrorResponse(_ data: Data) -> Bool { isDecodable(as: ErrorableResponse.self, from: data) }
    func extractError(from data: Data) throws -> (UUID, Response.Error.Result) {
        let response = try decoder.decode(ErrorableResponse.self, from: data)
        let id = try self.extractID(from: data)
        return (id, response.error)
    }
}

extension JSONRPC {
    enum ResponseType {
        case regular, subscription, error
    }
    
    func determineResponseType(from data: Data) throws -> ResponseType {
        if isRegularResponse(data) { return .regular }
        else if isSubscriptionResponse(data) { return .subscription }
        else { return .error }
    }
}

extension JSONRPC {
    func getMethodPath(from data: Data) throws -> MethodPath {
        let responseType = try determineResponseType(from: data)
        switch responseType {
        case .regular:
            let id = try self.extractID(from: data)
            let methodPath = "\(id)"//try extractMethodPath(from: data)
            return methodPath
        case .subscription:
            let methodPath = try self.extractMethodPath(from: data)
            return methodPath
        case .error:
            throw Error.decodingFailure(reason: .unexpectedFormat, data: data, description: "The data is not identified as regular response or a subscription response.")
        }
    }
    
    func getGenericResponse<JSONRPCResult: Decodable>(from data: Data) throws -> Response.JSONRPCGeneric<JSONRPCResult> {
        let genericResponse = try decoder.decode(Response.JSONRPCGeneric<JSONRPCResult>.self, from: data)
        return genericResponse
    }
}
/*
extension JSONRPC {
    func processRegularResponse<ResponseResult: Decodable>(data: Data, resultStorage: Storage.ResultBox<ResponseResult>) throws {
        let methodPath = try self.getMethodPath(from: data)
        
        if isRegularResponse(data) {
            let genericResponse: Response.JSONRPCGeneric<ResponseResult> = try self.getGenericResponse(from: data)
            guard let id = genericResponse.id else { throw Error.decodingFailure(reason: .idMissing, data: data, description: "Where is UUID for this regular response?") }
            
            if !isErrorResponse(data) {
                if let jsonrpcResult = genericResponse.result {
                    try resultStorage.store(result: jsonrpcResult, for: id)
                } else {
                    try resultStorage.store(result: nil, for: id)
                }
            } else {
                guard let error = genericResponse.error else { throw Error.decodingFailure(reason: .errorMissing, data: data, description: "There should be a JSONRPC error message.") }
                throw Error.rpc(.init(id: id, error: error), methodPath: methodPath, description: "The JSONRPC error response is detected from the server.")
            }
        }
    }
    
    func processSubscriptionResponse<ResponseNotification: Decodable>(data: Data, notificationStorage: Storage.NotificationBox<ResponseNotification>) throws {
        let methodPath = try self.getMethodPath(from: data)
        
        let genericResponse: Response.JSONRPCGeneric<ResponseNotification> = try self.getGenericResponse(from: data)
        guard isSubscriptionResponse(data) else { return }
        
        guard let method = genericResponse.method else { throw Error.decodingFailure(reason: .methodMissing, data: data, description: "Cannot identify the method.") }
        guard method == methodPath else { throw Error.decodingFailure(reason: .unmatchedMethod(methodFromResponse: method, methodFromExtractor: methodPath), data: data, description: "The method from the response isn't matched with the storing method path.") }
        guard let params = genericResponse.params else { throw Error.decodingFailure(reason: .parametersMissing, data: data, description: "This subscription response needs params to be decoded.") }
        
        try notificationStorage.store(notification: params, for: params.subscriptionIdentifier)
    }
}
*/
/*
extension JSONRPC {
    func storeResponse(from data: Data) throws {
        let methodPath = try self.getMethodPath(from: data)
        
        switch methodPath {
            // MARK: - Blockchain
        case "blockchain.estimatefee":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.estimateFee)
            
        case "blockchain.relayfee":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.relayFee)
            
            // MARK: - Blockchain.Address
        case "blockchain.address.get_balance":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.getBalance)
            
        case "blockchain.address.get_first_use":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.getFirstUse)
            
        case "blockchain.address.get_history":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.getHistory)
            
        case "blockchain.address.get_mempool":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.getMempool)
            
        case "blockchain.address.get_scripthash":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.getScriptHash)
            
        case "blockchain.address.listunspent":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.listUnspent)
            
        case "blockchain.address.subscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.subscribe)
            try processSubscriptionResponse(data: data,
                                            notificationStorage: self.storage.result.blockchain.address.notification)
            
        case "blockchain.address.unsubscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.address.unsubscribe)
            
            // MARK: - Blockchain.Block
        case "blockchain.block.header":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.block.header)
            
        case "blockchain.block.headers":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.block.headers)
            
            // MARK: - Blockchain.Header
        case "blockchain.header.get":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.header.get)
            
            // MARK: - Blockchain.Headers
        case "blockchain.headers.get_tip":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.headers.getTip)
            
        case "blockchain.headers.subscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.headers.subscribe)
            try processSubscriptionResponse(data: data,
                                            notificationStorage: self.storage.result.blockchain.headers.notification)
            
        case "blockchain.headers.unsubscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.headers.unsubscribe)
            
            // MARK: - Blockchain.Transaction
        case "blockchain.transaction.broadcast":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.broadcast)
            
        case "blockchain.transaction.get":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.get)
            
        case "blockchain.transaction.get_confirmed_blockhash":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.getConfirmedBlockHash)
            
        case "blockchain.transaction.get_height":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.getHeight)
            
        case "blockchain.transaction.get_merkle":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.getMerkle)
            
        case "blockchain.transaction.id_from_pos":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.idFromPos)
            
        case "blockchain.transaction.subscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.subscribe)
            try processSubscriptionResponse(data: data,
                                            notificationStorage: self.storage.result.blockchain.transaction.notification)
            
        case "blockchain.transaction.unsubscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.unsubscribe)
            
            // MARK: - Blockchain.Transaction.DSProof
        case "blockchain.transaction.dsproof.get":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.dsProof.get)
            
        case "blockchain.transaction.dsproof.list":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.dsProof.list)
            
        case "blockchain.transaction.dsproof.subscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.dsProof.subscribe)
            try processSubscriptionResponse(data: data,
                                            notificationStorage: self.storage.result.blockchain.transaction.dsProof.notification)
            
        case "blockchain.transaction.dsproof.unsubscribe":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.transaction.dsProof.unsubscribe)
            
            // MARK: - Blockchain.UTXO
        case "blockchain.utxo.get_info":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.blockchain.utxo.getInfo)
            
            // MARK: - Mempool
        case "mempool.get_fee_histogram":
            try processRegularResponse(data: data,
                                       resultStorage: self.storage.result.mempool.getFeeHistogram)
            
        default: throw Error.storage(.unknownMethodPath(methodPath), description: "This method path is not defined.")
        }
    }
}
*/
