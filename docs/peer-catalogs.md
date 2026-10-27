# Peer catalog provenance and qualification

The bundled catalogs are first-party-maintained configuration inputs for community Fulcrum services. Inclusion is not an endorsement, an operator identity attestation, or evidence that a peer is reachable, honest, independent, or suitable for a particular application. **Every peer in the inventory below is not live-qualified by this snapshot.**

## Reviewed source snapshot

The offline inventory was recorded on 2026-10-27 from public integration revision `e9e7d74a609c59a6f7f5da23655ff0a719417531`. These SHA-256 values bind the exact source JSON bytes, including formatting; they do not authenticate a remote service.

| Resource under `Sources/SwiftFulcrum/Network/WebSocket/` | Entries | SHA-256 |
| --- | --- | --- |
| [servers.mainnet.json](../Sources/SwiftFulcrum/Network/WebSocket/servers.mainnet.json) | 8 | `57bed7a91c4b5fa8feb26a9e149735a928cdedbc5c74ebafc8f7dab257f52f59` |
| [servers.testnet.json](../Sources/SwiftFulcrum/Network/WebSocket/servers.testnet.json) | 2 | `e5e46e61f09c20b3149e498a2ac0d15ad36eb7beee10b93f2263b24d0613b759` |
| [servers.chipnet.json](../Sources/SwiftFulcrum/Network/WebSocket/servers.chipnet.json) | 1 | `a8096798611a0814db629a4b5d0e0e25d5b73540feb7b10945ffcb7fc88cd524` |

Repository history records the last change to the mainnet resource at `ab534d2a32ceebe15e84ba2a87d77cbf3a7a315a` (2025-12-20), and to the testnet and chipnet resources at `d5ee465534c3af912b01cb8272b16267e3be0ef6` (2026-04-30). That is evidence of the maintained repository bytes, not an identified historical upstream catalog. Per-entry upstream import provenance and independently established operator ownership are not recorded here.

The status applying to every entry is: source bytes reviewed offline; historical upstream origin unknown; operator identity and independence unverified; last live qualification not recorded; no live qualification performed for this snapshot. A catalog edit date must not be used as a last successful connection date.

## Ordered inventory

Order below is source order. It is not a health ranking, a trust score, or a guarantee of connection priority.

| Network | Position | Endpoint |
| --- | --- | --- |
| mainnet | 1 | `wss://bch.imaginary.cash:50004` |
| mainnet | 2 | `wss://fulcrum.greyh.at:50004` |
| mainnet | 3 | `wss://cashnode.bch.ninja:50004` |
| mainnet | 4 | `wss://fulcrum.fountainhead.cash:50002` |
| mainnet | 5 | `wss://electrum.imaginary.cash:50004` |
| mainnet | 6 | `wss://electroncash.dk:50004` |
| mainnet | 7 | `wss://bch.loping.net:50004` |
| mainnet | 8 | `wss://fulcrum.jettscythe.xyz:50004` |
| testnet | 1 | `wss://testnet.imaginary.cash:50004` |
| testnet | 2 | `wss://testnet.bch.loping.net:51004` |
| chipnet | 1 | `wss://chipnet.imaginary.cash:50004` |

## Loading and trust semantics

`Client()` selects the mainnet bundled catalog by default. The [bundled loader](../Sources/SwiftFulcrum/ServerCatalog/ServerCatalog.Repository+BundledLoader.swift) returns a nonempty successfully decoded resource; supplied fallback URLs are used when that resource is unavailable, undecodable, or empty. Explicit endpoints and custom repositories retain their existing behavior. Parsing, network selection, fallback and URL normalization do not qualify a peer.

These snapshots contain `wss` endpoints. The public endpoint APIs also support `ws`; this document changes neither accepted schemes nor transport policy. TLS continues to use platform-default URLSession behavior. Certificate/hostname validation protects a connection to the selected hostname; it does not establish operator identity or independence, canonical-chain selection, complete transaction history, or correct balances. Applications remain responsible for their provider trust and verification requirements.

## Review and live qualification

1. For a proposed catalog change, record the exact repository revision, source path, old/new digest and ordered URL diff. Identify the external source and immutable revision when known; otherwise keep the origin explicitly unknown. Review network, scheme, port, credentials and path semantics without silently altering selection or TLS policy.
2. Keep offline integrity separate from live evidence. Update the documented snapshot and independent expected inventory only after reviewing the actual peer change. Run `sh scripts/validate.sh focused ServerCatalogRepositoryValidator`; the raw-byte and bundled-order checks guard against unreviewed default-peer changes, not outages or malicious responses.
3. If live qualification is required, obtain separate authorization for the explicit endpoints, network, public read-only requests, time budget and evidence handling. Use the documented opt-in network-test lane only with the intended test selection and endpoint configuration. Do not use wallet addresses, account identifiers, signing or broadcast. Offline checks do not authorize probes.
4. Record the UTC observation time, exact endpoint and network, tested protocol/features, genesis/network checks, normal TLS result, bounded availability outcome and evidence references. Attribute operator claims to their evidence; a DNS name, certificate, shared branding or different hostnames alone do not prove independent operators. Retain failures and uncertainties. A passing observation is limited to those checks at that time.
5. Reassess before application exposure and after endpoint, ownership, source or relevant transport changes. A past success does not become a permanent health or honesty guarantee. Application chain-view cross-checking remains separate from proving history completeness, balances or full-node validation.

The [README](../README.md#validation) owns executable validation commands and live opt-in gates. This contract supplies no current operational qualification or permission to contact a service.
