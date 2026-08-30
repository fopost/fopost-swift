import Foundation

/// The workspace a label belongs to.
public struct LabelWorkspaceRef: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let slug: String?
  public let type: WorkspaceType?
  public let logo: String?
  public let timezone: String?
  public let language: String?
}

/// One campaign tag.
public struct Label: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let color: String?
  public let workspace: LabelWorkspaceRef?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, name, color, workspace
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// The body of ``LabelsResource/create(_:)``. `color` is a hex value, e.g.
/// `#2563eb`.
public struct CreateLabelRequest: Codable, Sendable {
  public var workspaceID: String
  public var name: String
  public var color: String

  public init(workspaceID: String, name: String, color: String) {
    self.workspaceID = workspaceID
    self.name = name
    self.color = color
  }

  enum CodingKeys: String, CodingKey {
    case name, color
    case workspaceID = "workspace_id"
  }
}

/// The body of ``LabelsResource/update(_:_:)``. Both fields are required.
public struct UpdateLabelRequest: Codable, Sendable {
  public var name: String
  public var color: String

  public init(name: String, color: String) {
    self.name = name
    self.color = color
  }
}
