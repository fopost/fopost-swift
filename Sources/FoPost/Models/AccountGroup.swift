import Foundation

/// A named set of connected accounts in one workspace.
public struct AccountGroup: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let accountIDs: [String]?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, name
    case accountIDs = "account_ids"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// The body of ``AccountGroupsResource/create(_:)``.
public struct CreateAccountGroupRequest: Codable, Sendable {
  public var workspaceID: String
  public var name: String
  public var accountIDs: [String]?

  public init(workspaceID: String, name: String, accountIDs: [String]? = nil) {
    self.workspaceID = workspaceID
    self.name = name
    self.accountIDs = accountIDs
  }

  enum CodingKeys: String, CodingKey {
    case name
    case workspaceID = "workspace_id"
    case accountIDs = "account_ids"
  }
}

/// The body of ``AccountGroupsResource/update(_:_:)``.
public struct UpdateAccountGroupRequest: Codable, Sendable {
  public var name: String

  public init(name: String) {
    self.name = name
  }
}
