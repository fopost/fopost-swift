import Foundation

/// The window and scope shared by most analytics calls. `days` and an explicit
/// `from`/`to` range are alternatives; nil fields leave the API's defaults in
/// place.
public struct AnalyticsParams: Sendable {
  public var accountID: String?
  public var workspaceID: String?
  public var days: Int?
  /// `YYYY-MM-DD`.
  public var from: String?
  /// `YYYY-MM-DD`.
  public var to: String?
  /// Caps the rows returned, where the endpoint supports it.
  public var limit: Int?
  /// `recent` on top posts, to order by date instead of performance.
  public var sort: String?
  /// Narrows top posts to one campaign label.
  public var label: String?
  public var page: Int?

  public init(
    accountID: String? = nil, workspaceID: String? = nil, days: Int? = nil,
    from: String? = nil, to: String? = nil, limit: Int? = nil, sort: String? = nil,
    label: String? = nil, page: Int? = nil
  ) {
    self.accountID = accountID
    self.workspaceID = workspaceID
    self.days = days
    self.from = from
    self.to = to
    self.limit = limit
    self.sort = sort
    self.label = label
    self.page = page
  }

  var query: Query {
    var query = Query()
    query.add("accountId", accountID)
    query.add("workspace_id", workspaceID)
    query.add("days", days)
    query.add("from", from)
    query.add("to", to)
    query.add("limit", limit)
    query.add("sort", sort)
    query.add("label", label)
    query.add("page", page)
    return query
  }
}

/// Period-over-period changes, as fractions. A nil field means there was no
/// earlier period to compare against.
public struct AnalyticsDeltas: Codable, Sendable, Hashable {
  public let followers: Double?
  public let posts: Double?
  public let engagement: Double?
  public let impressions: Double?
  public let likes: Double?
  public let comments: Double?
  public let shares: Double?
  public let profileViews: Double?
}

/// One day's follower reading in an account's history.
public struct FollowerHistoryPoint: Codable, Sendable, Hashable {
  public let date: String?
  public let followers: Int?
}

/// One account inside the analytics overview.
public struct OverviewAccount: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let username: String?
  public let name: String?
  public let avatar: String?
  public let followers: Int?
  public let totalPosts: Int?
  public let fetchedAt: Date?
  public let history: [FollowerHistoryPoint]?
}

/// One platform's share of the accounts in scope.
public struct OverviewPlatform: Codable, Sendable, Hashable {
  public let platform: Platform?
  public let accounts: Int?
  public let followers: Int?
}

/// The headline roll-up across every account in scope.
public struct AnalyticsOverview: Codable, Sendable, Hashable {
  public struct TodayStats: Codable, Sendable, Hashable {
    public let posts: Int?
    public let followerChange: Int?
    public let engagement: Int?
  }

  public let totalAccounts: Int?
  public let totalFollowers: Int?
  public let totalPosts: Int?
  public let totalEngagement: Int?
  public let totalImpressions: Int?
  public let totalReach: Int?
  public let totalLikes: Int?
  public let totalComments: Int?
  public let totalShares: Int?
  public let totalReposts: Int?
  public let totalSaves: Int?
  public let totalClicks: Int?
  public let totalVideoViews: Int?
  public let totalProfileViews: Int?
  public let engagementRate: Double?
  public let deltas: AnalyticsDeltas?
  public let todayStats: TodayStats?
  public let platforms: [OverviewPlatform]?
  public let accounts: [OverviewAccount]?
}

/// One day of activity.
public struct TimeSeriesPoint: Codable, Sendable, Hashable {
  public let date: String?
  public let engagements: Int?
  public let impressions: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let followers: Int?
  public let posts: Int?
}

/// Daily activity over the window.
public struct TimeSeries: Codable, Sendable, Hashable {
  public let days: Int?
  public let series: [TimeSeriesPoint]?
}

/// One platform a top post reached.
public struct TopPostPlatform: Codable, Sendable, Hashable {
  public let platform: Platform?
  public let username: String?
  public let url: String?
}

/// A top post's numbers.
public struct TopPostMetrics: Codable, Sendable, Hashable {
  public let engagements: Int?
  public let impressions: Int?
  public let reach: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let reposts: Int?
  public let clicks: Int?
  public let saves: Int?
  public let videoViews: Int?
}

