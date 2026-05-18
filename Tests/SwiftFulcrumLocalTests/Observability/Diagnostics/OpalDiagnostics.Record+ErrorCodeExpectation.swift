// OpalDiagnostics.Record+ErrorCodeExpectation.swift

import OpalDiagnostics
import Testing

extension OpalDiagnostics.Record {
    func expectErrorCode(_ expected: OpalDiagnostics.ErrorCode) {
        let expectedField = OpalDiagnostics.Field.errorCode(expected)
        let actualField = fields.first { $0.name == expectedField.name }
        #expect(actualField?.value == expectedField.value)
        #expect(actualField?.privacy == expectedField.privacy)
    }
}
