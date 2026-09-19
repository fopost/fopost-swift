# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What This Is

`fopost-swift` is the official Swift SDK for the FoPost API — a Swift Package
Manager package named `FoPost` (library product `FoPost`, module `FoPost`).
Swift packages are distributed **by git tag**, not through a registry: tagging
`v<version>` is the release, and the Swift Package Index picks it up.

It wraps the same REST API as the sibling SDKs (`fopost-go`, `fopost-python`,
`fopost-js`, `fopost-ruby`, …). When an endpoint's shape is unclear, the
authority is `../fopost-api-collections/openapi.json`, and `../fopost-go` is the
closest reference implementation.

**Zero third-party dependencies.** `URLSession` and `Codable` only. Never add a
package dependency — not for JSON, not for testing, not for logging.

## Brand Rules

- The product is **FoPost** (`fopost.com`). Never write "OwlStack" — retired Aug 2026.
- Never write an email address. Support is https://fopost.com/contact and GitHub issues.
- Never name AI providers/models, infrastructure vendors, or any person.

## Architecture

```
Sources/FoPost/
  FoPost.swift          fopostVersion, the Empty response type
  FoPostClient.swift    the entry point, the resource namespaces, the escape hatch
  Configuration.swift   base URL, timeout, retry budget, User-Agent
  Transport.swift       signing, retrying, decoding — every request goes through it
  FoPostError.swift     FoPostError + FoPostAPIErrorDetails
  RateLimit.swift       the X-RateLimit-* headers
  Coding.swift          the shared JSONEncoder/JSONDecoder, timestamps, the data envelope
  Query.swift           query-parameter builder that skips empty values
  Multipart.swift       hand-built multipart/form-data
  JSONValue.swift       arbitrary JSON, for open-ended fields
  Models/               Codable structs, one file per domain
  Resources/            one struct per namespace, all conforming to Resource
```

A call flows `client.posts.create(_:)` → `Resource.httpPost` → `Transport.send`
→ `URLSession` → `Transport.decode`. The `Resource` protocol extension owns the
`httpGet`/`httpPost`/`httpPut`/`httpPatch`/`httpDelete`/`httpUpload` helpers —
they are prefixed so a resource can define its own `get`/`delete` without
shadowing them.

Coverage: posts, workspaces, accounts, communities, labels, webhooks,
analytics, automations, media, inbox, and ads. Inbox skips `/inbox/chat/*`
(browser-encrypted X Chat) and the binary `/inbox/{id}/attachments/{index}`
stream. Ads doc comments name the four spending calls (`boost`, `create`,
`setStatus`, `delete`) that need the `publish` scope on top of `ads`.

Design notes worth keeping:

- **Resources are computed properties on the client**, not stored ones, so the
  client stays `Sendable` with only immutable state.
- **String enums are open** (`FoPostStringEnum`): `Platform`, `PostStatus`, and
  friends are structs wrapping a raw `String` with static constants, so a value
  the API adds tomorrow decodes instead of throwing. Never turn one back into a
  Swift `enum`.
- **The `{"data": ...}` envelope is peeled tolerantly.** `EnvelopeProbe` checks
  for the key and only unwraps when it is there, because a few endpoints answer
  bare. List endpoints that carry `meta` decode as `Page<T>` with `unwrap: false`;
  inbox lists carry a camelCase `meta` and decode as `InboxPage<T>`.
- **Model fields are `Optional`** almost everywhere. The API omits what it has
  not computed; a non-optional field is a decode failure waiting to happen.
- **Timestamps** parse ISO 8601 with and without fractional seconds plus a
  couple of plain forms, and encode as RFC 3339 in UTC.

## API Contract

- Base URL `https://api.fopost.com/v1`, overridden by `FOPOST_BASE_URL`
- Auth is the header `X-API-Key`, **not** `Authorization: Bearer`. The key falls
  back to the `FOPOST_API_KEY` environment variable
- `User-Agent: fopost-swift/<version>`, 30 s timeout
- Retries: 3 attempts total, only on 429, 5xx, and network errors. Exponential
  backoff from 500 ms, doubling, capped at 60 s; `Retry-After` wins on a 429.
  A cancelled task is never retried
- Success envelope `{"data": ...}`; paginated lists add `meta` in snake_case
- Error envelope `{"error": "<code>", "message": "<text>"}`; 402 may carry
  `upgrade_url`, exposed as `FoPostError.upgradeURL`
- Rate limit headers `X-RateLimit-Limit`, `-Remaining`, `-Reset` on every response

## Commands

```bash
swift build
swift test
swift run fopost-example        # needs FOPOST_API_KEY
swift package describe          # validate the manifest
swift-format format -i -r Sources Tests examples   # if swift-format is installed
```

## Conventions

- The public API is `async`/`await` throughout, and the package builds in Swift
  6 language mode. Everything public is `Sendable`
- Doc comments (`///`) on every public symbol; that is what Xcode and DocC read.
  Inline `//` comments only for a non-obvious "why"
- Four-space indent, 100-column lines, `swift-format`'s default style
- Request bodies are `Codable` structs with explicit `CodingKeys` **only** where
  the JSON key differs from the Swift name. The API mixes snake_case and
  camelCase per endpoint, so a global `.convertFromSnakeCase` would be wrong
- Tests are XCTest (not swift-testing, so an older toolchain still runs them)
  and always offline: `StubURLProtocol` is injected through
  `URLSessionConfiguration.protocolClasses`. **Never write a test that reaches
  the network.** `makeStubClient(...)` shortens the retry waits so a retry test
  finishes in milliseconds

## Releasing

Bump `fopostVersion` in `Sources/FoPost/FoPost.swift`, then tag `v<version>`.
`.github/workflows/release.yml` builds, tests, checks the tag against
`fopostVersion`, and creates the GitHub Release with the built-in `GITHUB_TOKEN`.

**No registry secret is needed.** Swift packages resolve straight from the git
tag, so unlike the npm/PyPI/RubyGems siblings there is nothing to publish and no
`*_TOKEN` repo secret to configure.

## Git

Conventional Commits, atomic. Branch `feature/<description>`, merge to `main`
via PR. Never `gh pr create` — push the branch and hand over the compare link.
