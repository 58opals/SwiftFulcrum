![Swift 6.4](https://img.shields.io/badge/swift-6.4-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

Status: Stable on main.

Current release: `v0.8.0`, focused on generation-fenced client lifecycle handling, configuration and response validation, simplified WebSocket coordination, and stable OpalDiagnostics 0.2.0 integration.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

SwiftFulcrum is the Swift/BCH network-layer package for talking to public Fulcrum servers over WebSocket JSON-RPC.
It provides an actor-based client, typed RPC methods and result models, reconnect handling, and subscription recovery while staying focused on Fulcrum protocol responsibilities rather than wallet or app-domain logic.

Start with `SwiftFulcrum.Client` when you need typed requests, typed response models, and resilient subscription handling from Apple-platform apps, packages, or tools.

## Purpose and Boundaries

- For Swift/BCH consumers that need a typed Fulcrum adapter, including direct downstream packages such as Opal Base
- Owns Fulcrum transport, protocol modeling, reconnect behavior, bundled server catalogs, and OpalDiagnostics event emission
- Does not own wallet business logic, persistence, UI, or non-Fulcrum protocol expansion

For deeper package context, audience, and integration expectations, see [docs/context.md](docs/context.md).

## Requirements

- Swift tools version: `6.4`
- Platforms:
  - `iOS 27`
  - `macOS 27`
  - `watchOS 27`
  - `tvOS 27`
  - `visionOS 27`

Use the Xcode 27 family with a compiler supporting Swift tools 6.4 and Swift 6 language mode. The supported platform versions above are 27.0 deployment minimums; a newer selected 27.x SDK does not raise them. Before validation, record the active developer-directory selection and overrides, Xcode build, effective Swift compiler and each selected SDK version/path. After any of these inputs changes, use a new external scratch or derived-data lane and rerun the affected builds and tests against the existing dependency lock. Preserve earlier receipts and normal signing/security settings; an IDE update does not silently change package pins or enable live-network test opt-ins. SwiftFulcrum itself does not require Metal; consumers that add it must record that component separately.

## Installation (Swift Package Manager)

For reproducible review of the current Swift 6.4 / OS 27 integration, replace the placeholder below with the full commit hash of a reviewed public `develop` candidate.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", revision: "<reviewed-public-develop-commit>")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "SwiftFulcrum", package: "SwiftFulcrum")
        ]
    )
]
```

The current [Package.swift](Package.swift) pins `OpalDiagnostics` to an exact public integration revision; retain [Package.resolved](Package.resolved) for the complete graph. Applications that also require Diagnostics directly should reuse the manifest's selected revision. The published `v0.8.0` release remains available to version-based consumers; this integration snapshot is not a new SemVer release.

## Quick Start

```swift
import SwiftFulcrum

Task {
    do {
        let client = try await SwiftFulcrum.Client()

        do {
            let tip = try await client.request(SwiftFulcrum.API.blockchain.headers.tip)
            await client.stop()
            // Update application state with tip.height.
        } catch {
            await client.stop()
            throw error
        }
    } catch {
        // Surface the error through application-owned handling.
    }
}
```

`request(...)` starts the client automatically when idle. `SwiftFulcrum.Client()` uses the bundled mainnet server catalog by default; pass `connectingTo:` or `configuration:` when you need a fixed endpoint or different network settings. Bundled catalogs are available for `mainnet`, `testnet`, and `chipnet`.

The [peer catalog contract](docs/peer-catalogs.md) records exact source hashes and ordered inventories, unknown historical upstream/operator provenance, and the separate review and live-qualification process. Catalog inclusion and offline integrity checks do not establish live qualification.

```swift
let configuration = SwiftFulcrum.Client.Configuration(network: .chipnet)
let chipnetClient = try await SwiftFulcrum.Client(
    configuration: configuration
)
// Use chipnetClient, then release its network resources deterministically.
await chipnetClient.stop()
```

## Core Capabilities

- Actor-isolated `SwiftFulcrum.Client` entrypoint for unary requests and streaming subscriptions
- Typed endpoints via `SwiftFulcrum.API`
- Typed response models under `SwiftFulcrum.Response.*`
- Automatic protocol negotiation plus reconnect and failover with subscription recovery
- Bundled public server catalogs for `mainnet`, `testnet`, and `chipnet`
- Connection-state streams and OpalDiagnostics events for observability
- Bounded subscription update buffers by default; slow consumers receive an explicit overflow error and should resubscribe/resync

After a successful reconnect restore, each subscription's existing updates stream receives the current server snapshot before subsequent notifications. Restore snapshots use the same update type as notifications and are emitted even when unchanged, including a null script-hash or address status. Consumers may deduplicate values when appropriate; consumers that need to confirm data freshness should process every restored snapshot. Rejected or malformed restore responses terminate the affected stream and require a fresh subscription.

`Client.subscribeObserved` provides an additive subscription alternative whose initial payload and updates include their producer publication generation. Pair it with `makeConnectionRecoveryStream()` when independently consumed state and data streams must agree across reconnects. Recovery observations carry a monotonic phase sequence and the same generation authority used to fence restore publication; listener installation and the initial snapshot occur in one producer actor turn. Slow or cancelled recovery-stream readers do not delay recovery. The existing `subscribe`, `Subscription.Updates`, and raw connection-state APIs retain their signatures and defaults. Stamps describe publication generation, not the physical socket origin of untagged transport messages buffered across reconnects. A consumer should reject already-published older generations and must not invalidate hydrated data again for a delayed phase in an adopted generation; the ready phase alone does not establish downstream data freshness.

SwiftFulcrum currently uses platform-default URLSession TLS behavior. Custom trust or certificate policy is intentionally not exposed until there is a concrete URLSession-compatible trust API with security-focused tests.

## Diagnostics

SwiftFulcrum emits structured OpalDiagnostics records at high-signal boundaries such as JSON-RPC encoding and decoding, request routing, WebSocket send and receive, reconnect attempts, and subscription recovery. Host applications own runtime diagnostics policy, including minimum level, category filtering, and recent-record buffering.

Targets that configure diagnostics directly should depend on the `OpalDiagnostics` product and import it alongside SwiftFulcrum.

Use `enabledIncludingSubcategories` when the host app wants every SwiftFulcrum diagnostics category under `fulcrum`.

```swift
import OpalDiagnostics

