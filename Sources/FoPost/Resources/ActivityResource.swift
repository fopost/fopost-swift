import Foundation

/// What happened in a workspace, including the security audit log.
public struct ActivityResource: Resource {
  let transport: Transport

  /// Activity newest first.
  ///
  /// `kind: .security` is the audit log: members joining, leaving or changing
  /// role and access, and changes to two-step verification, passkeys, single
  /// sign-on and signed-in devices. Those rows are append-only and never expire.
  public func list(_ params: ActivityListParams = ActivityListParams()) async throws
    -> ActivityPage
  {
    var query = Query()
    query.add("workspace_id", params.workspaceID)
    query.add("kind", params.kind?.rawValue)
    query.add("from", params.from)
    query.add("to", params.to)
    query.add("cursor", params.cursor)
    query.add("limit", params.limit)
    // The response carries meta beside data, so it is read whole rather than unwrapped.
    return try await httpGet("/activity", query: query, unwrap: false, as: ActivityPage.self)
  }
}
