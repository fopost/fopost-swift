import Foundation

/// The request log: every API call made with the account's keys.
public struct LogsResource: Resource {
  let transport: Transport

  /// Requests newest first, with totals for the window. Page by passing
  /// `meta.nextCursor` back as `before`.
  public func list(_ params: LogListParams = LogListParams()) async throws -> LogPage {
    try await httpGet("/logs", query: params.query, unwrap: false, as: LogPage.self)
  }
}
