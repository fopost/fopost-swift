import Foundation

/// A label as it appears on a post.
public struct PostLabelRef: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let color: String?
}

/// One account a post targets, with its delivery outcome.
public struct PostAccountResult: Codable, Sendable, Hashable {
  public let id: String
  public let platform: String?
  public let username: String?
  public let name: String?
  public let avatar: String?
  public let publishStatus: String?
  public let postedAt: Date?
  public let platformPostID: String?
  public let externalURL: String?
  public let errorCode: String?
  public let errorMessage: String?
  public let rawErrorMessage: String?
  public let attempts: Int?
  public let maxAttempts: Int?

  enum CodingKeys: String, CodingKey {
    case id, platform, username, name, avatar, attempts
    case publishStatus = "publish_status"
    case postedAt = "posted_at"
    case platformPostID = "platform_post_id"
    case externalURL = "external_url"
    case errorCode = "error_code"
    case errorMessage = "error_message"
    case rawErrorMessage = "raw_error_message"
    case maxAttempts = "max_attempts"
  }
}

/// A composed post and everything scheduled or delivered from it.
public struct Post: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  public let status: PostStatus?
  public let contentType: String?
  public let scheduleAt: Date?
  public let repeatable: Bool?
  public let repeatableTimes: Int?
  public let repeatableGap: Int?
  public let repeatableGapUnit: String?
  public let remainingPosts: Int?
  public let title: String?
  public let summary: String?
  public let autoPlug: Bool?
  public let autoPlugContent: String?
  public let content: [ContentBlock]?
  public let accounts: [PostAccountResult]?
  public let labels: [PostLabelRef]?
  public let settings: [String: JSONValue]?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, status, repeatable, title, summary, content, accounts, labels, settings
    case workspaceID = "workspace_id"
    case contentType = "content_type"
    case scheduleAt = "schedule_at"
    case repeatableTimes = "repeatable_times"
    case repeatableGap = "repeatable_gap"
    case repeatableGapUnit = "repeatable_gap_unit"
    case remainingPosts = "remaining_posts"
    case autoPlug = "auto_plug"
    case autoPlugContent = "auto_plug_content"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// Filters and paginates ``PostsResource/list(_:)``. Nil fields are not sent,
/// so the API applies its own defaults (page 1, 30 per page).
public struct PostListParams: Sendable {
  public var page: Int?
  public var perPage: Int?
  public var workspaceID: String?
  public var status: PostStatus?
  /// Full-text match against post content.
  public var search: String?
  public var platforms: [String]?
  public var labels: [String]?
  public var accountIDs: [String]?
  /// `YYYY-MM-DD`, posts created on this day.
  public var date: String?
  /// `YYYY-MM-DD`.
  public var from: String?
  /// `YYYY-MM-DD`.
  public var to: String?
  /// `oldest` reverses the default newest-first order.
  public var sort: String?

  public init(
    page: Int? = nil, perPage: Int? = nil, workspaceID: String? = nil,
    status: PostStatus? = nil, search: String? = nil, platforms: [String]? = nil,
    labels: [String]? = nil, accountIDs: [String]? = nil, date: String? = nil,
    from: String? = nil, to: String? = nil, sort: String? = nil
  ) {
    self.page = page
    self.perPage = perPage
    self.workspaceID = workspaceID
    self.status = status
    self.search = search
    self.platforms = platforms
    self.labels = labels
    self.accountIDs = accountIDs
    self.date = date
    self.from = from
    self.to = to
    self.sort = sort
  }

  var query: Query {
    var query = Query()
    query.add("page", page)
    query.add("per_page", perPage)
    query.add("workspace_id", workspaceID)
    query.add("status", status?.rawValue)
    query.add("search", search)
    query.add("platform", platforms)
    query.add("label", labels)
    query.add("account_id", accountIDs)
    query.add("date", date)
    query.add("from", from)
    query.add("to", to)
    query.add("sort", sort)
    return query
  }
}

