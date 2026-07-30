// FulcrumNetworkClient~RPARequestSupport.swift

import Foundation

extension FulcrumNetworkClient {
    func validateRequestSupport(
        for method: SwiftFulcrum.RPC.Method,
        in negotiatedSession: NegotiatedSession
    ) throws {
        guard case .blockchain(.rpa(let request)) = method else {
            return
        }

        guard let negotiatedProtocol = negotiatedSession.negotiatedProtocol,
              negotiatedProtocol >= Self.minimumRPAProtocolVersion else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch(
                    "RPA requests require Electrum Cash protocol 1.6.0 or newer."
                )
            )
        }

        guard let capability =
            negotiatedSession.serverFeatures?.reusablePaymentAddress else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("Server does not advertise RPA support.")
            )
        }

        switch request {
        case .getHistory(let prefix, let fromHeight, let toHeight):
            try validateRPAPrefix(prefix, capability: capability)
            try validateRPAHistoryRange(
                fromHeight: fromHeight,
                toHeight: toHeight,
                capability: capability
            )

        case .getMempool(let prefix):
            try validateRPAPrefix(prefix, capability: capability)
        }
    }

    func validateResponseSupport<ResponsePayload>(
        _ response: ResponsePayload,
        for method: SwiftFulcrum.RPC.Method
    ) throws {
        guard case .blockchain(.rpa(.getHistory)) = method,
              let history =
                response as? SwiftFulcrum.Response.Blockchain.RPA.History,
              let maximumHistoryItems =
                state.negotiatedSession.serverFeatures?
                    .reusablePaymentAddress?
                    .maximumHistoryItems else {
            return
        }

        guard history.transactions.count <= maximumHistoryItems else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch(
                    "RPA history response exceeds the server item limit."
                )
            )
        }
    }
}

private extension FulcrumNetworkClient {
    static let minimumRPAProtocolVersion =
        SwiftFulcrum.ProtocolVersion(major: 1, minor: 6, patch: 0)!
    static let defaultMinimumRPAPrefixBits = 8
    static let maximumRPAPrefixBits = 16

    func validateRPAPrefix(
        _ prefix: String,
        capability: SwiftFulcrum.Response.Server.Features.ReusablePaymentAddress
    ) throws {
        let bytes = prefix.utf8
        guard (1 ... 4).contains(bytes.count),
              bytes.allSatisfy(Self.isHexDigit) else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch(
                    "RPA prefix must contain 1 to 4 hexadecimal characters."
                )
            )
        }

        let prefixBitCount = bytes.count * 4
        let minimumPrefixBits =
            capability.minimumPrefixBits ?? Self.defaultMinimumRPAPrefixBits
        guard prefixBitCount >= minimumPrefixBits else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch(
                    "RPA prefix is shorter than the server minimum."
                )
            )
        }

        let indexedPrefixBits =
            capability.indexedPrefixBits ?? Self.maximumRPAPrefixBits
        guard prefixBitCount <= indexedPrefixBits else {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch(
                    "RPA prefix exceeds the server index width."
                )
            )
        }
    }

    func validateRPAHistoryRange(
        fromHeight: UInt,
        toHeight: UInt?,
        capability: SwiftFulcrum.Response.Server.Features.ReusablePaymentAddress
    ) throws {
        if let toHeight {
            guard fromHeight <= toHeight else {
                throw SwiftFulcrum.Client.Error.client(
                    .protocolMismatch(
                        "RPA history end height must not precede its start height."
                    )
                )
            }

            if let historyBlockLimit = capability.historyBlockLimit {
                let requestedBlockCount = toHeight - fromHeight
                guard requestedBlockCount <= UInt(historyBlockLimit) else {
                    throw SwiftFulcrum.Client.Error.client(
                        .protocolMismatch(
                            "RPA history interval exceeds the server block limit."
                        )
                    )
                }
            }
        }

        if let startingHeight = capability.startingHeight {
            guard fromHeight >= UInt(startingHeight) else {
                throw SwiftFulcrum.Client.Error.client(
                    .protocolMismatch(
                        "RPA history starts below the server indexed height."
                    )
                )
            }
        }
    }

    static func isHexDigit(_ byte: UInt8) -> Bool {
        (48 ... 57).contains(byte)
            || (65 ... 70).contains(byte)
            || (97 ... 102).contains(byte)
    }
}
