# fopost-swift

[![CI](https://github.com/fopost/fopost-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/fopost/fopost-swift/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Official Swift SDK for the [FoPost](https://fopost.com) API. Schedule and publish
to every connected social platform from your code.

No third-party dependencies — `URLSession` and `Codable` only.

## Install

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fopost/fopost-swift.git", from: "0.3.0")
]
```

and the product to your target:

```swift
.target(name: "YourApp", dependencies: [.product(name: "FoPost", package: "fopost-swift")])
```

In Xcode: **File → Add Package Dependencies…** and paste the repository URL.

Requires Swift 5.9 or newer, and iOS 15 / macOS 12 / tvOS 15 / watchOS 8.

> **0.x release.** The public API is still settling and minor versions may
> contain breaking changes. Pin an exact version if that matters to you.

## Quick start

```swift
import FoPost

let client = try FoPostClient(apiKey: "fp_...")  // or omit it and set FOPOST_API_KEY

let workspace = try await client.workspaces.list()[0]
let accounts = try await client.accounts.list(workspaceID: workspace.id)

let post = try await client.posts.create(
    CreatePostRequest(
        workspaceID: workspace.id,
        accounts: accounts.map(\.id),
        content: .text("Hello from Swift")))

try await client.posts.publish(post.id)
```

Get a key from **Settings → API Keys** in the FoPost dashboard
(<https://fopost.com/dashboard/settings/api-keys>). It travels as the `X-API-Key`
header, never as a bearer token.

## Content

`.text` builds a single-block post and `.thread` builds one block per entry.
Media is attached per block:

```swift
try await client.posts.create(
    CreatePostRequest(
        workspaceID: workspace.id,
        accounts: accounts.map(\.id),
        content: [
            ContentBlock(text: "First post in the thread"),
            ContentBlock(
                text: "Second one, with an image",
                media: [MediaItem(type: "image", name: "chart.png", url: "https://.../chart.png")]),
        ]))
```

Uploading through the media library gives you an item that drops straight in:

```swift
let uploaded = try await client.media.upload(
    workspaceID: workspace.id,
    file: UploadFile(contentsOf: URL(fileURLWithPath: "chart.png")))

let content = [ContentBlock(text: "Numbers are in", media: [uploaded.asMediaItem()])]
```

A direct upload sends the bytes to storage instead of through the API:
`uploadDirect` presigns, PUTs the file, and completes it in one call, and
`presign` plus `complete(uploadID:)` are there when you want to PUT the bytes
yourself.

```swift
let uploaded = try await client.media.uploadDirect(
    workspaceID: workspace.id, filename: "chart.png", mimeType: "image/png",
    data: try Data(contentsOf: URL(fileURLWithPath: "chart.png")))
```

## Scheduling and publishing

`status` is `.draft` or `.scheduled`; a scheduled post needs `scheduleAt`. To
send something out now, create it and call `publish`. Nothing reaches a platform
without one of those two.

```swift
let post = try await client.posts.create(
    CreatePostRequest(
        workspaceID: workspace.id,
        accounts: accounts.map(\.id),
        content: .text("Ship day"),
        status: .scheduled,
        scheduleAt: Date().addingTimeInterval(3600)))
```

`publish` returns when delivery is **queued**, not when the post is live. Poll
`client.posts.deliveries(post.id)` or subscribe a webhook to learn the outcome.
`publish(_:dryRun: true)` validates the plan without sending anything, and
`preflight` reports per-account blockers and advisory content signals.

## Resources

| Namespace | Covers |
| --- | --- |
| `client.posts` | List, create, update, publish, cancel, retry, preflight, deliveries, publish runs, per-post analytics, bulk actions, CSV import |
| `client.workspaces` | Workspaces and their follower/post roll-up |
| `client.accounts` | Connected accounts, rename, move between workspaces, health, validation, token refresh, history, Telegram connect codes and bot commands, Slack channels, members and posting identity |
| `client.accountGroups` | Named sets of accounts a post can target with `accountGroupID` |
| `client.communities` | The X communities an account can post into |
| `client.labels` | Campaign labels |
| `client.webhooks` | Outbound event subscriptions |
| `client.analytics` | Overview, time series, top posts, posts table, labels, demographics, posting streak, on-demand collection |
| `client.automations` | Automations, runs, stats, manual triggers |
| `client.media` | The media library, uploads, and direct (presigned) uploads |
| `client.inbox` | Comments, mentions, and DMs: list, threads, conversations, unread count, mark read, refresh, state changes, reply (with media and quick replies), comment edits, hide, like, pin, react, delete, start a conversation, typing indicator, reply approvals |
| `client.contacts` | The people behind the inbox: list, get, create, update, delete, the threads one person appears in, CSV import, and the custom fields a workspace keeps. Plus volume and reply time per thread |
| `client.ads` | Boosts, ads, Meta Ads connections, sources, the campaign tree (campaigns, ad sets, ads, bulk status), creatives, audiences, targeting search, reach estimates, insights, lead forms, leads and the stored leads feed |
| `client.validate` | Check a post, text length, or a media URL against platform rules without creating anything |

Lists that paginate return a `Page<T>` carrying `data` and `meta`
(`currentPage`, `perPage`, `total`, `lastPage`, `from`, `to`). `client.posts.all(_:)`
walks every page as an `AsyncThrowingStream`:

```swift
for try await post in client.posts.all(PostListParams(status: .published)) {
    print(post.id)
}
```

Inbox lists return an `InboxPage<T>` instead, whose `meta` is `page`, `perPage`,
and `total`.

## Inbox and ads

Every inbox and contacts call needs an API key with the `inbox` scope — except `contacts.conversationAnalytics`, which reads under `analytics`. Every ads call needs the
`ads` scope. The inbox calls that act on the platform as the account,
`editComment`, `like`, `unlike`, `pin`, `unpin`, `react`, `startConversation`,
`setTyping`, a reply with `mediaIDs` or `quickReplies`, and deleting our own
reply, also need `publish`. The ads calls that spend money, `boost`, `create`,
`setStatus`, `delete`, `bulkSetStatus`, and every create, update, delete, and
duplicate on campaigns, ad sets, and network ads, also need `publish`. Anything
created starts paused unless `paused` is `false`.

```swift
let unread = try await client.inbox.list(
    InboxListParams(workspaceID: workspace.id, state: .unread, sort: .unanswered))
for item in unread.data where item.canReply == true {
    try await client.inbox.reply(item.id, text: "Thanks for the note!")
}

let ad = try await client.ads.boost(
    BoostPostRequest(
        workspaceId: workspace.id, connectionId: connection.id, adAccountId: "act_1234567890",
        postId: post.id, accountId: account.id, name: "Autumn drop boost", goal: .engagement,
        budget: AdBudget(minor: 2000, type: .daily),
        targeting: AdTargeting(countries: ["US", "CA"], ageMin: 21, ageMax: 45)))
_ = try await client.ads.setStatus(ad.id, workspaceID: workspace.id, status: .active)
```

## Contacts

The people behind the inbox: one person however many handles they write from. An inbound item files its author, a reply files whoever you answered, and both fold into whatever is already on file.

```swift
let page = try await client.contacts.list(workspaceID: workspaceID, search: "ada")
for contact in page.data {
  print("\(contact.displayName ?? "") — \(contact.channels.count) handles")
}

// Folds into whoever already holds the first channel, so this cannot duplicate someone.
let contact = try await client.contacts.create(
  CreateContactRequest(
    workspaceID: workspaceID,
    channels: [ContactChannel(platform: "x", handle: "ada_writes")],
    displayName: "Ada Okafor",
    fields: ["plan_tier": "Pro"]))

// A field set to nil is cleared; everything left out is untouched.
_ = try await client.contacts.update(contact.id, UpdateContactRequest(fields: ["region": nil]))
try await client.contacts.delete(contact.id)   // the messages stay in the inbox

// The threads this person appears in, newest first.
for thread in try await client.contacts.conversations(contact.id) {
  print("\(thread.platform) \(thread.messages) messages")
}

// platform and handle are required columns; any other column is a custom field key.
let result = try await client.contacts.importCSV(
  workspaceID: workspaceID, csv: "platform,handle\nx,ada_writes")
print("\(result.created) created, \(result.merged) merged")

// The columns your workspace keeps.
let field = try await client.contacts.createField(
  CreateContactFieldRequest(
    workspaceID: workspaceID, key: "plan_tier", name: "Plan Tier", type: .select,
    options: ["Free", "Pro"]))
try await client.contacts.deleteField(field.id)   // removes every answer to it

// Volume and median reply time per thread. Needs the `analytics` scope.
let report = try await client.contacts.conversationAnalytics(days: 30, sort: "slowest")
```

## Validation

`client.validate` checks content before a post exists. Nothing is stored:

```swift
let result = try await client.validate.post(
    ValidatePostRequest(content: "Ship day", platforms: [.twitter, .linkedin]))
for platform in result.platforms ?? [] where platform.ready != true {
    print(platform.platform ?? "", platform.issues ?? [])
}

let length = try await client.validate.length(
    ValidateLengthRequest(text: "Ship day", platforms: [.twitter]))
let media = try await client.validate.media(
    ValidateMediaRequest(url: "https://yourbrand.com/chart.png"))
```

## Error handling

Every failure is a `FoPostError`, mapped from the response status:

```swift
do {
    try await client.posts.publish(post.id)
} catch let error as FoPostError {
    switch error {
    case .paymentRequired(let details):
        print(details.message, error.upgradeURL as Any)
    case .rateLimited:
        print("retry after \(error.retryAfter ?? 0)s")
    case .validation(let details):
        print(details.field("fields", as: [String].self) ?? [])
    default:
        print(error.localizedDescription)
    }
}
```

| Case | Status |
| --- | --- |
| `.validation` | 400, 422 |
| `.authentication` | 401 |
| `.paymentRequired` | 402 — carries `upgradeURL` |
| `.permissionDenied` | 403 |
| `.notFound` | 404 |
| `.conflict` | 409 |
| `.rateLimited` | 429 — carries `retryAfter` |
| `.server` | 5xx |
| `.api` | anything else |
| `.transport` | the request never reached the API |
| `.decoding` / `.encoding` / `.configuration` | client-side |

Each API case carries `status`, `code`, `message`, the raw `body`, the
`X-RateLimit-*` budget, and `field(_:as:)` for anything the SDK does not model.

## Retries

Three attempts by default — two retries — on HTTP 429, HTTP 5xx, and network
errors. Nothing else is retried, so a 400 or a 404 comes back immediately.
Backoff is exponential from 500 ms, doubling, capped at 60 s; a `Retry-After`
header on a 429 wins, capped the same way. A cancelled task is never retried.

```swift
let client = try FoPostClient(
    apiKey: key,
    configuration: FoPostConfiguration(timeout: 60, maxAttempts: 5))
```

Set `FOPOST_BASE_URL` to point the SDK at another deployment.

## Concurrency

`FoPostClient` is `Sendable`, and so is every model and request type. The whole
public API is `async`/`await`, the package builds in Swift 6 language mode, and
one client is safe to share across tasks and actors.

## Escape hatch

For an endpoint the SDK does not wrap yet:

```swift
let payload = try await client.request(
    method: "GET", path: "/some/new/endpoint", query: ["days": "30"], as: JSONValue.self)
```

Pass any `Encodable` as `body`, and `unwrapData: false` when the endpoint does
not use the `{"data": ...}` envelope.

## Example

`examples/create-post` connects, composes, preflights, and publishes:

```bash
FOPOST_API_KEY=fp_... swift run fopost-example
```

## Contributing

```bash
swift build
swift test
```

Tests run offline against a stubbed `URLProtocol` and never touch the real API.

## Support

Docs at <https://fopost.com/docs>. Questions, bugs, and feature requests go to
[GitHub issues](https://github.com/fopost/fopost-swift/issues) or
<https://fopost.com/contact>.

## License

MIT. See [LICENSE](LICENSE).
