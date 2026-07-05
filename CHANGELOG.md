# Changelog

All notable changes to SwiftFulcrum will be documented here.

This changelog starts with the currently curated public release history. Earlier public tags exist from `v0.1.0` through `v0.5.5`; use the Git tag history for their detailed changes.

## [Unreleased]

### Added

- Changelog file for curated release notes, with a README link from the package front door.

## [v0.7.0] - 2026-07-05

### Added

- Bounded subscription backpressure with explicit overflow errors for slow consumers.
- Owned subscription update sequences and registry-backed subscription lifecycle handling.
- Typed WebSocket connection and reconnection attempt behavior.
- Shared timeout and cancellation orchestration across request and subscription flows.
- Release documentation for the public SwiftPM package.

### Changed

- Reconnect recovery state is now explicit, with more precise diagnostics around reconnect and session recovery.
- TLS posture is documented as platform-default URLSession behavior until a tested custom trust API exists.

## [v0.6.0] - 2026-07-05

### Changed

- Catch-up public release for the already-public `main` branch state after `v0.5.5`.
- Captured the stable SwiftFulcrum facade, OpalDiagnostics adoption, stricter response and catalog validation, chipnet catalog support, Swift 6.2 platform baseline, and license/documentation normalization.

### Notes

- This tag introduced no source changes beyond labeling the existing public `main` state.

## [v0.5.5] - 2026-02-02

### Notes

- Last release before the curated changelog history. Earlier public tags are available in Git history.

[Unreleased]: https://github.com/58opals/SwiftFulcrum/compare/v0.7.0...HEAD
[v0.7.0]: https://github.com/58opals/SwiftFulcrum/compare/v0.6.0...v0.7.0
[v0.6.0]: https://github.com/58opals/SwiftFulcrum/compare/v0.5.5...v0.6.0
[v0.5.5]: https://github.com/58opals/SwiftFulcrum/releases/tag/v0.5.5