/// One high-performing post. `source` is `fopost` for a post published from
/// here, or `platform` for one found on the account.
public struct TopPost: Codable, Sendable, Hashable {
  public let rank: Int?
  public let postId: String?
  public let externalPostId: String?
  public let source: String?
  public let preview: String?
  public let permalink: String?
  public let thumbnailUrl: String?
  public let status: PostStatus?
  public let createdAt: Date?
  public let platforms: [TopPostPlatform]?
  public let labels: [PostLabelRef]?
  public let metrics: TopPostMetrics?
}

/// One campaign label's performance.
public struct LabelAnalytics: Codable, Sendable, Hashable {
  public let labelId: String?
  public let name: String?
  public let color: String?
  public let postCount: Int?
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let engagementRate: Double?
  public let followerDelta: Int?
}

/// One row of the posts table, with its per-platform delivery breakdown.
public struct PostsTableRow: Codable, Sendable, Hashable {
  public struct PlatformRow: Codable, Sendable, Hashable {
    public let platform: Platform?
    public let username: String?
    public let url: String?
    public let deliveryStatus: DeliveryStatus?
  }

  public struct DeliverySummary: Codable, Sendable, Hashable {
    public let total: Int?
    public let published: Int?
    public let failed: Int?
    public let pending: Int?
  }

  public let postId: String?
  public let preview: String?
  public let status: PostStatus?
  public let createdAt: Date?
  public let scheduledAt: Date?
  public let platforms: [PlatformRow]?
  public let deliverySummary: DeliverySummary?
}

/// Posts with their delivery breakdown, paginated.
public struct PostsTable: Codable, Sendable, Hashable {
  public struct StatusSummary: Codable, Sendable, Hashable {
    public let draft: Int?
    public let scheduled: Int?
    public let published: Int?
    public let failed: Int?
    public let pending: Int?
    public let total: Int?
  }

  public let posts: [PostsTableRow]?
  public let total: Int?
  public let page: Int?
  public let limit: Int?
  public let statusSummary: StatusSummary?
}

/// One day of posting activity.
public struct StreakDay: Codable, Sendable, Hashable {
  public let date: String?
  public let count: Int?
  public let publishedCount: Int?
  public let failedCount: Int?
  public let scheduledCount: Int?
}

struct PostingStreakResponse: Codable, Sendable {
  let streak: [StreakDay]?
}

/// One slice of an audience: a value and its share.
public struct DemographicsBucket: Codable, Sendable, Hashable {
  public let key: String?
  public let value: Double?
  public let share: Double?
}

/// Names an account in a demographics response.
public struct AnalyticsAccountRef: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let username: String?
}

/// An audience breakdown. `unsupportedAccounts` names the accounts whose
/// platform does not report demographics.
public struct Demographics: Codable, Sendable, Hashable {
  public struct Dimensions: Codable, Sendable, Hashable {
    public let age: [DemographicsBucket]?
    public let gender: [DemographicsBucket]?
    public let country: [DemographicsBucket]?
    public let city: [DemographicsBucket]?
  }

  public let audience: DemographicsAudience?
  public let dimensions: Dimensions?
  public let contributingAccounts: [AnalyticsAccountRef]?
  public let unsupportedAccounts: [AnalyticsAccountRef]?
}

/// What a collection run refreshed.
public struct CollectSummary: Codable, Sendable, Hashable {
  public struct ErrorDetail: Codable, Sendable, Hashable {
    public let accountId: String?
    public let platform: Platform?
    public let username: String?
    /// `account`, `demographics`, `timeline`, or `post`.
    public let stage: String?
    public let message: String?
  }

  public let accounts: Int?
  public let posts: Int?
  public let demographics: Int?
  public let errors: Int?
  public let errorDetails: [ErrorDetail]?
}

// MARK: - Deeper analytics

/// One age band of the content decay report.
public struct DecayBand: Codable, Sendable, Hashable {
  public let bucket: String?
  public let label: String?
  /// Posts with at least one reading in this band.
  public let posts: Int?
  public let avgEngagements: Double?
  public let avgImpressions: Double?
  /// Mean share of the post's final engagement reached by this age, 0-1.
  /// `nil` when nothing in the band had earned anything yet.
  public let shareOfFinal: Double?
}

/// How engagement accumulates as a post ages.
public struct ContentDecay: Codable, Sendable, Hashable {
  public let days: Int?
  /// Posts with a publish time and at least one later reading.
  public let postsMeasured: Int?
  /// First band where the average post had passed half its final engagement.
  public let halfLifeBucket: String?
  public let bands: [DecayBand]?
}

