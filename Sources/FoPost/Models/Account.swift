import Foundation

/// A connected social account.
public struct Account: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let platform: Platform?
  public let username: String?
  /// The display name override when set, else ``platformName``.
  public let name: String?
  /// The name the platform itself reports.
  public let platformName: String?
  public let avatar: String?
  public let isPrimary: Bool?
  public let active: Bool?
  public let healthStatus: AccountHealthStatus?
  public let lastHealthCheck: Date?
}

/// The workspace an account detail response names.
public struct AccountWorkspaceRef: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let slug: String?
  public let type: WorkspaceType?
}

/// One account with the workspace that owns it.
public struct AccountDetail: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  public let platform: Platform?
  public let username: String?
  /// The display name override when set, else ``platformName``.
  public let name: String?
  /// The name the platform itself reports.
  public let platformName: String?
  public let avatar: String?
  public let workspace: AccountWorkspaceRef?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, platform, username, name, avatar, workspace
    case workspaceID = "workspace_id"
    case platformName = "platform_name"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// Connects an account from credentials you already hold. Platforms that use
/// OAuth are connected in the dashboard instead.
public struct CreateAccountRequest: Codable, Sendable {
  public var workspaceId: String
  public var platform: Platform
  public var username: String
  public var name: String
  public var avatar: String?
  /// The platform's own fields, e.g. an API token.
  public var credentials: [String: JSONValue]?

  public init(
    workspaceId: String, platform: Platform, username: String, name: String,
    avatar: String? = nil, credentials: [String: JSONValue]? = nil
  ) {
    self.workspaceId = workspaceId
    self.platform = platform
    self.username = username
    self.name = name
    self.avatar = avatar
    self.credentials = credentials
  }
}

/// An account's names after ``AccountsResource/rename(_:displayName:)``.
public struct RenamedAccount: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let platformName: String?

  enum CodingKeys: String, CodingKey {
    case id, name
    case platformName = "platform_name"
  }
}

/// Where an account lives after ``AccountsResource/move(_:workspaceID:)``.
public struct MovedAccount: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?

  enum CodingKeys: String, CodingKey {
    case id
    case workspaceID = "workspace_id"
  }
}

struct UpdateAccountRequest: Encodable, Sendable {
  let displayName: String?

  enum CodingKeys: String, CodingKey {
    case displayName = "display_name"
  }

  // The API requires the key, so nil is sent as an explicit null.
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(displayName, forKey: .displayName)
  }
}

struct MoveAccountRequest: Encodable, Sendable {
  let workspaceID: String

  enum CodingKeys: String, CodingKey {
    case workspaceID = "workspace_id"
  }
}

/// The account a create call connected.
public struct CreatedAccount: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  public let platform: Platform?
  public let username: String?
  public let name: String?
  public let avatar: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, platform, username, name, avatar
    case workspaceID = "workspace_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// An account's primary flag after toggling.
public struct PrimaryResult: Codable, Sendable, Hashable {
  public let id: String
  public let isPrimary: Bool?
}

/// Whether an account's stored credentials still work.
public struct ValidationResult: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let valid: Bool?
  public let healthStatus: AccountHealthStatus?
}

/// One account's connection health.
public struct AccountHealth: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let platform: Platform?
  public let username: String?
  public let active: Bool?
  public let healthStatus: AccountHealthStatus?
  public let lastHealthCheck: Date?
}

/// The health of every account the key can reach.
public struct HealthSummary: Codable, Sendable, Hashable {
  public struct Counts: Codable, Sendable, Hashable {
    public let total: Int?
    public let healthy: Int?
    public let degraded: Int?
    public let expired: Int?
    public let revoked: Int?
    public let unknown: Int?
  }

  public let accounts: [AccountHealth]?
  public let summary: Counts?
}

/// When a refreshed credential now expires.
public struct RefreshedToken: Codable, Sendable, Hashable {
  public let message: String?
  public let expiresAt: Date?
}

