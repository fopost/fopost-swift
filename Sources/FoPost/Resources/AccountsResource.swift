import Foundation

/// Connected social accounts.
public struct AccountsResource: Resource {
  let transport: Transport

  /// The connected accounts the key can reach, optionally narrowed to one
  /// workspace or one account group.
  public func list(workspaceID: String? = nil, groupID: String? = nil) async throws -> [Account] {
    var query = Query()
    query.add("workspaceId", workspaceID)
    query.add("group_id", groupID)
    return try await httpGet("/accounts", query: query, as: [Account].self)
  }

  /// One account.
  public func get(_ id: String) async throws -> AccountDetail {
    try await httpGet("/accounts/\(escapePath(id))", as: AccountDetail.self)
  }

  /// Connects an account with credentials.
  public func create(_ body: CreateAccountRequest) async throws -> CreatedAccount {
    try await httpPost("/accounts", body: body, as: CreatedAccount.self)
  }

  /// Sets the name FoPost shows for an account. A nil or empty name restores
  /// the platform's own name.
  public func rename(_ id: String, displayName: String?) async throws -> RenamedAccount {
    try await httpPatch(
      "/accounts/\(escapePath(id))", body: UpdateAccountRequest(displayName: displayName),
      as: RenamedAccount.self)
  }

  /// Moves an account to another workspace the caller owns. A 409 with the
  /// code `move_blocked` lists the reasons under the `blocking_tables` field.
  public func move(_ id: String, workspaceID: String) async throws -> MovedAccount {
    try await httpPost(
      "/accounts/\(escapePath(id))/move", body: MoveAccountRequest(workspaceID: workspaceID),
      as: MovedAccount.self)
  }

  /// Disconnects an account.
  public func delete(_ id: String) async throws {
    try await httpDelete("/accounts/\(escapePath(id))")
  }

  /// Toggles which account leads its platform in the workspace.
  @discardableResult
  public func setPrimary(_ id: String) async throws -> PrimaryResult {
    try await httpPost("/accounts/\(escapePath(id))/primary", as: PrimaryResult.self)
  }

  /// Checks an account's credentials against the platform.
  public func validate(_ id: String) async throws -> ValidationResult {
    try await httpPost("/accounts/\(escapePath(id))/validate", as: ValidationResult.self)
  }

  /// An account's health. Pass `refresh` to re-check it live rather than
  /// reading the last stored result.
  public func health(_ id: String, refresh: Bool = false) async throws -> AccountHealth {
    var query = Query()
    if refresh { query.add("refresh", true) }
    return try await httpGet(
      "/accounts/\(escapePath(id))/health", query: query, as: AccountHealth.self)
  }

  /// The health of every account, optionally narrowed to one workspace.
  public func healthSummary(workspaceID: String? = nil) async throws -> HealthSummary {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/accounts/health", query: query, as: HealthSummary.self)
  }

  /// Renews an account's OAuth token ahead of its expiry.
  @discardableResult
  public func refreshToken(_ id: String) async throws -> RefreshedToken {
    try await httpPost("/accounts/\(escapePath(id))/refresh-token", as: RefreshedToken.self)
  }

  /// An account's stored snapshots, newest first. A nil limit leaves the
  /// API's default of 30 in place.
  public func analytics(_ id: String, limit: Int? = nil) async throws -> AccountAnalyticsHistory {
    var query = Query()
    query.add("limit", limit)
    return try await httpGet(
      "/accounts/\(escapePath(id))/analytics", query: query, as: AccountAnalyticsHistory.self)
  }

  /// Mints a one-time code, valid for 15 minutes. Sending `/connect <code>` to
  /// the bot in a chat connects that chat. Omit `workspaceID` for a key bound
  /// to one workspace.
  public func createTelegramConnectCode(workspaceID: String? = nil) async throws
    -> TelegramConnectCode
  {
    try await httpPost(
      "/accounts/telegram/connect-code",
      body: CreateTelegramConnectCodeRequest(workspaceId: workspaceID),
      as: TelegramConnectCode.self)
  }

  /// Where a Telegram connect code stands: pending, connected, failed, or
  /// expired.
  public func telegramConnectStatus(code: String) async throws -> TelegramConnectStatus {
    var query = Query()
    query.add("code", code)
    return try await httpGet(
      "/accounts/telegram/connect-code/status", query: query, as: TelegramConnectStatus.self)
  }

