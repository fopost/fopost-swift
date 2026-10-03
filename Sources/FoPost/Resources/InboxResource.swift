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

  /// Edits our own comment on the platform. Also needs the `publish` scope.
  public func editComment(_ id: String, text: String) async throws -> InboxItem {
    try await httpPatch(
      "/inbox/\(escapePath(id))", body: EditInboxCommentRequest(text: text), as: InboxItem.self)
  }

  /// Sends a reply on the platform as the connected account. `text` may be
  /// omitted when `mediaIDs` is given. `mediaIDs` (at most 10) and
  /// `quickReplies` (at most 13, each up to 20 characters) apply to DMs and
  /// also need the `publish` scope.
  public func reply(
    _ id: String, text: String? = nil, mediaIDs: [String]? = nil, quickReplies: [String]? = nil
  ) async throws -> InboxReplyResult {
    try await httpPost(
      "/inbox/\(escapePath(id))/reply",
      body: InboxReplyRequest(text: text, mediaIDs: mediaIDs, quickReplies: quickReplies),
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

  /// Likes an item on the platform. Also needs the `publish` scope.
  public func like(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/like", as: InboxItem.self)
  }

  /// Removes our like. Also needs the `publish` scope.
  public func unlike(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/unlike", as: InboxItem.self)
  }

  /// Pins our own comment. Also needs the `publish` scope.
  public func pin(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/pin", as: InboxItem.self)
  }

  /// Unpins our own comment. Also needs the `publish` scope.
  public func unpin(_ id: String) async throws -> InboxItem {
    try await httpPost("/inbox/\(escapePath(id))/unpin", as: InboxItem.self)
  }

  /// Reacts to a message with an emoji, or removes ours when `reaction` is
  /// nil. Also needs the `publish` scope.
  public func react(_ id: String, reaction: String?) async throws -> InboxItem {
    try await httpPost(
      "/inbox/\(escapePath(id))/react", body: ReactInboxItemRequest(reaction: reaction),
      as: InboxItem.self)
  }

  /// Opens a DM, by handle from an account or as a private reply to a
  /// comment. Also needs the `publish` scope.
  public func startConversation(_ body: StartInboxConversationRequest) async throws
    -> InboxConversationStart
  {
    try await httpPost("/inbox/conversations", body: body, as: InboxConversationStart.self)
  }

  /// Shows or clears the typing indicator in a DM thread. Also needs the
  /// `publish` scope.
  @discardableResult
  public func setTyping(conversationID: String, accountID: String, on: Bool = true) async throws
    -> InboxTypingResult
  {
    try await httpPost(
      "/inbox/conversations/\(escapePath(conversationID))/typing",
      body: InboxTypingRequest(accountID: accountID, on: on), as: InboxTypingResult.self)
  }

  /// Passes a Messenger thread to another Meta app, or takes it back when
  /// `appID` is nil. Also needs the `publish` scope.
  @discardableResult
  public func handover(
    conversationID: String, accountID: String, appID: String? = nil, metadata: String? = nil
  ) async throws -> InboxHandover {
    try await httpPost(
      "/inbox/conversations/\(escapePath(conversationID))/handover",
      body: InboxHandoverRequest(accountID: accountID, appID: appID, metadata: metadata),
      as: InboxHandover.self)
  }

  /// Deletes a comment on the platform, or our own reply. Deleting our own
  /// reply also needs the `publish` scope.
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