/// The body of ``PostsResource/create(_:)``. `status` is `draft` or
/// `scheduled`; a scheduled post needs `scheduleAt`. To send a post out now,
/// create it and call ``PostsResource/publish(_:accountIDs:dryRun:)``.
public struct CreatePostRequest: Codable, Sendable {
  public var workspaceID: String
  public var accounts: [String]
  /// A group whose accounts are added to ``accounts``, each account once.
  public var accountGroupID: String?
  public var content: [ContentBlock]
  /// `post`, `thread`, or `reel`.
  public var contentType: String?
  /// `text_post`, `thread`, `article`, `carousel`, `short_video`, or `link_share`.
  public var artifactType: String?
  public var status: PostStatus?
  public var scheduleAt: Date?
  public var repeatable: Bool?
  public var repeatableTimes: Int?
  public var repeatableGap: Int?
  public var repeatableGapUnit: String?
  public var labels: [String]?
  public var title: String?
  public var internalTitle: String?
  public var summary: String?
  public var autoPlug: Bool?
  public var autoPlugContent: String?
  /// Per-platform options, keyed by platform.
  public var settings: [String: JSONValue]?
  public var sourceIDs: [String]?
  public var companionOf: String?

  public init(
    workspaceID: String, accounts: [String] = [], accountGroupID: String? = nil,
    content: [ContentBlock],
    contentType: String? = nil, artifactType: String? = nil, status: PostStatus? = nil,
    scheduleAt: Date? = nil, repeatable: Bool? = nil, repeatableTimes: Int? = nil,
    repeatableGap: Int? = nil, repeatableGapUnit: String? = nil, labels: [String]? = nil,
    title: String? = nil, internalTitle: String? = nil, summary: String? = nil,
    autoPlug: Bool? = nil, autoPlugContent: String? = nil,
    settings: [String: JSONValue]? = nil, sourceIDs: [String]? = nil,
    companionOf: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.accounts = accounts
    self.accountGroupID = accountGroupID
    self.content = content
    self.contentType = contentType
    self.artifactType = artifactType
    self.status = status
    self.scheduleAt = scheduleAt
    self.repeatable = repeatable
    self.repeatableTimes = repeatableTimes
    self.repeatableGap = repeatableGap
    self.repeatableGapUnit = repeatableGapUnit
    self.labels = labels
    self.title = title
    self.internalTitle = internalTitle
    self.summary = summary
    self.autoPlug = autoPlug
    self.autoPlugContent = autoPlugContent
    self.settings = settings
    self.sourceIDs = sourceIDs
    self.companionOf = companionOf
  }

  enum CodingKeys: String, CodingKey {
    case accounts, content, status, repeatable, labels, title, summary, settings
    case workspaceID = "workspace_id"
    case accountGroupID = "account_group_id"
    case contentType = "content_type"
    case artifactType = "artifact_type"
    case scheduleAt = "schedule_at"
    case repeatableTimes = "repeatable_times"
    case repeatableGap = "repeatable_gap"
    case repeatableGapUnit = "repeatable_gap_unit"
    case internalTitle = "internal_title"
    case autoPlug = "auto_plug"
    case autoPlugContent = "auto_plug_content"
    case sourceIDs = "source_ids"
    case companionOf = "companion_of"
  }
}

/// The body of ``PostsResource/update(_:_:)``. Only the fields you set are
/// sent, so an update is a partial one.
public struct UpdatePostRequest: Codable, Sendable {
  public var accounts: [String]?
  public var content: [ContentBlock]?
  public var contentType: String?
  public var artifactType: String?
  public var status: PostStatus?
  public var scheduleAt: Date?
  public var repeatable: Bool?
  public var repeatableTimes: Int?
  public var repeatableGap: Int?
  public var repeatableGapUnit: String?
  public var labels: [String]?
  public var title: String?
  public var internalTitle: String?
  public var summary: String?
  public var autoPlug: Bool?
  public var autoPlugContent: String?
  public var settings: [String: JSONValue]?

  public init(
    accounts: [String]? = nil, content: [ContentBlock]? = nil, contentType: String? = nil,
    artifactType: String? = nil, status: PostStatus? = nil, scheduleAt: Date? = nil,
    repeatable: Bool? = nil, repeatableTimes: Int? = nil, repeatableGap: Int? = nil,
    repeatableGapUnit: String? = nil, labels: [String]? = nil, title: String? = nil,
    internalTitle: String? = nil, summary: String? = nil, autoPlug: Bool? = nil,
    autoPlugContent: String? = nil, settings: [String: JSONValue]? = nil
  ) {
    self.accounts = accounts
    self.content = content
    self.contentType = contentType
    self.artifactType = artifactType
    self.status = status
    self.scheduleAt = scheduleAt
    self.repeatable = repeatable
    self.repeatableTimes = repeatableTimes
    self.repeatableGap = repeatableGap
    self.repeatableGapUnit = repeatableGapUnit
    self.labels = labels
    self.title = title
    self.internalTitle = internalTitle
    self.summary = summary
    self.autoPlug = autoPlug
    self.autoPlugContent = autoPlugContent
    self.settings = settings
  }

