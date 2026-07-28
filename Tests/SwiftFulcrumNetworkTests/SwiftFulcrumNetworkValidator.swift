// SwiftFulcrumNetworkValidator.swift

import Testing
import SwiftFulcrumTestSupport

@Suite(
    .serialized,
    .enabled(
        if: TestExecutionPolicy.shouldRunNetwork,
        Comment(rawValue: TestExecutionPolicy.networkDisabledMessage)
    )
)
enum SwiftFulcrumNetworkValidator {}
