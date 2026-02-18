import Foundation

extension SwiftTestingTagValidator {
    static func main() {
        do {
            try runValidator()
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(1)
        }
    }

    static func runValidator() throws {
        guard CommandLine.arguments.count >= 5 else {
            throw ValidationError.invalidArguments
        }

        let eventPath = CommandLine.arguments[1]
        let includeTag = normalizeTagValue(CommandLine.arguments[2])
        let excludeTags = parseTagsCSV(CommandLine.arguments[3])
        let outputPath = CommandLine.arguments[4]

        guard !includeTag.isEmpty else {
            throw ValidationError.invalidArguments
        }

        let eventContent = try readText(from: eventPath)
        let records = decodeEventData(from: eventContent)

        let filePaths = Set(records.suites.map { $0.filePath } + records.functions.map { $0.filePath })
        var fileTagDataByPath: [String: FileTagData] = [:]
        for filePath in filePaths.sorted() {
            fileTagDataByPath[filePath] = try parseFileTagData(at: filePath)
        }

        var suiteTagsByIdentifier: [String: Set<String>] = [:]
        for suiteData in records.suites {
            let tags = fileTagDataByPath[suiteData.filePath]?.suiteTagsByLine[suiteData.line] ?? []
            suiteTagsByIdentifier[suiteData.identifier] = tags
        }

        var matchedIdentifiers: [String] = []
        for functionData in records.functions {
            var effectiveTags = fileTagDataByPath[functionData.filePath]?.functionTagsByLine[functionData.line] ?? []
            for suiteIdentifier in deriveAncestorSuiteIdentifiers(from: functionData.identifier) {
                if let inheritedTags = suiteTagsByIdentifier[suiteIdentifier] {
                    effectiveTags.formUnion(inheritedTags)
                }
            }

            guard effectiveTags.contains(includeTag) else { continue }
            guard excludeTags.isDisjoint(with: effectiveTags) else { continue }
            matchedIdentifiers.append(functionData.identifier)
        }

        matchedIdentifiers.sort()
        let output = matchedIdentifiers.joined(separator: "\n") + (matchedIdentifiers.isEmpty ? "" : "\n")
        try writeText(output, to: outputPath)
    }

    static func decodeEventData(from content: String) -> (suites: [SuiteData], functions: [FunctionData]) {
        let decoder = JSONDecoder()
        var suites: [SuiteData] = []
        var functions: [FunctionData] = []

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let eventData = try? decoder.decode(EventData.self, from: Data(line.utf8)) else { continue }
            guard eventData.kind == "test" else { continue }
            guard let identifier = eventData.payload.id,
                  let filePath = eventData.payload.sourceLocation?._filePath,
                  let lineNumber = eventData.payload.sourceLocation?.line,
                  let payloadKind = eventData.payload.kind else { continue }

            if payloadKind == "suite" {
                suites.append(SuiteData(identifier: identifier, filePath: filePath, line: lineNumber))
            } else if payloadKind == "function" {
                functions.append(FunctionData(identifier: identifier, filePath: filePath, line: lineNumber))
            }
        }

        return (suites, functions)
    }

    static func deriveAncestorSuiteIdentifiers(from functionIdentifier: String) -> [String] {
        guard let slashIndex = functionIdentifier.firstIndex(of: "/") else { return [] }
        let suitePath = String(functionIdentifier[..<slashIndex])
        let parts = suitePath.split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return [] }
        return (2...parts.count).map { length in parts.prefix(length).joined(separator: ".") }
    }

    static func normalizeTagValue(_ value: String) -> String {
        var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while normalized.hasPrefix(".") { normalized.removeFirst() }
        return normalized
    }

    static func parseTagsCSV(_ csv: String) -> Set<String> {
        Set(csv.split(separator: ",").map { normalizeTagValue(String($0)) }.filter { !$0.isEmpty })
    }

    static func readText(from path: String) throws -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw ValidationError.cannotReadFile(path, error)
        }
    }

    static func writeText(_ text: String, to path: String) throws {
        do {
            try text.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw ValidationError.cannotWriteFile(path, error)
        }
    }
}