  enum CodingKeys: String, CodingKey {
    case accounts, content, status, repeatable, labels, title, summary, settings
    case contentType = "content_type"
    case artifactType = "artifact_type"
    case scheduleAt = "schedule_at"
    case repeatableTimes = "repeatable_times"
    case repeatableGap = "repeatable_gap"
    case repeatableGapUnit = "repeatable_gap_unit"
    case internalTitle = "internal_title"
    case autoPlug = "auto_plug"
    case autoPlugContent = "auto_plug_content"
  }
}

/// The id and status of the copy ``PostsResource/duplicate(_:)`` created.
public struct DuplicatedPost: Codable, Sendable, Hashable {
  public let id: String
  public let status: PostStatus?
}

/// A post reference carried by several publishing responses.
public struct PostRef: Codable, Sendable, Hashable {
  public let id: String
  public let status: PostStatus?
}

/// One account's delivery as reported by publish or retry.
public struct PublishDelivery: Codable, Sendable, Hashable {
  public let id: String?
  public let accountId: String?
  public let status: DeliveryStatus?
  public let errorCode: String?
  public let errorMessage: String?
  public let platformPostId: String?
  public let externalUrl: String?
  public let postedAt: Date?
  public let attempts: Int?
  public let scheduledPublishAt: Date?
  public let delayReason: String?
  public let delayMessage: String?
}

/// One account named in a plan or an outcome list.
public struct AccountPlanRef: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: String?
  public let attempts: Int?
}

/// The outcome of a publish. On a dry run, `dryRun` is true and `deliveries`
/// is empty — the per-account plan is in `accounts` instead.
public struct PublishResult: Codable, Sendable, Hashable {
  public let dryRun: Bool?
  public let postStatus: PostStatus?
  public let deliveries: [PublishDelivery]?
  public let healthWarnings: [HealthWarning]?
  public let post: PostRef?
  public let accounts: [AccountPlanRef]?

  enum CodingKeys: String, CodingKey {
    case dryRun, deliveries, healthWarnings, post, accounts
    case postStatus = "post_status"
  }
}

/// Reports the deliveries retried and the ones out of attempts.
public struct RetryResult: Codable, Sendable, Hashable {
  public let postStatus: PostStatus?
  public let deliveries: [PublishDelivery]?
  public let exceeded: [AccountPlanRef]?

  enum CodingKeys: String, CodingKey {
    case deliveries, exceeded
    case postStatus = "post_status"
  }
}

/// Reports the deliveries a cancel stopped.
public struct CancelResult: Codable, Sendable, Hashable {
  public let postStatus: PostStatus?
  public let deliveries: [PublishDelivery]?

  enum CodingKeys: String, CodingKey {
    case deliveries
    case postStatus = "post_status"
  }
}

/// One account's readiness. `issues` block publishing; `signals` are advisory.
public struct PreflightAccount: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: String?
  public let username: String?
  public let ready: Bool?
  public let issues: [String]?
  public let score: Double?
  public let signals: [ContentSignal]?
}

/// Per-account blockers and advisory content signals for a post.
public struct PreflightResult: Codable, Sendable, Hashable {
  public let ready: Bool?
  public let post: PostRef?
  public let accounts: [PreflightAccount]?
}

/// One account's delivery record for a post.
public struct Delivery: Codable, Sendable, Hashable {
  public let id: String
  public let accountId: String?
  public let status: DeliveryStatus?
  public let errorCode: String?
  public let errorMessage: String?
  public let attempts: Int?
  public let maxAttempts: Int?
  public let scheduledPublishAt: Date?
  public let delayReason: String?
  public let delayMessage: String?
  public let postedAt: Date?
  public let lastAttemptAt: Date?
  public let platformPostId: String?
  public let externalUrl: String?
  public let platform: String?
  public let username: String?
  public let accountName: String?
}

