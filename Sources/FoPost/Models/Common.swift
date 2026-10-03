import Foundation

/// One page of a paginated list.
public struct PageMeta: Codable, Sendable, Hashable {
  public let currentPage: Int?
  public let perPage: Int?
  public let total: Int?
  public let lastPage: Int?
  public let from: Int?
  public let to: Int?

  enum CodingKeys: String, CodingKey {
    case currentPage = "current_page"
    case perPage = "per_page"
    case total
    case lastPage = "last_page"
    case from
    case to
  }
}

/// A paginated list response: the rows plus their page metadata.
public struct Page<Element: Codable & Sendable>: Codable, Sendable {
  public let data: [Element]
  public let meta: PageMeta?

  /// True when another page follows this one.
  public var hasMore: Bool {
    guard let meta, let current = meta.currentPage, let last = meta.lastPage else {
      return false
    }
    return current < last
  }
}

extension Page: Equatable where Element: Equatable {}
extension Page: Hashable where Element: Hashable {}

/// The bare acknowledgement several endpoints answer with.
public struct MessageResponse: Codable, Sendable, Hashable {
  public let message: String?
  public let deleted: Int?
}

/// One attachment on a content block.
public struct MediaItem: Codable, Sendable, Hashable {
  /// `image`, `video`, or `gif`.
  public var type: String
  public var name: String?
  public var url: String
  public var size: Double?
  public var alt: String?
  public var thumbnail: String?

  public init(
    type: String, name: String? = nil, url: String, size: Double? = nil, alt: String? = nil,
    thumbnail: String? = nil
  ) {
    self.type = type
    self.name = name
    self.url = url
    self.size = size
    self.alt = alt
    self.thumbnail = thumbnail
  }
}

/// One text-plus-media unit. A single post has one block; a thread has one per
/// entry, in order.
public struct ContentBlock: Codable, Sendable, Hashable {
  public var id: Int?
  public var text: String
  public var media: [MediaItem]?
  public var position: Int?

  public init(text: String, media: [MediaItem]? = nil, position: Int? = nil, id: Int? = nil) {
    self.id = id
    self.text = text
    self.media = media
    self.position = position
  }
}

extension Array where Element == ContentBlock {
  /// The content of a single-block post.
  public static func text(_ text: String, media: [MediaItem]? = nil) -> [ContentBlock] {
    [ContentBlock(text: text, media: media)]
  }

  /// One content block per string, in order.
  public static func thread(_ texts: [String]) -> [ContentBlock] {
    texts.map { ContentBlock(text: $0) }
  }

  /// One content block per string, in order.
  public static func thread(_ texts: String...) -> [ContentBlock] {
    thread(texts)
  }
}

/// Advisory feedback from a preflight check. Blockers arrive as issues instead.
public struct ContentSignal: Codable, Sendable, Hashable {
  /// `info` or `warn`.
  public let level: String
  public let code: String
  public let message: String
}

/// Flags an account whose credentials look shaky.
public struct HealthWarning: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: String?
  public let healthStatus: String?
  public let message: String?
}

/// A string the API defines but may extend. Decoding never fails on a value
/// this SDK has not seen yet, so a new platform or status stays readable.
public protocol FoPostStringEnum: RawRepresentable, Codable, Sendable, Hashable,
  ExpressibleByStringLiteral, CustomStringConvertible
where RawValue == String {
  init(rawValue: String)
}

extension FoPostStringEnum {
  public init(stringLiteral value: String) { self.init(rawValue: value) }

  public init(from decoder: any Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  public var description: String { rawValue }
}

/// The statuses a post moves through.
public struct PostStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let draft: Self = "draft"
  public static let scheduled: Self = "scheduled"
  public static let publishing: Self = "publishing"
  public static let published: Self = "published"
  public static let partiallyFailed: Self = "partially_failed"
  public static let failed: Self = "failed"
  public static let cancelled: Self = "cancelled"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .draft, .scheduled, .publishing, .published, .partiallyFailed, .failed, .cancelled,
  ]
}

/// The statuses one account's delivery moves through.
public struct DeliveryStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let pending: Self = "pending"
  public static let queued: Self = "queued"
  public static let delayed: Self = "delayed"
  public static let publishing: Self = "publishing"
  public static let published: Self = "published"
  public static let failed: Self = "failed"
  public static let cancelled: Self = "cancelled"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .pending, .queued, .delayed, .publishing, .published, .failed, .cancelled,
  ]
}