OpalDiagnostics.configure(
    .init(
        minimumLevel: .debug,
        categoryFilter: .enabledIncludingSubcategories(["fulcrum"]),
        bufferPolicy: .enabled(capacity: 500)
    )
)
```

SwiftFulcrum does not print directly and does not expose package-specific logging adapters. Full endpoint URLs, payload previews, server reason strings, localized error messages, addresses, script hashes, transaction IDs, tokens, and JSON-RPC params are treated as private fields.

## Validation

Tests own JSON-RPC mapping, response validation, transport lifecycle, reconnect generations, cancellation, subscriptions, and server catalogs. Preserve boundary failures and late-result races even when their setup resembles another suite. Keep test support local to its consumers and remove helpers only after their last caller disappears.

The default development command builds/discovers once and runs focused configuration, protocol-generation, response-decoding and diagnostics contracts from that same build. It reports its selected definition count and does not claim complete lifecycle, cancellation or reconnect assurance.

```sh
sh scripts/validate.sh
sh scripts/validate.sh focused ClientCancellationValidator
sh scripts/validate.sh --list assurance
sh scripts/validate.sh assurance
```

`focused` accepts a literal substring of a discovered local suite or test identifier, including a complete identifier. Empty, malformed and unmatched selections fail. Successful discovery alone is insufficient: execution must produce a native result containing non-skipped tests. `--list` prints the exact selection after discovery without executing it. `assurance` selects every `SwiftFulcrumLocalTests` definition, including late-result races, cancellation and reconnect behavior. All runner lanes explicitly disable the existing live-network opt-ins, even if inherited from the calling shell; live tests remain a separate operation below.

Set `OPAL_VALIDATION_SCRATCH_PATH` to a per-repository, toolchain-compatible cache when needed; the default is `.build/validation`. Only the current invocation uses `--skip-build`, immediately after discovery has built the same path and options. No persistent receipt bypasses later builds. The tracked dependency lock must exist, resolved versions are forced and lock drift fails validation.

CI resolves the unchanged published graph before compilation, then runs development checks on pull requests and branch pushes. `main`, tags and an explicit `workflow_dispatch` assurance selection run the complete offline local suite. For a raw SwiftPM invocation, preserve the published graph:

```bash
swift package resolve
git diff --exit-code -- Package.resolved
swift test --force-resolved-versions --filter '^SwiftFulcrumLocalTests[./]'
```

To run live-network tests separately, use `SWIFTFULCRUM_RUN_NETWORK=1 swift test --force-resolved-versions --filter '^SwiftFulcrumNetworkTests[./]'`. Existing slow-network gates remain independently opt-in. Offline assurance does not establish live-server acceptance.

## License

SwiftFulcrum is licensed under the [Apache License 2.0](LICENSE). Copyright 2026 58 Opals.
