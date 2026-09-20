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

  // MARK: - Meta messaging settings (Facebook Pages, Instagram)

  /// The prompts shown before the first message. A network without them answers `400`.
  public func iceBreakers(_ id: String) async throws -> MetaIceBreakers {
    try await httpGet("/accounts/\(escapePath(id))/messaging/ice-breakers", as: MetaIceBreakers.self)
  }

  /// Replaces the ice breakers, up to four.
  public func setIceBreakers(_ id: String, _ iceBreakers: [MetaIceBreaker]) async throws
    -> MetaIceBreakers
  {
    try await httpPut(
      "/accounts/\(escapePath(id))/messaging/ice-breakers",
      body: MetaIceBreakers(iceBreakers: iceBreakers), as: MetaIceBreakers.self)
  }

  /// Clears the ice breakers.
  @discardableResult
  public func deleteIceBreakers(_ id: String) async throws -> MetaIceBreakers {
    try await httpDelete(
      "/accounts/\(escapePath(id))/messaging/ice-breakers", as: MetaIceBreakers.self)
  }

  /// The always-visible Messenger menu. Facebook Pages only.
  public func persistentMenu(_ id: String) async throws -> MetaPersistentMenu {
    try await httpGet(
      "/accounts/\(escapePath(id))/messaging/persistent-menu", as: MetaPersistentMenu.self)
  }

  /// Replaces the menu, one entry per locale, up to three items each.
  public func setPersistentMenu(_ id: String, _ menu: [MetaPersistentMenuEntry]) async throws
    -> MetaPersistentMenu
  {
    try await httpPut(
      "/accounts/\(escapePath(id))/messaging/persistent-menu",
      body: MetaPersistentMenu(persistentMenu: menu), as: MetaPersistentMenu.self)
  }

  /// Clears the menu.
  @discardableResult
  public func deletePersistentMenu(_ id: String) async throws -> MetaPersistentMenu {
    try await httpDelete(
      "/accounts/\(escapePath(id))/messaging/persistent-menu", as: MetaPersistentMenu.self)
  }

  /// The text shown before a Messenger conversation starts. Facebook Pages only.
  public func greeting(_ id: String) async throws -> MetaGreeting {
    try await httpGet("/accounts/\(escapePath(id))/messaging/greeting", as: MetaGreeting.self)
  }

  /// Replaces the greeting, one entry per locale, each up to 160 characters.
  public func setGreeting(_ id: String, _ greeting: [MetaGreetingText]) async throws -> MetaGreeting
  {
    try await httpPut(
      "/accounts/\(escapePath(id))/messaging/greeting",
      body: MetaGreeting(greeting: greeting), as: MetaGreeting.self)
  }

  /// Clears the greeting.
  @discardableResult
  public func deleteGreeting(_ id: String) async throws -> MetaGreeting {
    try await httpDelete("/accounts/\(escapePath(id))/messaging/greeting", as: MetaGreeting.self)
  }

  /// What the network is delivering to the FoPost webhook for this account.
  public func webhookSubscription(_ id: String) async throws -> WebhookSubscription {
    try await httpGet(
      "/accounts/\(escapePath(id))/webhook-subscription", as: WebhookSubscription.self)
  }

  /// Subscribes to every field this account needs, lapsed or not.
  @discardableResult
  public func resubscribeWebhook(_ id: String) async throws -> WebhookSubscription {
    try await httpPost(
      "/accounts/\(escapePath(id))/webhook-subscription", as: WebhookSubscription.self)
  }
}
