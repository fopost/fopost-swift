import Foundation

/// What kind of message an inbox item is.
public struct InboxItemType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let comment: Self = "comment"
  public static let mention: Self = "mention"
  public static let dm: Self = "dm"
  /// A rating left on the business: a Google Business review or a Facebook Page recommendation.
  public static let review: Self = "review"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.comment, .mention, .dm, .review]
}

/// Where an inbox item sits in its workflow.
public struct InboxItemState: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let unread: Self = "unread"
  public static let read: Self = "read"
  public static let resolved: Self = "resolved"
  public static let snoozed: Self = "snoozed"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.unread, .read, .resolved, .snoozed]
}

/// Whether a message came in or went out.
public struct InboxDirection: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let inbound: Self = "inbound"
  public static let outbound: Self = "outbound"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.inbound, .outbound]
}

/// The orders an inbox list can be returned in.
public struct InboxSort: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let newest: Self = "newest"
  public static let oldest: Self = "oldest"
  public static let unanswered: Self = "unanswered"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.newest, .oldest, .unanswered]
}

/// Which threads ``InboxResource/threads(_:)`` groups.
public struct InboxThreadKind: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let comments: Self = "comments"
  public static let mentions: Self = "mentions"
  public static let reviews: Self = "reviews"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.comments, .mentions, .reviews]
}

/// How far a platform's inbox support has come.
public struct InboxCoverage: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let live: Self = "live"
  public static let soon: Self = "soon"
  /// The platform offers no way to read this channel.
  public static let unavailable: Self = "none"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.live, .soon, .unavailable]
}

/// The page metadata inbox lists carry. Unlike ``PageMeta`` it is camelCase
/// and has no last page; ``InboxPage/hasMore`` derives it from the total.
public struct InboxPageMeta: Codable, Sendable, Hashable {
  public let page: Int?
  public let perPage: Int?
  public let total: Int?
}

/// One page of an inbox list: the rows plus their page metadata.
public struct InboxPage<Element: Codable & Sendable>: Codable, Sendable {
  public let data: [Element]
  public let meta: InboxPageMeta?

  /// True when another page follows this one.
  public var hasMore: Bool {
    guard let meta, let page = meta.page, let perPage = meta.perPage, let total = meta.total
    else { return false }
    return page * perPage < total
  }
}

extension InboxPage: Equatable where Element: Equatable {}
extension InboxPage: Hashable where Element: Hashable {}

/// A file, link, or share attached to a message. `url` is served by the API,
/// never a platform URL, and needs the caller's key to fetch.
public struct InboxAttachment: Codable, Sendable, Hashable {
  /// `image`, `video`, `audio`, `file`, `link` or `share`.
  public let kind: String?
  public let name: String?
  public let width: Int?
  public let height: Int?
  /// The target of a `link` attachment.
  public let link: String?
  public let url: String?
  public let previewUrl: String?
}

/// The connected account an inbox row belongs to.
public struct InboxAccountRef: Codable, Sendable, Hashable {
  public let id: String
  public let platform: Platform?
  public let username: String?
  public let name: String?
  public let avatar: String?
}

/// The platform post an item sits under, whoever published it.
public struct InboxPostContext: Codable, Sendable, Hashable {
  public let externalId: String?
  /// Published from one of our accounts.
  public let isOwn: Bool?
  public let text: String?
  public let authorName: String?
  public let authorHandle: String?
  public let authorAvatarUrl: String?
  public let thumbnailUrl: String?
  public let permalink: String?
  public let publishedAt: Date?
  /// The FoPost post this was published from, when it was.
  public let published: [String: JSONValue]?
}

