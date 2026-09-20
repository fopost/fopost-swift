import Foundation

/// What first created a contact row.
public enum ContactSource: String, Codable, Sendable, Hashable {
  case inbox, radar, `import`
}

/// What a custom field accepts.
public enum ContactFieldType: String, Codable, Sendable, Hashable {
  case text, number, date, select, boolean
}

/// How a per-conversation report is ordered.
public enum ConversationSort: String, Codable, Sendable, Hashable {
  case volume, slowest, recent
}

/// One handle on one network.
///
/// `handle` is lower-cased with no leading `@`. `externalID` is the platform's
/// own id for this person when the network gave us one, and it is what a merge
/// prefers: a handle can be changed, an id cannot.
public struct ContactChannel: Codable, Sendable, Hashable {
  public let platform: String
  public let handle: String
  public let externalID: String?

  public init(platform: String, handle: String, externalID: String? = nil) {
    self.platform = platform
    self.handle = handle
    self.externalID = externalID
  }

  enum CodingKeys: String, CodingKey {
    case platform, handle
    case externalID = "externalId"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(platform, forKey: .platform)
    try container.encode(handle, forKey: .handle)
    // An absent id must not travel as null: that would claim we know one.
    try container.encodeIfPresent(externalID, forKey: .externalID)
  }
}

/// A workspace label put on a contact.
public struct ContactLabel: Codable, Sendable, Hashable {
  public let id: String
  public let name: String
  public let color: String?
}

/// One person, however many handles they write from.
public struct Contact: Codable, Sendable, Hashable {
  public let id: String
  public let displayName: String?
  public let channels: [ContactChannel]
  /// What first created the row.
  public let source: ContactSource?
  public let note: String?
  public let firstSeenAt: Date?
  public let lastSeenAt: Date?
  /// Custom field values, keyed by field key.
  public let fields: [String: String]
  public let labels: [ContactLabel]
  /// Set only on a listing that spans workspaces.
  public let workspaceID: String?

  enum CodingKeys: String, CodingKey {
    case id, channels, source, note, fields, labels
    case displayName = "display_name"
    case firstSeenAt = "first_seen_at"
    case lastSeenAt = "last_seen_at"
    case workspaceID = "workspace_id"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
    channels = try container.decodeIfPresent([ContactChannel].self, forKey: .channels) ?? []
    source = try container.decodeIfPresent(ContactSource.self, forKey: .source)
    note = try container.decodeIfPresent(String.self, forKey: .note)
    firstSeenAt = try container.decodeIfPresent(Date.self, forKey: .firstSeenAt)
    lastSeenAt = try container.decodeIfPresent(Date.self, forKey: .lastSeenAt)
    fields = try container.decodeIfPresent([String: String].self, forKey: .fields) ?? [:]
    labels = try container.decodeIfPresent([ContactLabel].self, forKey: .labels) ?? []
    workspaceID = try container.decodeIfPresent(String.self, forKey: .workspaceID)
  }
}

/// The pagination block a contacts listing returns beside its rows.
public struct ContactPageMeta: Codable, Sendable, Hashable {
  public let page: Int?
  public let perPage: Int?
  public let total: Int?

  enum CodingKeys: String, CodingKey {
    case page, total
    case perPage = "per_page"
  }
}

/// One page of contacts: the rows plus their pagination block.
public struct ContactPage: Codable, Sendable, Hashable {
  public let data: [Contact]
  public let pagination: ContactPageMeta?

  /// True when another page follows this one.
  public var hasMore: Bool {
    guard let pagination, let page = pagination.page, let perPage = pagination.perPage,
      let total = pagination.total
    else { return false }
    return page * perPage < total
  }
}

/// One thread a contact appears in.
public struct ContactConversation: Codable, Sendable, Hashable {
  /// How the inbox groups it: the DM thread id, else the post the comments hang
  /// off, else the handle.
  public let key: String
  public let accountID: String
  public let accountUsername: String?
  public let platform: String
  public let messages: Int
  public let received: Int
  public let sent: Int
  public let lastMessageAt: Date?
  /// An inbox item id, readable through the inbox endpoints.
  public let lastItemID: String?

  enum CodingKeys: String, CodingKey {
    case key, platform, messages, received, sent
    case accountID = "account_id"
    case accountUsername = "account_username"
    case lastMessageAt = "last_message_at"
    case lastItemID = "last_item_id"
  }
}

/// One CSV row the import could not read.
public struct ContactImportSkip: Codable, Sendable, Hashable {
  public let row: Int
  public let reason: String
}

/// What a CSV import did.
public struct ContactImportResult: Codable, Sendable, Hashable {
  public let created: Int
  /// Rows that folded into a contact already on file.
  public let merged: Int
  public let skipped: [ContactImportSkip]
  /// Columns that matched neither a reserved field nor a custom field. They are
  /// reported, never stored.
  public let unknownColumns: [String]

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    created = try container.decodeIfPresent(Int.self, forKey: .created) ?? 0
    merged = try container.decodeIfPresent(Int.self, forKey: .merged) ?? 0
    skipped = try container.decodeIfPresent([ContactImportSkip].self, forKey: .skipped) ?? []
    unknownColumns = try container.decodeIfPresent([String].self, forKey: .unknownColumns) ?? []
  }
}

/// A column the workspace invented. `key` is the machine name and the CSV column
/// header, fixed once created; the name and options are not.
public struct ContactField: Codable, Sendable, Hashable {
  public let id: String
  public let key: String
  public let name: String
  public let type: ContactFieldType?
  /// Allowed values when `type` is `select`.
  public let options: [String]
  public let position: Int

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    key = try container.decode(String.self, forKey: .key)
    name = try container.decode(String.self, forKey: .name)
    type = try container.decodeIfPresent(ContactFieldType.self, forKey: .type)
    options = try container.decodeIfPresent([String].self, forKey: .options) ?? []
    position = try container.decodeIfPresent(Int.self, forKey: .position) ?? 0
  }
}

