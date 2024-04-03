import Foundation

extension Storage.RequestBox: CustomStringConvertible {
    var description: String {
        let storage =
"""
→ <RequestStorage>:
\(requests.map {"\($0.id): \($0.method) - \($0.params)"})
"""
        return storage
    }
}