  /// The command menu the bot shows in a connected Telegram chat.
  public func telegramBotCommands(_ id: String) async throws -> TelegramBotCommands {
    try await httpGet(
      "/accounts/\(escapePath(id))/telegram/commands", as: TelegramBotCommands.self)
  }

  /// Replaces the command menu for a connected Telegram chat (1-100 commands).
  public func setTelegramBotCommands(_ id: String, commands: [TelegramBotCommand]) async throws
    -> TelegramBotCommands
  {
    try await httpPut(
      "/accounts/\(escapePath(id))/telegram/commands",
      body: TelegramBotCommands(commands: commands), as: TelegramBotCommands.self)
  }

  /// Clears the command menu for a connected Telegram chat.
  @discardableResult
  public func deleteTelegramBotCommands(_ id: String) async throws -> TelegramBotCommands {
    try await httpDelete(
      "/accounts/\(escapePath(id))/telegram/commands", as: TelegramBotCommands.self)
  }

  /// Subreddits a Reddit account is subscribed to, busiest first, plus its own
  /// profile page. ``RedditSubreddit/canPost`` is false where the account may
  /// read but not submit, and ``RedditSubreddit/isDefault`` marks the subreddit
  /// posts go to when a post names none. A 409 `reconnect_required` means the
  /// account has to be reconnected first; the same applies to the other Reddit
  /// calls.
  public func redditSubreddits(_ id: String) async throws -> [RedditSubreddit] {
    try await httpGet("/accounts/\(escapePath(id))/reddit/subreddits", as: [RedditSubreddit].self)
  }

  /// The rules a subreddit publishes, in its own order. `subreddit` carries no
  /// `r/` prefix.
  public func redditSubredditRules(_ id: String, subreddit: String) async throws
    -> [RedditSubredditRule]
  {
    let wrapper = try await httpGet(
      "/accounts/\(escapePath(id))/reddit/subreddits/\(escapePath(subreddit))/rules",
      as: RedditSubredditRules.self)
    return wrapper.rules ?? []
  }

  /// Post flairs one subreddit offers. A flair id is valid only in the
  /// subreddit it came from: pass it as `flair_id` in the post's Reddit
  /// platform settings, and preflight rejects an id from anywhere else.
  public func redditFlairs(_ id: String, subreddit: String) async throws -> [RedditFlair] {
    let wrapper = try await httpGet(
      "/accounts/\(escapePath(id))/reddit/flairs",
      query: Query(["subreddit": subreddit]),
      as: RedditFlairs.self)
    return wrapper.flairs ?? []
  }

  /// Sets where a Reddit account's posts go when a post names no subreddit.
  /// Passing nil falls back to the account's own profile page, which always
  /// takes a post. Returns the subreddit now in effect.
  public func setRedditDefaultSubreddit(_ id: String, subreddit: String?) async throws -> String? {
    let result = try await httpPut(
      "/accounts/\(escapePath(id))/reddit/default-subreddit",
      body: RedditDefaultSubredditRequest(subreddit: subreddit),
      as: RedditDefaultSubreddit.self)
    return result.subreddit
  }

  /// Channels the Slack app can post to: every public channel, and private
  /// ones the app was invited to. A 409 `webhook_connection` means the account
  /// posts through a webhook.
  public func slackChannels(_ id: String) async throws -> [SlackChannel] {
    try await httpGet("/accounts/\(escapePath(id))/slack/channels", as: [SlackChannel].self)
  }

  /// People in the connected Slack workspace, for addressing a DM.
  public func slackMembers(_ id: String) async throws -> [SlackMember] {
    try await httpGet("/accounts/\(escapePath(id))/slack/members", as: [SlackMember].self)
  }

  /// The name and icon a Slack account posts under.
  public func slackIdentity(_ id: String) async throws -> SlackIdentity {
    try await httpGet("/accounts/\(escapePath(id))/slack/identity", as: SlackIdentity.self)
  }

  /// Sets the name and icon a Slack account posts under. Setting one icon
  /// clears the other.
  public func updateSlackIdentity(_ id: String, _ body: UpdateSlackIdentityRequest) async throws
    -> SlackIdentity
  {
    try await httpPatch(
      "/accounts/\(escapePath(id))/slack/identity", body: body, as: SlackIdentity.self)
  }
}
