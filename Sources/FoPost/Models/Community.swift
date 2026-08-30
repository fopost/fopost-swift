import Foundation

/// An X community linked to an account.
public struct Community: Codable, Sendable, Hashable {
  /// The local row id, used to remove the link.
  public let id: Int
  public let accountId: String?
  /// X's own id for the community.
  public let communityId: String?
  public let name: String?
  public let memberCount: Int?
  public let description: String?
  public let imageUrl: String?
  public let lastSyncedAt: Date?
  public let createdAt: Date?
}

/// A community as X's search returns it, before it is linked to the account.
public struct CommunitySearchResult: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let description: String?
  public let memberCount: Int?

  enum CodingKeys: String, CodingKey {
    case id, name, description
    case memberCount = "member_count"
  }
}
