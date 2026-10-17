import Foundation

/// The cross-account reporting surface.
public struct AnalyticsResource: Resource {
  let transport: Transport

  /// The headline numbers for the window.
  public func overview(_ params: AnalyticsParams = AnalyticsParams()) async throws
    -> AnalyticsOverview
  {
    try await httpGet("/analytics/overview", query: params.query, as: AnalyticsOverview.self)
  }

  /// One point per day in the window.
  public func timeSeries(_ params: AnalyticsParams = AnalyticsParams()) async throws -> TimeSeries {
    try await httpGet("/analytics/time-series", query: params.query, as: TimeSeries.self)
  }

  /// The best performing posts in the window.
  public func topPosts(_ params: AnalyticsParams = AnalyticsParams()) async throws -> [TopPost] {
    try await httpGet("/analytics/top-posts", query: params.query, as: [TopPost].self)
  }

  /// A per-label campaign roll-up.
  public func labels(_ params: AnalyticsParams = AnalyticsParams()) async throws
    -> [LabelAnalytics]
  {
    try await httpGet("/analytics/labels", query: params.query, as: [LabelAnalytics].self)
  }

  /// Posts with their delivery breakdown, paginated.
  public func postsTable(_ params: AnalyticsParams = AnalyticsParams()) async throws -> PostsTable {
    try await httpGet("/analytics/posts-table", query: params.query, as: PostsTable.self)
  }

  /// 365 days of posting activity.
  public func postingStreak(workspaceID: String? = nil) async throws -> [StreakDay] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    let response = try await httpGet(
      "/analytics/posting-streak", query: query, as: PostingStreakResponse.self)
    return response.streak ?? []
  }

  /// An audience breakdown.
  public func demographics(
    audience: DemographicsAudience? = nil, _ params: AnalyticsParams = AnalyticsParams()
  ) async throws -> Demographics {
    var query = params.query
    query.add("audience", audience?.rawValue)
    return try await httpGet("/analytics/demographics", query: query, as: Demographics.self)
  }

  /// Pulls fresh numbers from the platforms. Throttled harder than the read
  /// endpoints, since every call reaches out to a network.
  @discardableResult
  public func collect(accountID: String? = nil) async throws -> CollectSummary {
    var query = Query()
    query.add("accountId", accountID)
    return try await httpPost("/analytics/collect", query: query, as: CollectSummary.self)
  }

  /// How long a post keeps earning: engagement grouped by the post's age at
  /// each reading. `days` selects posts by publish time, not reading time.
  public func decay(_ params: AnalyticsParams = AnalyticsParams()) async throws -> ContentDecay {
    try await httpGet("/analytics/decay", query: params.query, as: ContentDecay.self)
  }

  /// Whether posting more earned more: weekly cadence against what each
  /// cadence earned per post.
  public func frequency(_ params: AnalyticsParams = AnalyticsParams()) async throws
    -> PostingFrequency
  {
    try await httpGet("/analytics/frequency", query: params.query, as: PostingFrequency.self)
  }

  /// Every reading held for one post, oldest first, with what moved between
  /// them and one timeline per delivery.
  ///
  /// - Parameter idOrPermalink: a FoPost post id, or the permalink of a post
  ///   made natively on the network.
  public func timeline(_ idOrPermalink: String) async throws -> PostTimeline {
    let path = "/analytics/posts/\(Self.escape(idOrPermalink))/timeline"
    return try await httpGet(path, as: PostTimeline.self)
  }

  /// Readings recorded after `since`, oldest first, with a cursor to continue.
  /// Poll it to mirror the metrics into your own store instead of refetching
  /// the whole history.
  public func changes(_ params: MetricChangesParams = MetricChangesParams()) async throws
    -> MetricChangePage
  {
    try await httpGet("/analytics/changes", query: params.query, as: MetricChangePage.self)
  }

  /// Re-reads one post from the network now. Spends the same per-user budget
  /// as ``collect(accountID:)``, so a burst answers 429.
  ///
  /// - Parameter idOrPermalink: a FoPost post id, or the permalink of a post
  ///   made natively on the network.
  @discardableResult
  public func collectPost(_ idOrPermalink: String) async throws -> CollectPostResult {
    let path = "/posts/\(Self.escape(idOrPermalink))/analytics/collect"
    return try await httpPost(path, as: CollectPostResult.self)
  }

  /// Posts on the account that never went out through FoPost, newest first.
  public func nativePosts(
    accountID: String, _ params: NativePostsParams = NativePostsParams()
  ) async throws -> InboxPage<NativePost> {
    try await httpGet(
      "/accounts/\(accountID)/native-posts", query: params.query, unwrap: false,
      as: InboxPage<NativePost>.self)
  }

  /// A post can be addressed by permalink, whose slashes would otherwise split
  /// the path.
  private static func escape(_ value: String) -> String {
    // The unreserved set of RFC 3986, so an id stays readable and a permalink
    // loses only the characters that would split the path.
    var unreserved = CharacterSet.alphanumerics
    unreserved.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
  }
}
