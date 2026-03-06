import Foundation

extension SwiftFulcrum.RPC.Method {
    func createRequest(with uuid: UUID) -> FulcrumRequest {
        switch self {
        case .server(let server):
            return createServerRequest(server, uuid: uuid)
        case .blockchain(let blockchain):
            return createBlockchainRequest(blockchain, uuid: uuid)
        case .mempool(let mempool):
            return createMempoolRequest(mempool, uuid: uuid)
        }
    }
}
