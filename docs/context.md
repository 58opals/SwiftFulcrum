# SwiftFulcrum Context

This document is the durable repo-owned source of truth for SwiftFulcrum's purpose, audience, boundaries, and integration expectations. The [README](../README.md) stays concise and points here for deeper package context.

## Background and Purpose

SwiftFulcrum exists to give Swift/BCH software a dedicated Fulcrum protocol adapter instead of forcing each consumer to rebuild WebSocket connectivity, JSON-RPC encoding and decoding, reconnect handling, and subscription lifecycle management on its own.

The package is intentionally focused on the public Fulcrum server ecosystem used by Bitcoin Cash applications. It is a protocol-centered layer that stays close to the Fulcrum contract while exposing a Swift-first API surface.

## Protocol Vocabulary

SwiftFulcrum uses a small set of established Fulcrum, JSON-RPC, WebSocket, TLS, and BCH abbreviations when they are the protocol names users already expect: `API`, `BCH`, `DSProof`, `IDFromPos`, `JSONRPC`, `RPC`, `TLS`, and `UTXO`. These terms are accepted package vocabulary in strict implementation code and public facade API chains; avoid inventing expanded spellings that obscure the Fulcrum wire contract.

## Audience and Stakeholders

- Swift package and app authors who need typed BCH network access through Fulcrum
- Opal Base as the direct downstream package in the current BCH stack
- Other wallet and tool consumers that need a reusable Fulcrum client without pulling in higher-level application logic
- Maintainers who need one repo-owned source for what this package is for and where its boundaries stop

## Role in the BCH Stack

SwiftFulcrum is the network and protocol layer for Fulcrum-backed BCH integrations.

It owns:

- WebSocket transport setup for `ws` and `wss` Fulcrum endpoints
- Typed endpoint and response modeling through `SwiftFulcrum.API` and `SwiftFulcrum.Response.*`
- Actor-isolated client lifecycle via `SwiftFulcrum.Client`
- Protocol negotiation, reconnect handling, and best-effort subscription recovery
- Bundled public server catalogs for `mainnet`, `testnet`, and `chipnet`
- Connection-state streams and structured OpalDiagnostics events for downstream observability

It does not own:

- Wallet, account, or spend-planning logic
- UI, persistence, or application-state policy
- Non-Fulcrum network protocols
- Downstream-specific workaround layers that should live in consuming packages or apps
- Package-specific logging frameworks, console logging adapters, or product metrics policy

## Integration Expectations

Use `SwiftFulcrum.Client` as the primary entry point.

- Construct `SwiftFulcrum.Client()` to use the bundled mainnet catalog by default
- Pass `connectingTo:` when a consumer needs a fixed Fulcrum endpoint
- Pass `configuration:` when a consumer needs testnet or chipnet selection, custom TLS behavior, reconnect tuning, bootstrap servers, protocol negotiation settings, or a custom server catalog loader

Use the client surface according to interaction style:

- `request(_:)` for unary typed endpoints that return one decoded result
- `subscribe(_:)` for streaming typed endpoints with an initial response plus an async updates stream
- `makeConnectionStateStream()` when the consumer needs transport-state visibility
- OpalDiagnostics runtime configuration when the host app needs minimum-level control, category filtering, routing policy, or recent-record buffer export

Common integration patterns:

- App or package code can issue typed unary calls such as header, transaction, block, or mempool requests without owning raw JSON-RPC plumbing
- Long-lived consumers can subscribe to address, scripthash, transaction, or proof-related updates while letting the client manage reconnect and subscription restore attempts
- Host apps can enable SwiftFulcrum diagnostics categories such as `fulcrum`, `fulcrum.jsonrpc`, `fulcrum.websocket`, and `fulcrum.reconnect`; SwiftFulcrum only emits structured events and does not decide app-layer diagnostics policy

## Boundaries and Non-Goals

SwiftFulcrum should stay easy to explain as a dedicated Fulcrum adapter.

Non-goals for this repository include:

- Broadening into a general BCH application framework
- Absorbing responsibilities that belong in Opal Base or app-level consumers
- Mixing product or portfolio reporting into the repository context docs
- Using the package context docs as a development-process or release-management runbook
