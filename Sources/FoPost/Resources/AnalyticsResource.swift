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
}
