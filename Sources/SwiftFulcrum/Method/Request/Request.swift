import Foundation

struct Request {
    let jsonrpc: String = "2.0"
    let id: UUID
    let method: String
    let requestedMethod: Method
    let params: Encodable
    
    init(id: UUID = .init(), method: Method, params: Encodable) {
        self.id = id
        self.method = method.path
        self.requestedMethod = method
        self.params = params
    }
}

extension Request: Encodable {
    private enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        try container.encode(params, forKey: .params)
    }
}

extension Request: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Request, rhs: Request) -> Bool {
        lhs.id == rhs.id
    }
}

extension Request {
    var data: Data {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return data
        } catch {
            fatalError()
        }
    }
}