/// One week of posting. `weekStart` is the Monday, UTC, as `YYYY-MM-DD`.
public struct FrequencyWeek: Codable, Sendable, Hashable {
  public let weekStart: String?
  public let posts: Int?
  public let engagements: Int?
  public let avgEngagementsPerPost: Double?
}

/// The weeks that shared a cadence, folded together.
public struct FrequencyBand: Codable, Sendable, Hashable {
  public let band: String?
  public let label: String?
  public let weeks: Int?
  public let posts: Int?
  public let avgPostsPerWeek: Double?
  public let avgEngagementsPerPost: Double?
  /// Engagements over reach, impressions as the stand-in; `nil` with neither.
  public let engagementRate: Double?
}

/// Weekly cadence set against what each cadence earned per post.
public struct PostingFrequency: Codable, Sendable, Hashable {
  public let days: Int?
  public let weeks: [FrequencyWeek]?
  public let bands: [FrequencyBand]?
  /// The cadence that earned the most per post; `nil` without posts.
  public let best: FrequencyBand?
}

/// What moved between one reading and the one before it.
public struct TimelineDelta: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
}

/// One reading of a post.
public struct TimelinePoint: Codable, Sendable, Hashable {
  public let at: String?
  /// Minutes since publication; `nil` when the network never said when.
  public let ageMinutes: Int?
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let videoViews: Int?
  public let delta: TimelineDelta?
}

/// One delivery's readings: the same post on two networks decays differently.
public struct TimelineDelivery: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let username: String?
  public let externalPostId: String?
  public let postedAt: String?
  public let points: [TimelinePoint]?
}

/// Every reading held for one post, one timeline per delivery.
public struct PostTimeline: Codable, Sendable, Hashable {
  /// `nil` when the post was made natively on the network.
  public let postId: String?
  public let deliveries: [TimelineDelivery]?
}

/// One reading, as the changes feed reports it.
public struct MetricChange: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let externalPostId: String?
  /// `nil` for a post made natively on the network.
  public let postId: String?
  public let postedAt: String?
  public let fetchedAt: String?
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
}

/// One page of readings. Feed `cursor` back as the next `since`.
public struct MetricChangePage: Codable, Sendable, Hashable {
  public let since: String?
  /// `nil` when nothing changed.
  public let cursor: String?
  public let hasMore: Bool?
  public let changes: [MetricChange]?
}

/// What the on-demand refresh did for one delivery.
public struct CollectPostDelivery: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let externalPostId: String?
  public let collected: Bool?
  public let fetchedAt: String?
  /// Why the refresh did not happen.
  public let message: String?
}

/// What one post's refresh managed.
public struct CollectPostResult: Codable, Sendable, Hashable {
  public let collected: Int?
  public let deliveries: [CollectPostDelivery]?
}

/// The freshest reading held for a post made outside FoPost.
public struct NativePostMetrics: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let engagements: Int?
  public let likes: Int?
  public let comments: Int?
  public let shares: Int?
  public let videoViews: Int?
}

/// A post on the account that never went out through FoPost.
public struct NativePost: Codable, Sendable, Hashable {
  public let externalPostId: String?
  public let text: String?
  public let permalink: String?
  public let thumbnailUrl: String?
  public let mediaType: String?
  public let postedAt: String?
  public let fetchedAt: String?
  public let metrics: NativePostMetrics?
}

/// Filters for the changes feed. `since` is an ISO 8601 timestamp; leaving it
/// unset asks for the last seven days.
public struct MetricChangesParams: Sendable {
  public var since: String?
  public var limit: Int?
  public var workspaceID: String?
  public var accountID: String?

  public init(
    since: String? = nil, limit: Int? = nil, workspaceID: String? = nil, accountID: String? = nil
  ) {
    self.since = since
    self.limit = limit
    self.workspaceID = workspaceID
    self.accountID = accountID
  }

  var query: Query {
    var query = Query()
    query.add("since", since)
    query.add("limit", limit)
    query.add("workspace_id", workspaceID)
    query.add("accountId", accountID)
    return query
  }
}

/// Pagination for the posts made outside FoPost.
public struct NativePostsParams: Sendable {
  public var page: Int?
  public var perPage: Int?
  /// Keep only posts published in the last this many days.
  public var days: Int?

  public init(page: Int? = nil, perPage: Int? = nil, days: Int? = nil) {
    self.page = page
    self.perPage = perPage
    self.days = days
  }

  var query: Query {
    var query = Query()
    query.add("page", page)
    query.add("per_page", perPage)
    query.add("days", days)
    return query
  }
}