/// One point in an account's history.
public struct AccountAnalyticsSnapshot: Codable, Sendable, Hashable {
  public let followers: Int?
  public let following: Int?
  public let totalPosts: Int?
  public let reach: Int?
  public let profileViews: Int?
  public let fetchedAt: Date?
}

/// An account's followers over time.
public struct AccountAnalyticsHistory: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let username: String?
  public let history: [AccountAnalyticsSnapshot]?
}

/// A one-time code that connects a Telegram chat when sent to the bot.
public struct TelegramConnectCode: Codable, Sendable, Hashable {
  public let code: String
  /// What to send in the chat: `/connect <code>`.
  public let command: String?
  /// The publishing bot, without the @.
  public let botUsername: String?
  /// Opens a private chat with the bot, code included.
  public let deepLink: String?
  /// Adds the bot to a group, code included.
  public let groupLink: String?
  public let expiresAt: Date?

  enum CodingKeys: String, CodingKey {
    case code, command
    case botUsername = "bot_username"
    case deepLink = "deep_link"
    case groupLink = "group_link"
    case expiresAt = "expires_at"
  }
}

/// Where a Telegram connect code stands.
public struct TelegramConnectStatus: Codable, Sendable, Hashable {
  public let status: TelegramConnectState?
  /// The connected account, once ``TelegramConnectState/connected``.
  public let accountID: String?
  /// Why the connection failed, when ``TelegramConnectState/failed``.
  public let reason: TelegramConnectFailure?

  enum CodingKeys: String, CodingKey {
    case status, reason
    case accountID = "account_id"
  }
}

/// The states a Telegram connect code moves through.
public struct TelegramConnectState: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let pending: Self = "pending"
  public static let connected: Self = "connected"
  public static let failed: Self = "failed"
  public static let expired: Self = "expired"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.pending, .connected, .failed, .expired]
}

/// Why a Telegram connect code failed.
public struct TelegramConnectFailure: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let cardRequired: Self = "card_required"
  public static let slotTaken: Self = "slot_taken"
  public static let workspaceUnavailable: Self = "workspace_unavailable"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.cardRequired, .slotTaken, .workspaceUnavailable]
}

/// One entry in a Telegram bot's command menu.
public struct TelegramBotCommand: Codable, Sendable, Hashable {
  /// 1-32 lowercase letters, digits or underscores, without the slash.
  public let command: String
  /// 1-256 characters.
  public let description: String

  public init(command: String, description: String) {
    self.command = command
    self.description = description
  }
}

/// The command menu a Telegram bot shows in a connected chat.
public struct TelegramBotCommands: Codable, Sendable, Hashable {
  public let commands: [TelegramBotCommand]
}

struct CreateTelegramConnectCodeRequest: Encodable, Sendable {
  let workspaceId: String?
}

/// A Slack channel the app can post to.
public struct SlackChannel: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let isPrivate: Bool?
  /// Whether the bot is in the channel.
  public let isMember: Bool?
  /// The channel this account posts to.
  public let isCurrent: Bool?

  enum CodingKeys: String, CodingKey {
    case id, name
    case isPrivate = "is_private"
    case isMember = "is_member"
    case isCurrent = "is_current"
  }
}

/// A person in the connected Slack workspace.
public struct SlackMember: Codable, Sendable, Hashable {
  /// Slack user id; pass it as the handle to start a DM.
  public let id: String
  public let name: String?
  public let realName: String?
  public let displayName: String?
  public let avatar: String?
  public let isBot: Bool?

  enum CodingKeys: String, CodingKey {
    case id, name, avatar
    case realName = "real_name"
    case displayName = "display_name"
    case isBot = "is_bot"
  }
}

/// The name and icon a Slack account posts under.
public struct SlackIdentity: Codable, Sendable, Hashable {
  /// Nil posts under the app name.
  public let username: String?
  public let iconURL: String?
  /// An emoji code such as `:rocket:`.
  public let iconEmoji: String?

  enum CodingKeys: String, CodingKey {
    case username
    case iconURL = "icon_url"
    case iconEmoji = "icon_emoji"
  }
}

