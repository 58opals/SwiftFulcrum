// FulcrumRequest.swift

import Foundation

struct FulcrumRequest {
    let jsonrpc: String = "2.0"
    let id: UUID
    let method: String
    let requestedMethod: SwiftFulcrum.RPC.Method
    let params: Encodable
    
    init(id: UUID, method: SwiftFulcrum.RPC.Method, params: Encodable) {
        self.id = id
        self.method = method.path
        self.requestedMethod = method
        self.params = params
    }
}

extension FulcrumRequest: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        try container.encode(params, forKey: .params)
    }
}

extension FulcrumRequest: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FulcrumRequest, rhs: FulcrumRequest) -> Bool {
        lhs.id == rhs.id
    }
}

extension FulcrumRequest {
    var data: Data? {
        let traceID = SwiftFulcrumDiagnostics.traceID(for: id)
        do {
            let data = try JSONRPCCodec.Coder.encoder.encode(self)
            SwiftFulcrumDiagnostics.record(
                SwiftFulcrumDiagnostics.Event.jsonRPCRequestEncoded,
                category: SwiftFulcrumDiagnostics.Category.jsonRPC,
                traceID: traceID,
                fields: [
                    SwiftFulcrumDiagnostics.methodField(method),
                    SwiftFulcrumDiagnostics.publicField("request_id", id),
                    SwiftFulcrumDiagnostics.publicField("byte_count", data.count)
                ]
            )
            return data
        } catch {
            SwiftFulcrumDiagnostics.record(
                SwiftFulcrumDiagnostics.Event.jsonRPCRequestEncodeFailed,
                category: SwiftFulcrumDiagnostics.Category.jsonRPC,
                level: .error,
                traceID: traceID,
                fields: [
                    SwiftFulcrumDiagnostics.methodField(method),
                    SwiftFulcrumDiagnostics.publicField("request_id", id)
                ] + SwiftFulcrumDiagnostics.errorFields(error)
            )
            return nil
        }
    }
}
