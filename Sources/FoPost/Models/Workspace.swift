import Foundation

/// A connected account as listed on a workspace.
public struct WorkspaceAccountRef: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let platform: Platform?
  public let username: String?
  public let name: String?
  public let avatar: String?
}

/// One tenant. `accounts` is populated by list and get.
public struct Workspace: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let slug: String?
  public let type: WorkspaceType?
  public let logo: String?
  public let website: String?
  public let timezone: String?
  public let country: String?
  public let description: String?
  public let language: String?
  public let accounts: [WorkspaceAccountRef]?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, name, slug, type, logo, website, timezone, country, description, language, accounts
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// The body of ``WorkspacesResource/create(_:)``.
public struct CreateWorkspaceRequest: Codable, Sendable {
  public var name: String
  public var slug: String
  public var type: WorkspaceType?
  public var logo: String?
  public var website: String?
  public var timezone: String?
  public var country: String?
  public var description: String?
  public var language: String?

  public init(
    name: String, slug: String, type: WorkspaceType? = nil, logo: String? = nil,
    website: String? = nil, timezone: String? = nil, country: String? = nil,
    description: String? = nil, language: String? = nil
  ) {
    self.name = name
    self.slug = slug
    self.type = type
    self.logo = logo
    self.website = website
    self.timezone = timezone
    self.country = country
    self.description = description
    self.language = language
  }
}

/// The body of ``WorkspacesResource/update(_:_:)``. Only the fields you set
/// are sent.
public struct UpdateWorkspaceRequest: Codable, Sendable {
  public var name: String?
  public var slug: String?
  public var type: WorkspaceType?
  public var logo: String?
  public var website: String?
  public var timezone: String?
  public var country: String?
  public var description: String?
  public var language: String?
  public var requireApproval: Bool?
  public var aiAltTextEnabled: Bool?
  public var brandColor: String?

  public init(
    name: String? = nil, slug: String? = nil, type: WorkspaceType? = nil, logo: String? = nil,
    website: String? = nil, timezone: String? = nil, country: String? = nil,
    description: String? = nil, language: String? = nil, requireApproval: Bool? = nil,
    aiAltTextEnabled: Bool? = nil, brandColor: String? = nil
  ) {
    self.name = name
    self.slug = slug
    self.type = type
    self.logo = logo
    self.website = website
    self.timezone = timezone
    self.country = country
    self.description = description
    self.language = language
    self.requireApproval = requireApproval
    self.aiAltTextEnabled = aiAltTextEnabled
    self.brandColor = brandColor
  }
}

/// One account's follower and post totals inside a workspace roll-up.
public struct WorkspaceAccountAnalytics: Codable, Sendable, Hashable {
  public let accountId: String?
  public let platform: Platform?
  public let username: String?
  public let followers: Int?
  public let following: Int?
  public let totalPosts: Int?
  public let fetchedAt: Date?
}

/// The follower and post roll-up for one workspace.
public struct WorkspaceAnalytics: Codable, Sendable, Hashable {
  public struct Totals: Codable, Sendable, Hashable {
    public let followers: Int?
    public let totalPosts: Int?
  }

  public let workspaceId: String?
  public let accounts: [WorkspaceAccountAnalytics]?
  public let totals: Totals?
}