/// One comment, mention, review, or direct message.
public struct InboxItem: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let platform: Platform?
  public let type: InboxItemType?
  public let state: InboxItemState?
  public let direction: InboxDirection?
  public let conversationId: String?
  public let authorName: String?
  public let authorHandle: String?
  public let authorAvatarUrl: String?
  public let text: String?
  /// Stars on a review, 1-5. Nil on every other type.
  public let rating: Int?
  public let attachments: [InboxAttachment]?
  public let permalink: String?
  public let postExternalId: String?
  public let parentExternalId: String?
  public let platformCreatedAt: Date?
  public let snoozedUntil: Date?
  public let repliedAt: Date?
  public let createdAt: Date?
  /// False on platforms whose API reads but cannot answer.
  public let canReply: Bool?
  public let hidden: Bool?
  public let liked: Bool?
  public let pinned: Bool?
  /// Our reaction on a DM.
  public let reaction: String?
  public let editedAt: Date?
  public let canHide: Bool?
  /// A comment someone left, or our own reply.
  public let canDelete: Bool?
  public let canLike: Bool?
  /// Our own comment only.
  public let canPin: Bool?
  /// Our own comment only.
  public let canEdit: Bool?
  public let canReact: Bool?
  public let canSendMedia: Bool?
  public let canQuickReply: Bool?
  /// A DM can be opened from this comment with ``InboxResource/startConversation(_:)``.
  public let canPrivateReply: Bool?
  /// The FoPost post this item was left under, when we published it.
  public let post: [String: JSONValue]?
  public let postContext: InboxPostContext?
  public let account: InboxAccountRef?
}

/// One platform post with comments, one post we were mentioned in, or one review.
public struct InboxThread: Codable, Sendable, Hashable {
  public let workspaceId: String?
  public let accountId: String?
  public let postExternalId: String?
  public let commentCount: Int?
  public let unreadCount: Int?
  public let lastCommentAt: Date?
  public let lastCommentText: String?
  public let lastCommentAuthor: String?
  /// Stars, on a review thread. Nil on comments and mentions.
  public let rating: Int?
  public let post: InboxPostContext?
  public let account: InboxAccountRef?
}

/// One direct-message thread.
public struct InboxConversation: Codable, Sendable, Hashable {
  /// The person on the other side of the thread.
  public struct Participant: Codable, Sendable, Hashable {
    public let name: String?
    public let handle: String?
    public let avatarUrl: String?
  }

  public let workspaceId: String?
  public let accountId: String?
  public let conversationId: String?
  public let messageCount: Int?
  public let unreadCount: Int?
  public let lastMessageAt: Date?
  public let lastMessageText: String?
  public let lastMessageOutbound: Bool?
  public let participant: Participant?
  public let account: InboxAccountRef?
}

/// A connected account and what its inbox can read.
public struct InboxAccount: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let platform: Platform?
  public let username: String?
  public let name: String?
  public let avatar: String?
  /// Comments and mentions can be read for this account.
  public let inboxSupported: Bool?
  public let pendingReason: String?
  public let dmSupported: Bool?
  public let dmPendingReason: String?
  /// A new DM can be opened from this account by handle.
  public let canStartConversation: Bool?
}

/// What one platform's inbox can do today.
public struct InboxPlatform: Codable, Sendable, Hashable {
  public let platform: Platform?
  public let comments: InboxCoverage?
  public let dms: InboxCoverage?
}

/// The outcome of ``InboxResource/refresh(workspaceID:)``.
public struct InboxRefreshResult: Codable, Sendable, Hashable {
  /// An account whose DM grant has to be renewed in the dashboard.
  public struct DMReconnect: Codable, Sendable, Hashable {
    public let platform: Platform?
    public let account: String?
  }

  public let accountsPolled: Int?
  public let newItems: Int?
  /// Accounts the platform rate-limited during this poll.
  public let rateLimited: Int?
  public let dmReconnect: [DMReconnect]?
}

/// A reply an automation or the agent drafted that a person still has to send.
public struct InboxApproval: Codable, Sendable, Hashable {
  /// The approval id, used by the approve and reject calls.
  public let id: Int
  public let workspaceId: String?
  /// What drafted the reply: an automation or the agent.
  public let source: String?
  /// The drafted text.
  public let reply: String?
  public let createdAt: Date?
  public let item: [String: JSONValue]?
}

/// What became of an approval after a decision.
public struct InboxApprovalDecision: Codable, Sendable, Hashable {
  public let id: Int?
  public let outcome: String?
}

/// The reply as the platform recorded it.
public struct InboxReplyRef: Codable, Sendable, Hashable {
  public let externalId: String?
  public let externalUrl: String?
}

/// The item after a reply, and the reply itself.
public struct InboxReplyResult: Codable, Sendable, Hashable {
  public let item: InboxItem?
  public let reply: InboxReplyRef?
}

/// The DM ``InboxResource/startConversation(_:)`` opened, and the message sent.
public struct InboxConversationStart: Codable, Sendable, Hashable {
  public let conversationId: String?
  public let item: InboxItem?
}