/// How healthy a connected account's credentials are.
public struct AccountHealthStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let healthy: Self = "healthy"
  public static let degraded: Self = "degraded"
  public static let expired: Self = "expired"
  public static let revoked: Self = "revoked"
  public static let unknown: Self = "unknown"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.healthy, .degraded, .expired, .revoked, .unknown]
}

/// The events a webhook subscription can ask for.
public struct WebhookEvent: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let postPublished: Self = "post.published"
  public static let postFailed: Self = "post.failed"
  public static let postPartiallyFailed: Self = "post.partially_failed"
  public static let deliveryPublished: Self = "delivery.published"
  public static let deliveryFailed: Self = "delivery.failed"
  public static let deliveryDelayed: Self = "delivery.delayed"
  public static let accountHealthChanged: Self = "account.health_changed"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .postPublished, .postFailed, .postPartiallyFailed, .deliveryPublished, .deliveryFailed,
    .deliveryDelayed, .accountHealthChanged,
  ]
}

/// The kinds of workspace a plan can hold.
public struct WorkspaceType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let personal: Self = "PERSONAL"
  public static let team: Self = "TEAM"
  public static let organization: Self = "ORGANIZATION"
  public static let client: Self = "CLIENT"
  public static let project: Self = "PROJECT"
  public static let department: Self = "DEPARTMENT"
  public static let event: Self = "EVENT"
  public static let temporary: Self = "TEMPORARY"
  public static let community: Self = "COMMUNITY"
  public static let brand: Self = "BRAND"
  public static let agency: Self = "AGENCY"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .personal, .team, .organization, .client, .project, .department, .event, .temporary, .community,
    .brand, .agency,
  ]
}

/// The audience a demographics breakdown can describe.
public struct DemographicsAudience: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let followers: Self = "followers"
  public static let engaged: Self = "engaged"
  public static let reached: Self = "reached"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.followers, .engaged, .reached]
}

/// What starts an automation.
public struct AutomationTrigger: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let crossPost: Self = "cross_post"
  public static let rssFeed: Self = "rss_feed"
  public static let apiWebhook: Self = "api_webhook"
  public static let schedule: Self = "schedule"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.crossPost, .rssFeed, .apiWebhook, .schedule]
}

/// What one automation step does.
public struct AutomationAction: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let publish: Self = "publish"
  public static let delay: Self = "delay"
  public static let transform: Self = "transform"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.publish, .delay, .transform]
}

/// The networks an account can be connected to.
public struct Platform: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let twitter: Self = "twitter"
  public static let instagram: Self = "instagram"
  public static let instagramBusiness: Self = "instagram-business"
  public static let facebook: Self = "facebook"
  public static let linkedin: Self = "linkedin"
  public static let tiktok: Self = "tiktok"
  public static let youtube: Self = "youtube"
  public static let bluesky: Self = "bluesky"
  public static let threads: Self = "threads"
  public static let mastodon: Self = "mastodon"
  public static let lemmy: Self = "lemmy"
  public static let pinterest: Self = "pinterest"
  public static let snapchat: Self = "snapchat"
  public static let telegram: Self = "telegram"
  public static let twitch: Self = "twitch"
  public static let discord: Self = "discord"
  public static let slack: Self = "slack"
  public static let reddit: Self = "reddit"
  public static let tumblr: Self = "tumblr"
  public static let dribbble: Self = "dribbble"
  public static let mewe: Self = "mewe"
  public static let devto: Self = "devto"
  public static let hashnode: Self = "hashnode"
  public static let medium: Self = "medium"
  public static let substack: Self = "substack"
  public static let googleBusiness: Self = "google-business"
  public static let kick: Self = "kick"
  public static let listmonk: Self = "listmonk"
  public static let wordpress: Self = "wordpress"
  public static let nostr: Self = "nostr"
  public static let whop: Self = "whop"
  public static let skool: Self = "skool"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .twitter, .instagram, .instagramBusiness, .facebook, .linkedin, .tiktok, .youtube, .bluesky,
    .threads, .mastodon, .lemmy, .pinterest, .snapchat, .telegram, .twitch, .discord, .slack, .reddit, .tumblr,
    .dribbble, .mewe, .devto, .hashnode, .medium, .substack, .googleBusiness, .kick, .listmonk,
    .wordpress, .nostr, .whop, .skool,
  ]
}

/// How a bulk label action applies the labels it is given.
public struct BulkLabelMode: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let replace: Self = "replace"
  public static let add: Self = "add"
  public static let remove: Self = "remove"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.replace, .add, .remove]
}
