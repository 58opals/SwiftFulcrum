// OpalDiagnostics.TraceID+SwiftFulcrum.swift

import Foundation
import OpalDiagnostics

extension OpalDiagnostics.TraceID {
    init(swiftFulcrumRequestID requestID: UUID) {
        self.init(rawValue: requestID.uuidString)
    }
}
