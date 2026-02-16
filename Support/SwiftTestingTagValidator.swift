import Foundation

@main
enum SwiftTestingTagValidator {
    struct SourceLocationData: Decodable {
        let _filePath: String?
        let line: Int?
    }

    struct PayloadData: Decodable {
        let id: String?
        let kind: String?
        let sourceLocation: SourceLocationData?
    }

    struct EventData: Decodable {
        let kind: String
        let payload: PayloadData
    }

    struct SuiteData {
        let identifier: String
        let filePath: String
        let line: Int
    }

    struct FunctionData {
        let identifier: String
        let filePath: String
        let line: Int
    }

    struct TokenData {
        let kind: String
        let column: String.Index
    }

    struct AttributeData {
        let text: String
        let endLine: Int
    }

    struct FileTagData {
        var suiteTagsByLine: [Int: Set<String>] = [:]
        var functionTagsByLine: [Int: Set<String>] = [:]
    }

    enum ValidationError: Error, CustomStringConvertible {
        case invalidArguments
        case cannotReadFile(String, Error)
        case cannotWriteFile(String, Error)

        var description: String {
            switch self {
            case .invalidArguments:
                return "usage: SwiftTestingTagValidator <event-jsonl> <include-tag> <exclude-tags-csv> <output-file>"
            case let .cannotReadFile(path, error):
                return "failed to read \(path): \(error.localizedDescription)"
            case let .cannotWriteFile(path, error):
                return "failed to write \(path): \(error.localizedDescription)"
            }
        }
    }
}