/// How one thread performed over the period.
public struct ConversationAnalyticsRow: Codable, Sendable, Hashable {
  /// An opaque, stable handle for the thread, not the id or handle the inbox
  /// groups on: that would be a person, and this reads under the `analytics`
  /// scope. Use it to line the same thread up between two calls.
  public let key: String
  public let accountID: String
  public let platform: String
  public let received: Int
  public let sent: Int
  public let answered: Int
  public let open: Int
  /// Nil when the thread was never answered.
  public let medianResponseMinutes: Double?
  public let firstMessageAt: Date?
  public let lastMessageAt: Date?

  enum CodingKeys: String, CodingKey {
    case key, platform, received, sent, answered, open
    case accountID = "accountId"
    case medianResponseMinutes, firstMessageAt, lastMessageAt
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    key = try container.decode(String.self, forKey: .key)
    accountID = try container.decode(String.self, forKey: .accountID)
    platform = try container.decode(String.self, forKey: .platform)
    received = try container.decodeIfPresent(Int.self, forKey: .received) ?? 0
    sent = try container.decodeIfPresent(Int.self, forKey: .sent) ?? 0
    answered = try container.decodeIfPresent(Int.self, forKey: .answered) ?? 0
    open = try container.decodeIfPresent(Int.self, forKey: .open) ?? 0
    medianResponseMinutes = try container.decodeIfPresent(
      Double.self, forKey: .medianResponseMinutes)
    firstMessageAt = try container.decodeIfPresent(Date.self, forKey: .firstMessageAt)
    lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
  }
}

/// Inbox analytics broken out per thread.
public struct ConversationAnalytics: Codable, Sendable, Hashable {
  public let conversations: [ConversationAnalyticsRow]
  public let total: Int
  public let page: Int
  public let perPage: Int

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    conversations =
      try container.decodeIfPresent([ConversationAnalyticsRow].self, forKey: .conversations) ?? []
    total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
    page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
    perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 25
  }
}

// ─── Requests ────────────────────────────────────────────────────────

/// The body of ``ContactsResource/create(_:)``.
public struct CreateContactRequest: Codable, Sendable {
  public var workspaceID: String
  /// At least one. The first decides which contact this folds into.
  public var channels: [ContactChannel]
  public var displayName: String?
  public var note: String?
  public var fields: [String: String]?

  public init(
    workspaceID: String, channels: [ContactChannel], displayName: String? = nil,
    note: String? = nil, fields: [String: String]? = nil
  ) {
    self.workspaceID = workspaceID
    self.channels = channels
    self.displayName = displayName
    self.note = note
    self.fields = fields
  }

  enum CodingKeys: String, CodingKey {
    case channels, note, fields
    case workspaceID = "workspace_id"
    case displayName = "display_name"
  }
}

/// The body of ``ContactsResource/update(_:_:)``. Only what is set is sent; a
/// custom field whose value is nil is cleared.
public struct UpdateContactRequest: Codable, Sendable {
  public var displayName: String??
  public var channels: [ContactChannel]?
  public var note: String??
  /// A value of nil clears that field.
  public var fields: [String: String?]?

  public init(
    displayName: String?? = nil, channels: [ContactChannel]? = nil, note: String?? = nil,
    fields: [String: String?]? = nil
  ) {
    self.displayName = displayName
    self.channels = channels
    self.note = note
    self.fields = fields
  }

  enum CodingKeys: String, CodingKey {
    case channels, note, fields
    case displayName = "display_name"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    // The double optional splits "not sent" from "sent as null": the outer nil
    // leaves the key out, the inner nil clears the value.
    if let displayName { try container.encode(displayName, forKey: .displayName) }
    if let channels { try container.encode(channels, forKey: .channels) }
    if let note { try container.encode(note, forKey: .note) }
    if let fields { try container.encode(fields, forKey: .fields) }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    displayName = try container.decodeIfPresent(String?.self, forKey: .displayName)
    channels = try container.decodeIfPresent([ContactChannel].self, forKey: .channels)
    note = try container.decodeIfPresent(String?.self, forKey: .note)
    fields = try container.decodeIfPresent([String: String?].self, forKey: .fields)
  }
}

/// The body of ``ContactsResource/createField(_:)``.
///
/// `workspaceID` rides on the query string rather than in the body, because
/// that is where the handler reads it; it is carried here so one value names
/// both.
public struct CreateContactFieldRequest: Encodable, Sendable {
  public var workspaceID: String
  /// Lower-case letters, digits and underscores, starting with a letter.
  public var key: String
  public var name: String
  public var type: ContactFieldType
  /// Required when `type` is `.select`.
  public var options: [String]

  public init(
    workspaceID: String, key: String, name: String, type: ContactFieldType = .text,
    options: [String] = []
  ) {
    self.workspaceID = workspaceID
    self.key = key
    self.name = name
    self.type = type
    self.options = options
  }

  enum CodingKeys: String, CodingKey {
    case key, name, type, options
  }
}

/// The body of ``ContactsResource/updateField(_:_:)``. The key and the type are
/// fixed once created; the name and options are not.
public struct UpdateContactFieldRequest: Codable, Sendable {
  public var name: String?
  public var options: [String]?
  public var position: Int?

  public init(name: String? = nil, options: [String]? = nil, position: Int? = nil) {
    self.name = name
    self.options = options
    self.position = position
  }
}
