// FulcrumRequest+CodingKeys.swift

import Foundation

extension FulcrumRequest {
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }
}
