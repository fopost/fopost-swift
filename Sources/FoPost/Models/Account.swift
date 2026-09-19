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