/// One account's outcome within a single publish run.
public struct PublishRunDelivery: Codable, Sendable, Hashable {
  public let accountID: String?
  public let accountName: String?
  public let username: String?
  public let platform: String?
  public let status: DeliveryStatus?
  public let attemptNumber: Int?
  public let errorCode: String?
  public let errorMessage: String?
  public let platformPostID: String?
  public let externalURL: String?
  public let startedAt: Date?
  public let completedAt: Date?
  public let durationMs: Int?

  enum CodingKeys: String, CodingKey {
    case username, platform, status
    case accountID = "account_id"
    case accountName = "account_name"
    case attemptNumber = "attempt_number"
    case errorCode = "error_code"
    case errorMessage = "error_message"
    case platformPostID = "platform_post_id"
    case externalURL = "external_url"
    case startedAt = "started_at"
    case completedAt = "completed_at"
    case durationMs = "duration_ms"
  }
}

/// One attempt at publishing a post, with its per-account results.
public struct PublishRun: Codable, Sendable, Hashable {
  public let id: String
  public let runNumber: Int?
  public let status: String?
  public let startedAt: Date?
  public let completedAt: Date?
  public let deliveries: [PublishRunDelivery]?

  enum CodingKeys: String, CodingKey {
    case id, status, deliveries
    case runNumber = "run_number"
    case startedAt = "started_at"
    case completedAt = "completed_at"
  }
}

/// One platform's numbers for a post. A nil field means the platform does not
/// report that metric.
public struct PostAnalyticsMetrics: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let reposts: Int?
  public let clicks: Int?
  public let saves: Int?
  public let videoViews: Int?
  public let watchTimeMs: Int?
  public let avgWatchTimeMs: Int?
  public let reactionsBreakdown: [String: JSONValue]?
  public let follows: Int?
  public let fetchedAt: Date?
}

/// A post's totalled performance.
public struct PostAnalyticsTotals: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let reposts: Int?
  public let clicks: Int?
  public let saves: Int?
  public let videoViews: Int?
  public let follows: Int?
}

/// One platform's slice of a post's analytics.
public struct PostAnalyticsPlatform: Codable, Sendable, Hashable {
  public let platform: String?
  public let username: String?
  public let externalPostId: String?
  public let permalink: String?
  public let thumbnailUrl: String?
  public let mediaType: String?
  public let postedAt: Date?
  public let metrics: PostAnalyticsMetrics?
}

/// A post's performance, totalled and per platform.
public struct PostAnalytics: Codable, Sendable, Hashable {
  public let postId: String?
  public let totals: PostAnalyticsTotals?
  public let platforms: [PostAnalyticsPlatform]?
  public let lastFetchedAt: Date?
}

/// Reports how many posts a bulk action changed.
public struct BulkResult: Codable, Sendable, Hashable {
  public let updated: Int?
  public let action: String?
  public let mode: String?
}

/// One CSV row as the bulk-import validator read it.
public struct BulkImportRow: Codable, Sendable, Hashable {
  public let row: Int?
  public let contentPreview: String?
  public let scheduleAt: Date?
  public let accounts: [String]?
  public let labels: Int?
  public let hasMedia: Bool?
  public let errors: [String]?

  enum CodingKeys: String, CodingKey {
    case row, accounts, labels, errors
    case contentPreview = "content_preview"
    case scheduleAt = "schedule_at"
    case hasMedia = "has_media"
  }
}

/// The dry run of a CSV import.
public struct BulkImportValidation: Codable, Sendable, Hashable {
  public let totalRows: Int?
  public let validRows: Int?
  public let invalidRows: Int?
  public let rows: [BulkImportRow]?

  enum CodingKeys: String, CodingKey {
    case rows
    case totalRows = "total_rows"
    case validRows = "valid_rows"
    case invalidRows = "invalid_rows"
  }
}

/// A post a committed CSV import created.
public struct BulkImportPost: Codable, Sendable, Hashable {
  public let id: String
  public let scheduleAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case scheduleAt = "schedule_at"
  }
}

/// What a committed CSV import created. Keep `batchID` to roll the whole batch
/// back.
public struct BulkImportResult: Codable, Sendable, Hashable {
  public let batchID: String?
  public let created: Int?
  public let posts: [BulkImportPost]?

  enum CodingKeys: String, CodingKey {
    case created, posts
    case batchID = "batch_id"
  }
}
