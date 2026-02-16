import Foundation

extension SwiftTestingTagValidator {
    static func parseFileTagData(at filePath: String) throws -> FileTagData {
        let content = try readText(from: filePath)
        let lines = content.components(separatedBy: "\n")
        var fileTagData = FileTagData()
        var lineNumber = 1

        while lineNumber <= lines.count {
            guard let tokenData = findTokenData(in: lines[lineNumber - 1]) else {
                lineNumber += 1
                continue
            }

            let attributeData = captureAttributeData(lines: lines, startLine: lineNumber, startColumn: tokenData.column)
            let tags = parseTagsFromAttribute(attributeData.text)

            if !tags.isEmpty {
                var taggedLines: Set<Int> = [lineNumber, attributeData.endLine]
                if let targetLine = findTargetLine(for: tokenData.kind, lines: lines, startLine: lineNumber) {
                    taggedLines.insert(targetLine)
                }

                for taggedLine in taggedLines {
                    if tokenData.kind == "suite" {
                        fileTagData.suiteTagsByLine[taggedLine, default: []].formUnion(tags)
                    } else {
                        fileTagData.functionTagsByLine[taggedLine, default: []].formUnion(tags)
                    }
                }
            }

            lineNumber = max(lineNumber + 1, attributeData.endLine + 1)
        }

        return fileTagData
    }

    static func findTokenData(in line: String) -> TokenData? {
        let suiteRange = line.range(of: "@Suite")
        let testRange = line.range(of: "@Test")
        switch (suiteRange, testRange) {
        case let (.some(suiteValue), .some(testValue)):
            return suiteValue.lowerBound < testValue.lowerBound
                ? TokenData(kind: "suite", column: suiteValue.lowerBound)
                : TokenData(kind: "function", column: testValue.lowerBound)
        case let (.some(suiteValue), .none):
            return TokenData(kind: "suite", column: suiteValue.lowerBound)
        case let (.none, .some(testValue)):
            return TokenData(kind: "function", column: testValue.lowerBound)
        case (.none, .none):
            return nil
        }
    }

    static func captureAttributeData(lines: [String], startLine: Int, startColumn: String.Index) -> AttributeData {
        var lineNumber = startLine
        var text = ""
        var hasOpenParenthesis = false
        var parenthesisDepth = 0

        while lineNumber <= lines.count {
            let line = lines[lineNumber - 1]
            let slice: Substring = (lineNumber == startLine) ? line[startColumn...] : Substring(line)
            text += String(slice) + "\n"

            for character in slice {
                if character == "(" {
                    hasOpenParenthesis = true
                    parenthesisDepth += 1
                } else if character == ")", hasOpenParenthesis {
                    parenthesisDepth -= 1
                }
            }

            if !hasOpenParenthesis || parenthesisDepth <= 0 {
                return AttributeData(text: text, endLine: lineNumber)
            }

            lineNumber += 1
        }

        return AttributeData(text: text, endLine: lines.count)
    }

    static func parseTagsFromAttribute(_ attributeText: String) -> Set<String> {
        var tags = Set<String>()
        guard let tagsRegex = try? NSRegularExpression(pattern: #"\.tags\s*\("#),
              let valueRegex = try? NSRegularExpression(pattern: #"\.[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*"#) else {
            return tags
        }

        let nsAttributeText = attributeText as NSString
        let tagMatches = tagsRegex.matches(in: attributeText, range: NSRange(location: 0, length: nsAttributeText.length))

        for tagMatch in tagMatches {
            let start = tagMatch.range.location + tagMatch.range.length
            var depth = 1
            var index = start

            while index < nsAttributeText.length, depth > 0 {
                let character = nsAttributeText.substring(with: NSRange(location: index, length: 1))
                if character == "(" { depth += 1 }
                if character == ")" { depth -= 1 }
                index += 1
            }

            let bodyLength = max(0, index - start - 1)
            guard bodyLength > 0 else { continue }
            let body = nsAttributeText.substring(with: NSRange(location: start, length: bodyLength))
            let nsBody = body as NSString
            let valueMatches = valueRegex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))

            for valueMatch in valueMatches {
                var value = nsBody.substring(with: valueMatch.range)
                while value.hasPrefix(".") { value.removeFirst() }
                guard !value.isEmpty else { continue }
                tags.insert(value)
                if let leaf = value.split(separator: ".").last {
                    tags.insert(String(leaf))
                }
            }
        }

        return tags
    }

    static func findTargetLine(for kind: String, lines: [String], startLine: Int) -> Int? {
        let pattern = (kind == "suite") ? #"\b(struct|class|actor|enum)\b"# : #"\bfunc\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        var lineNumber = startLine

        while lineNumber <= lines.count {
            let line = lines[lineNumber - 1]
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("//") {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if regex.firstMatch(in: line, range: range) != nil {
                    return lineNumber
                }
            }
            lineNumber += 1
        }

        return nil
    }
}