/// Whether the typing indicator is showing after
/// ``InboxResource/setTyping(conversationID:accountID:on:)``.
public struct InboxTypingResult: Codable, Sendable, Hashable {
  public let typing: Bool?
}

/// The outcome of ``InboxResource/handover(conversationID:accountID:appID:metadata:)``.
public struct InboxHandover: Codable, Sendable, Hashable {
  /// The app control went to, or nil when it was taken back.
  public let appID: String?
  /// `passed` or `taken`.
  public let control: String

  enum CodingKeys: String, CodingKey {
    case appID = "app_id"
    case control
  }
}

/// How many items ``InboxResource/markThreadRead(_:)`` settled.
public struct InboxReadResult: Codable, Sendable, Hashable {
  public let updated: Int?
}

/// Whether ``InboxResource/delete(_:)`` removed the comment or our reply on the platform.
public struct InboxDeleteResult: Codable, Sendable, Hashable {
  public let deleted: Bool?
}

/// The answer to ``InboxResource/unreadCount(workspaceID:)``.
public struct UnreadCount: Codable, Sendable, Hashable {
  public let count: Int
}

/// Filters and paginates ``InboxResource/list(_:)``. Nil fields are not sent,
/// so the API applies its own defaults.
public struct InboxListParams: Sendable {
  public var workspaceID: String?
  public var type: InboxItemType?
  public var state: InboxItemState?
  public var platform: Platform?
  public var accountID: String?
  public var postID: String?
  public var postExternalID: String?
  public var conversationID: String?
  public var direction: InboxDirection?
  /// Full-text match against message text and author.
  public var q: String?
  public var sort: InboxSort?
  public var page: Int?
  public var perPage: Int?

  public init(
    workspaceID: String? = nil, type: InboxItemType? = nil, state: InboxItemState? = nil,
    platform: Platform? = nil, accountID: String? = nil, postID: String? = nil,
    postExternalID: String? = nil, conversationID: String? = nil,
    direction: InboxDirection? = nil, q: String? = nil, sort: InboxSort? = nil,
    page: Int? = nil, perPage: Int? = nil
  ) {
    self.workspaceID = workspaceID
    self.type = type
    self.state = state
    self.platform = platform
    self.accountID = accountID
    self.postID = postID
    self.postExternalID = postExternalID
    self.conversationID = conversationID
    self.direction = direction
    self.q = q
    self.sort = sort
    self.page = page
    self.perPage = perPage
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("type", type?.rawValue)
    query.add("state", state?.rawValue)
    query.add("platform", platform?.rawValue)
    query.add("account_id", accountID)
    query.add("post_id", postID)
    query.add("post_external_id", postExternalID)
    query.add("conversation_id", conversationID)
    query.add("direction", direction?.rawValue)
    query.add("q", q)
    query.add("sort", sort?.rawValue)
    query.add("page", page)
    query.add("per_page", perPage)
    return query
  }
}

/// Filters and paginates ``InboxResource/threads(_:)``. `kind` defaults to
/// comments on the API side.
public struct InboxThreadListParams: Sendable {
  public var workspaceID: String?
  public var kind: InboxThreadKind?
  public var platform: Platform?
  public var accountID: String?
  public var state: InboxItemState?
  public var q: String?
  public var sort: InboxSort?
  public var page: Int?
  public var perPage: Int?

  public init(
    workspaceID: String? = nil, kind: InboxThreadKind? = nil, platform: Platform? = nil,
    accountID: String? = nil, state: InboxItemState? = nil, q: String? = nil,
    sort: InboxSort? = nil, page: Int? = nil, perPage: Int? = nil
  ) {
    self.workspaceID = workspaceID
    self.kind = kind
    self.platform = platform
    self.accountID = accountID
    self.state = state
    self.q = q
    self.sort = sort
    self.page = page
    self.perPage = perPage
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("kind", kind?.rawValue)
    query.add("platform", platform?.rawValue)
    query.add("account_id", accountID)
    query.add("state", state?.rawValue)
    query.add("q", q)
    query.add("sort", sort?.rawValue)
    query.add("page", page)
    query.add("per_page", perPage)
    return query
  }
}