/// The body of ``AccountsResource/updateSlackIdentity(_:_:)``. A field left
/// `nil` is omitted and keeps its value; `.some(nil)` sends `null` and clears
/// it. Set `iconURL` or `iconEmoji`, not both.
public struct UpdateSlackIdentityRequest: Encodable, Sendable {
  /// 1-80 characters.
  public var username: String??
  /// An http(s) image URL.
  public var iconURL: String??
  /// An emoji code such as `:rocket:`.
  public var iconEmoji: String??

  public init(username: String?? = nil, iconURL: String?? = nil, iconEmoji: String?? = nil) {
    self.username = username
    self.iconURL = iconURL
    self.iconEmoji = iconEmoji
  }

  enum CodingKeys: String, CodingKey {
    case username
    case iconURL = "icon_url"
    case iconEmoji = "icon_emoji"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let username { try container.encode(username, forKey: .username) }
    if let iconURL { try container.encode(iconURL, forKey: .iconURL) }
    if let iconEmoji { try container.encode(iconEmoji, forKey: .iconEmoji) }
  }
}

// MARK: - Discord (bot connections)
//
// A Discord account connected with a webhook has no bot to act as: every call
// below answers `409 webhook_connection` for one.

/// A Discord text channel the bot can post to.
public struct DiscordChannel: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  /// Discord's channel type: 0 text, 5 announcement, 15 forum.
  public let type: Int?
  public let parentID: String?
  public let nsfw: Bool?
  /// The channel this account posts to.
  public let isCurrent: Bool?

  enum CodingKeys: String, CodingKey {
    case id, name, type, nsfw
    case parentID = "parent_id"
    case isCurrent = "is_current"
  }
}

/// The nickname and avatar the bot wears in the server.
public struct DiscordIdentity: Codable, Sendable, Hashable {
  /// Nil wears the application's own name.
  public let username: String?
  public let avatarURL: String?

  enum CodingKeys: String, CodingKey {
    case username
    case avatarURL = "avatar_url"
  }
}

/// The body of ``AccountsResource/updateDiscordIdentity(_:_:)``. A field left
/// `nil` is omitted and keeps its value; `.some(nil)` sends `null` and clears it.
public struct UpdateDiscordIdentityRequest: Encodable, Sendable {
  /// 1-32 characters.
  public var username: String??
  /// An http(s) image URL.
  public var avatarURL: String??

  public init(username: String?? = nil, avatarURL: String?? = nil) {
    self.username = username
    self.avatarURL = avatarURL
  }

  enum CodingKeys: String, CodingKey {
    case username
    case avatarURL = "avatar_url"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let username { try container.encode(username, forKey: .username) }
    if let avatarURL { try container.encode(avatarURL, forKey: .avatarURL) }
  }
}

/// A message in the connected channel.
public struct DiscordMessage: Codable, Sendable, Hashable {
  public let id: String
  public let channelID: String?
  public let content: String?
  public let authorID: String?
  public let authorName: String?
  public let pinned: Bool?
  public let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id, content, pinned
    case channelID = "channel_id"
    case authorID = "author_id"
    case authorName = "author_name"
    case createdAt = "created_at"
  }
}

/// A message the bot put somewhere.
public struct DiscordMessageRef: Codable, Sendable, Hashable {
  public let id: String
  public let channelID: String?

  enum CodingKeys: String, CodingKey {
    case id
    case channelID = "channel_id"
  }
}

/// A thread started on a message.
public struct DiscordThread: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let parentID: String?

  enum CodingKeys: String, CodingKey {
    case id, name
    case parentID = "parent_id"
  }
}

/// An event on the server's calendar. `channelID` names a voice or stage
/// channel; otherwise `location` says where it happens.
public struct DiscordScheduledEvent: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let description: String?
  public let channelID: String?
  public let location: String?
  public let startTime: String?
  public let endTime: String?
  /// `scheduled`, `active`, `completed` or `canceled`.
  public let status: String?
  public let userCount: Int?

  enum CodingKeys: String, CodingKey {
    case id, name, description, location, status
    case channelID = "channel_id"
    case startTime = "start_time"
    case endTime = "end_time"
    case userCount = "user_count"
  }
}

