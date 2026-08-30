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
