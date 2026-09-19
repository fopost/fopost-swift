import Foundation

/// Comments, mentions, and direct messages on connected accounts. Every call
/// needs the `inbox` scope.
public struct InboxResource: Resource {
  let transport: Transport

  /// One page of items, newest first by default.
  public func list(_ params: InboxListParams = InboxListParams()) async throws -> InboxPage<
    InboxItem
  > {
    try await httpGet("/inbox", query: params.query, unwrap: false, as: InboxPage<InboxItem>.self)
  }

  /// One row per platform post with comments, or per post we were mentioned
  /// in when `kind` is `.mentions`.
  public func threads(_ params: InboxThreadListParams = InboxThreadListParams()) async throws
    -> InboxPage<InboxThread>
  {
    try await httpGet(
      "/inbox/posts", query: params.query, unwrap: false, as: InboxPage<InboxThread>.self)
  }

  /// One row per DM thread, latest first.
  public func conversations(_ params: InboxConversationListParams = InboxConversationListParams())
    async throws -> InboxPage<InboxConversation>
  {
    try await httpGet(
      "/inbox/conversations", query: params.query, unwrap: false,
      as: InboxPage<InboxConversation>.self)
  }

  /// How many items are unread, optionally in one workspace.
  public func unreadCount(workspaceID: String? = nil) async throws -> UnreadCount {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/inbox/unread-count", query: query, as: UnreadCount.self)
  }

  /// The connected accounts and what each one's inbox can read.
  public func accounts(workspaceID: String? = nil) async throws -> [InboxAccount] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/inbox/accounts", query: query, as: [InboxAccount].self)
  }

  /// What each platform's inbox can do today. Not tenant data.
  public func platforms() async throws -> [InboxPlatform] {
    try await httpGet("/inbox/platforms", as: [InboxPlatform].self)
  }

  /// Marks every item in a thread read.
  @discardableResult
  public func markThreadRead(_ body: MarkInboxReadRequest) async throws -> InboxReadResult {
    try await httpPost("/inbox/read", body: body, as: InboxReadResult.self)
  }

  /// Polls every inbox-capable account in the workspace now.
  public func refresh(workspaceID: String) async throws -> InboxRefreshResult {
    try await httpPost(
      "/inbox/refresh", body: RefreshInboxRequest(workspaceID: workspaceID),
      as: InboxRefreshResult.self)
  }

  /// Changes an item's state. Snoozing needs a future `snoozedUntil`.
  public func update(_ id: String, _ body: UpdateInboxItemRequest) async throws -> InboxItem {
    try await httpPatch("/inbox/\(escapePath(id))", body: body, as: InboxItem.self)
  }

  /// Sends a reply on the platform as the connected account.
  public func reply(_ id: String, text: String) async throws -> InboxReplyResult {
    try await httpPost(
      "/inbox/\(escapePath(id))/reply", body: InboxReplyRequest(text: text),
      as: InboxReplyResult.self)
  }

  /// Hides a comment on the platform.
  public func hide(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/hide", as: InboxItem.self)
  }

  /// Unhides a comment on the platform.
  public func unhide(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/unhide", as: InboxItem.self)
  }

  /// Deletes a comment on the platform.
  @discardableResult
  public func delete(_ id: String) async throws -> InboxDeleteResult {
    try await httpDelete("/inbox/\(escapePath(id))", as: InboxDeleteResult.self)
  }

  /// Replies an automation or the agent drafted that a person still has to
  /// send.
  public func approvals(workspaceID: String? = nil) async throws -> [InboxApproval] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/inbox/approvals", query: query, as: [InboxApproval].self)
  }

  /// Sends a drafted reply, or `text` in its place.
  @discardableResult
  public func approveReply(_ id: Int, text: String? = nil) async throws -> InboxApprovalDecision {
    try await httpPost(
      "/inbox/approvals/\(id)/approve", body: DecideInboxReplyRequest(text: text),
      as: InboxApprovalDecision.self)
  }

  /// Discards a drafted reply.
  @discardableResult
  public func rejectReply(_ id: Int) async throws -> InboxApprovalDecision {
    try await httpPost("/inbox/approvals/\(id)/reject", as: InboxApprovalDecision.self)
  }
}