/// The body of the scheduled-event create and update calls. Give `channelID`,
/// or `location` with an `endTime`. On an update, a `nil` field is left alone.
public struct DiscordEventRequest: Encodable, Sendable {
  public var name: String?
  public var description: String?
  /// RFC 3339.
  public var startTime: String?
  /// RFC 3339; required for an event at a location.
  public var endTime: String?
  public var channelID: String?
  public var location: String?
  /// Only meaningful on an update.
  public var status: String?

  public init(
    name: String? = nil, description: String? = nil, startTime: String? = nil,
    endTime: String? = nil, channelID: String? = nil, location: String? = nil,
    status: String? = nil
  ) {
    self.name = name
    self.description = description
    self.startTime = startTime
    self.endTime = endTime
    self.channelID = channelID
    self.location = location
    self.status = status
  }

  enum CodingKeys: String, CodingKey {
    case name, description, location, status
    case startTime = "start_time"
    case endTime = "end_time"
    case channelID = "channel_id"
  }
}

/// A person in the connected server.
public struct DiscordMember: Codable, Sendable, Hashable {
  /// Discord user id; pass it as the member id for a DM or a role.
  public let id: String
  public let username: String?
  public let displayName: String?
  /// Nickname in this server.
  public let nick: String?
  public let avatar: String?
  public let isBot: Bool?
  public let roles: [String]?
  public let joinedAt: String?

  enum CodingKeys: String, CodingKey {
    case id, username, nick, avatar, roles
    case displayName = "display_name"
    case isBot = "is_bot"
    case joinedAt = "joined_at"
  }
}

/// A role in the connected server.
public struct DiscordRole: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  /// An RGB integer; 0 is the default colour.
  public let color: Int?
  public let hoist: Bool?
  public let mentionable: Bool?
  /// A managed role belongs to an integration and cannot be edited.
  public let managed: Bool?
  public let position: Int?
  /// Discord's permission bitfield as a decimal string.
  public let permissions: String?
}

/// The body of the role create and update calls.
public struct DiscordRoleRequest: Encodable, Sendable {
  public var name: String?
  /// An RGB integer, e.g. 5793266.
  public var color: Int?
  /// Show members with this role separately in the member list.
  public var hoist: Bool?
  public var mentionable: Bool?
  /// Discord's permission bitfield as a decimal string.
  public var permissions: String?

  public init(
    name: String? = nil, color: Int? = nil, hoist: Bool? = nil, mentionable: Bool? = nil,
    permissions: String? = nil
  ) {
    self.name = name
    self.color = color
    self.hoist = hoist
    self.mentionable = mentionable
    self.permissions = permissions
  }
}

/// The body of the thread call.
public struct DiscordThreadRequest: Encodable, Sendable {
  public var name: String
  /// Minutes of inactivity before it archives: 60, 1440, 4320 or 10080.
  public var autoArchiveDuration: Int?

  public init(name: String, autoArchiveDuration: Int? = nil) {
    self.name = name
    self.autoArchiveDuration = autoArchiveDuration
  }

  enum CodingKeys: String, CodingKey {
    case name
    case autoArchiveDuration = "auto_archive_duration"
  }
}

/// What a Discord delete, pin or role assignment answers.
public struct DiscordAck: Codable, Sendable, Hashable {
  public let deleted: Bool?
  public let pinned: Bool?
  public let assigned: Bool?
}

struct SwitchDiscordChannelRequest: Encodable, Sendable {
  let channelID: String

  enum CodingKeys: String, CodingKey {
    case channelID = "channel_id"
  }
}

struct DiscordDirectMessageRequest: Encodable, Sendable {
  let memberID: String
  let content: String

  enum CodingKeys: String, CodingKey {
    case memberID = "member_id"
    case content
  }
}
