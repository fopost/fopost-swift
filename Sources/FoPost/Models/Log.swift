import Foundation

/// One API request, as the request log recorded it.
public struct LogEntry: Codable, Sendable, Hashable {
  public let id: Int
  public let workspaceID: String?
  public let time: Date?
  /// `jwt` or `api_key`.
  public let authMethod: String?
  public let method: String?
  public let route: String?
  public let path: String?
  public let statusCode: Int?
  public let durationMs: Int?
  public let platform: String?
  public let message: String?

  enum CodingKeys: String, CodingKey {
    case id, time, method, route, path, platform, message
    case workspaceID = "workspace_id"
    case authMethod = "auth_method"
    case statusCode = "status_code"
    case durationMs = "duration_ms"
  }
}

/// Request and error counts for one slice of the window.
public struct LogBucket: Codable, Sendable, Hashable {
  public let at: Date?
  public let total: Int?
  public let errors: Int?
}

/// Totals over the window the page was read from.
public struct LogSummary: Codable, Sendable, Hashable {
  public let since: Date?
  public let total: Int?
  public let errors: Int?
  public let buckets: [LogBucket]?
}

/// The cursor for the next page; `hasMore` is false at the end of the list.
public struct LogPageMeta: Codable, Sendable, Hashable {
  public let nextCursor: String?
  public let hasMore: Bool?

  enum CodingKeys: String, CodingKey {
    case nextCursor = "next_cursor"
    case hasMore = "has_more"
  }
}

/// One page of the request log, newest first, with the window's totals.
public struct LogPage: Codable, Sendable, Hashable {
  public let data: [LogEntry]
  public let meta: LogPageMeta?
  public let summary: LogSummary?
}

/// How to narrow the request log. Nil fields are not sent.
public struct LogListParams: Sendable {
  public var workspaceID: String?
  /// How many days back to read, up to 30.
  public var days: Int?
  /// `success` or `failed`.
  public var status: String?
  public var method: String?
  public var statusCode: Int?
  public var platform: String?
  public var route: String?
  /// Free text matched against the path and message.
  public var q: String?
  public var limit: Int?
  /// The `meta.nextCursor` of the previous page.
  public var before: String?

  public init(
    workspaceID: String? = nil, days: Int? = nil, status: String? = nil, method: String? = nil,
    statusCode: Int? = nil, platform: String? = nil, route: String? = nil, q: String? = nil,
    limit: Int? = nil, before: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.days = days
    self.status = status
    self.method = method
    self.statusCode = statusCode
    self.platform = platform
    self.route = route
    self.q = q
    self.limit = limit
    self.before = before
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("days", days)
    query.add("status", status)
    query.add("method", method)
    query.add("status_code", statusCode)
    query.add("platform", platform)
    query.add("route", route)
    query.add("q", q)
    query.add("limit", limit)
    query.add("before", before)
    return query
  }
}