/// Filters and paginates ``InboxResource/conversations(_:)``.
public struct InboxConversationListParams: Sendable {
  public var workspaceID: String?
  public var platform: Platform?
  public var accountID: String?
  public var state: InboxItemState?
  public var q: String?
  public var sort: InboxSort?
  public var page: Int?
  public var perPage: Int?

  public init(
    workspaceID: String? = nil, platform: Platform? = nil, accountID: String? = nil,
    state: InboxItemState? = nil, q: String? = nil, sort: InboxSort? = nil,
    page: Int? = nil, perPage: Int? = nil
  ) {
    self.workspaceID = workspaceID
    self.platform = platform
    self.accountID = accountID
    self.state = state
    self.q = q
    self.sort = sort
    self.page = page
    self.perPage = perPage
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("platform", platform?.rawValue)
    query.add("account_id", accountID)
    query.add("state", state?.rawValue)
    query.add("q", q)
    query.add("sort", sort?.rawValue)
    query.add("page", page)
    query.add("per_page", perPage)
    return query
  }
}

/// The body of ``InboxResource/markThreadRead(_:)``. Name the thread by its
/// platform post (`postExternalID`) or its DM conversation (`conversationID`).
public struct MarkInboxReadRequest: Codable, Sendable {
  public var workspaceID: String
  public var accountID: String
  public var postExternalID: String?
  public var conversationID: String?

  public init(
    workspaceID: String, accountID: String, postExternalID: String? = nil,
    conversationID: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.accountID = accountID
    self.postExternalID = postExternalID
    self.conversationID = conversationID
  }

  enum CodingKeys: String, CodingKey {
    case workspaceID = "workspace_id"
    case accountID = "account_id"
    case postExternalID = "post_external_id"
    case conversationID = "conversation_id"
  }
}

/// The body of ``InboxResource/update(_:_:)``. `snoozedUntil` is required when
/// the state is `snoozed` and must be in the future.
public struct UpdateInboxItemRequest: Codable, Sendable {
  public var state: InboxItemState
  public var snoozedUntil: Date?

  public init(state: InboxItemState, snoozedUntil: Date? = nil) {
    self.state = state
    self.snoozedUntil = snoozedUntil
  }
}

struct RefreshInboxRequest: Codable, Sendable {
  var workspaceID: String

  enum CodingKeys: String, CodingKey {
    case workspaceID = "workspace_id"
  }
}

/// The body of ``InboxResource/startConversation(_:)``. Name either
/// `accountID` and `handle`, or `commentID` for a private reply to a comment.
public struct StartInboxConversationRequest: Codable, Sendable {
  /// The account to send from, with `handle`.
  public var accountID: String?
  /// Who to message.
  public var handle: String?
  /// An inbox comment to answer privately instead. Only where `canPrivateReply` is true.
  public var commentID: String?
  public var text: String
  /// Media library ids to attach, at most 10.
  public var mediaIDs: [String]?

  public init(
    accountID: String? = nil, handle: String? = nil, commentID: String? = nil, text: String,
    mediaIDs: [String]? = nil
  ) {
    self.accountID = accountID
    self.handle = handle
    self.commentID = commentID
    self.text = text
    self.mediaIDs = mediaIDs
  }

  enum CodingKeys: String, CodingKey {
    case accountID = "account_id"
    case handle
    case commentID = "comment_id"
    case text
    case mediaIDs = "media_ids"
  }
}

struct InboxReplyRequest: Codable, Sendable {
  var text: String?
  var mediaIDs: [String]?
  var quickReplies: [String]?

  enum CodingKeys: String, CodingKey {
    case text
    case mediaIDs = "media_ids"
    case quickReplies = "quick_replies"
  }
}

struct EditInboxCommentRequest: Codable, Sendable {
  var text: String
}

struct ReactInboxItemRequest: Codable, Sendable {
  var reaction: String?

  // Nil is sent as null, which removes our reaction.
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(reaction, forKey: .reaction)
  }
}

struct InboxTypingRequest: Codable, Sendable {
  var accountID: String
  var on: Bool

  enum CodingKeys: String, CodingKey {
    case accountID = "account_id"
    case on
  }
}

struct InboxHandoverRequest: Codable, Sendable {
  var accountID: String
  var appID: String?
  var metadata: String?

  enum CodingKeys: String, CodingKey {
    case accountID = "account_id"
    case appID = "app_id"
    case metadata
  }
}

struct DecideInboxReplyRequest: Codable, Sendable {
  var text: String?
}
