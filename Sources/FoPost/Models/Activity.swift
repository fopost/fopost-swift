import Foundation

/// What kind of thing happened. ``security`` is the audit log: its rows are
/// append-only and, unlike the rest, never expire.
public enum ActivityKind: String, Codable, Sendable, Hashable {
  case publish
  case connection
  case webhook
  case inbox
  case automation
  case billing
  case security
}

/// Who did it. `name` is absent for a system event.
public struct ActivityActor: Codable, Sendable, Hashable {
  public let type: String
  public let name: String?
}

/// One thing that happened in a workspace.
public struct ActivityEvent: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceID: String?
  /// A string rather than ``ActivityKind`` so a kind added server-side still decodes.
  public let kind: String
  public let refType: String?
  public let refID: String?
  public let summary: String
  public let actor: ActivityActor
  public let time: Date?

  enum CodingKeys: String, CodingKey {
    case id, kind, summary, actor, time
    case workspaceID = "workspace_id"
    case refType = "ref_type"
    case refID = "ref_id"
  }
}

/// The cursor for the next page; `nil` at the end of the list.
public struct ActivityMeta: Codable, Sendable, Hashable {
  public let nextCursor: String?

  enum CodingKeys: String, CodingKey {
    case nextCursor = "next_cursor"
  }
}

/// One page of activity, newest first.
public struct ActivityPage: Codable, Sendable, Hashable {
  public let data: [ActivityEvent]
  public let meta: ActivityMeta
}

/// How to narrow the log. Leave `workspaceID` unset to read every workspace the
/// key can reach.
public struct ActivityListParams: Sendable {
  public var workspaceID: String?
  public var kind: ActivityKind?
  /// Only events at or after this time.
  public var from: Date?
  /// Only events at or before this time.
  public var to: Date?
  /// The `meta.nextCursor` of the previous page.
  public var cursor: String?
  public var limit: Int?

  public init(
    workspaceID: String? = nil, kind: ActivityKind? = nil, from: Date? = nil, to: Date? = nil,
    cursor: String? = nil, limit: Int? = nil
  ) {
    self.workspaceID = workspaceID
    self.kind = kind
    self.from = from
    self.to = to
    self.cursor = cursor
    self.limit = limit
  }
}
