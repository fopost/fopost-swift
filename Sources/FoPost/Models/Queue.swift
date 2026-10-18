import Foundation

/// One recurring posting time: a weekday and a wall-clock time in a zone.
public struct QueueSlot: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  /// The account the slot belongs to; `nil` for a workspace-wide slot.
  public let accountID: String?
  /// 0 is Sunday, 6 is Saturday.
  public let weekday: Int?
  /// `HH:mm`.
  public let time: String?
  public let timezone: String?
  public let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, weekday, time, timezone
    case workspaceID = "workspace_id"
    case accountID = "account_id"
    case createdAt = "created_at"
  }
}

/// A queued post whose time changed when a slot was edited or removed.
public struct QueueMove: Codable, Sendable, Hashable {
  public let id: String
  public let from: Date?
  public let to: Date?
}

/// The slot after an update, plus the posts that moved with it.
public struct UpdatedQueueSlot: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  public let accountID: String?
  public let weekday: Int?
  public let time: String?
  public let timezone: String?
  public let createdAt: Date?
  public let moved: [QueueMove]?

  enum CodingKeys: String, CodingKey {
    case id, weekday, time, timezone, moved
    case workspaceID = "workspace_id"
    case accountID = "account_id"
    case createdAt = "created_at"
  }
}

/// What a slot removal did: whether it went, and the posts that moved.
public struct DeletedQueueSlot: Codable, Sendable, Hashable {
  public let deleted: Bool?
  public let moved: [QueueMove]?
}

/// The body of ``QueueResource/createSlot(_:)``.
public struct CreateQueueSlotRequest: Codable, Sendable {
  public var workspaceID: String
  public var accountID: String?
  /// 0 is Sunday, 6 is Saturday.
  public var weekday: Int
  /// `HH:mm`, 24-hour.
  public var time: String
  public var timezone: String

  public init(
    workspaceID: String, weekday: Int, time: String, timezone: String, accountID: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.accountID = accountID
    self.weekday = weekday
    self.time = time
    self.timezone = timezone
  }

  enum CodingKeys: String, CodingKey {
    case weekday, time, timezone
    case workspaceID = "workspace_id"
    case accountID = "account_id"
  }
}

/// The body of ``QueueResource/updateSlot(_:_:)``. Only the fields you set
/// are sent.
public struct UpdateQueueSlotRequest: Codable, Sendable {
  public var accountID: String?
  public var weekday: Int?
  public var time: String?
  public var timezone: String?

  public init(
    accountID: String? = nil, weekday: Int? = nil, time: String? = nil, timezone: String? = nil
  ) {
    self.accountID = accountID
    self.weekday = weekday
    self.time = time
    self.timezone = timezone
  }

  enum CodingKeys: String, CodingKey {
    case weekday, time, timezone
    case accountID = "account_id"
  }
}

struct QueueNextResponse: Decodable {
  let next: Date?
}
