import Foundation

/// Where a broadcast stands.
public enum BroadcastStatus: String, Codable, Sendable, Hashable {
  case draft, scheduled, sending, sent, cancelled
}

/// What became of one recipient's message.
public enum RecipientStatus: String, Codable, Sendable, Hashable {
  case pending, sent, skipped, failed
}

/// Why a recipient was skipped instead of written to.
public enum SkipReason: String, Codable, Sendable, Hashable {
  /// The network's messaging window had shut, so nothing was attempted.
  /// Messenger and Instagram take a business-initiated message only within 24
  /// hours of the contact's last one.
  case windowClosed = "window_closed"
  /// This contact never wrote to the sending account.
  case noConversation = "no_conversation"
  /// The account's network takes no messages.
  case unsupportedPlatform = "unsupported_platform"
}

/// Whether a sequence fires at all.
public enum SequenceStatus: String, Codable, Sendable, Hashable {
  case active, paused
}

/// Where a contact stands on a sequence.
public enum EnrollmentStatus: String, Codable, Sendable, Hashable {
  case active, completed, stopped, failed
}

/// An operator an ``AudienceField`` clause may use.
public enum AudienceOperator: String, Codable, Sendable, Hashable {
  case `is`, isNot = "is_not", contains, isSet = "is_set", isNotSet = "is_not_set"
}

/// One custom-field clause in an audience filter.
public struct AudienceField: Codable, Sendable, Hashable {
  public let key: String
  public let op: AudienceOperator?
  public let value: String?

  public init(key: String, op: AudienceOperator? = nil, value: String? = nil) {
    self.key = key
    self.op = op
    self.value = value
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(key, forKey: .key)
    try container.encodeIfPresent(op, forKey: .op)
    try container.encodeIfPresent(value, forKey: .value)
  }
}

/// Who a broadcast or an enrollment resolves to, expressed over contacts.
///
/// Every clause narrows: a contact has to match all of them. An absent clause
/// is not sent, so an empty filter is everyone in the workspace.
public struct AudienceFilter: Codable, Sendable, Hashable {
  /// Contacts with a handle on at least one of these networks.
  public let platforms: [String]?
  public let labelIDs: [String]?
  public let source: ContactSource?
  public let fields: [AudienceField]?

  public init(
    platforms: [String]? = nil, labelIDs: [String]? = nil, source: ContactSource? = nil,
    fields: [AudienceField]? = nil
  ) {
    self.platforms = platforms
    self.labelIDs = labelIDs
    self.source = source
    self.fields = fields
  }

  enum CodingKeys: String, CodingKey {
    case platforms, source, fields
    case labelIDs = "label_ids"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(platforms, forKey: .platforms)
    try container.encodeIfPresent(labelIDs, forKey: .labelIDs)
    try container.encodeIfPresent(source, forKey: .source)
    try container.encodeIfPresent(fields, forKey: .fields)
  }
}

/// What became of a broadcast's recipients, by status.
///
/// `skipped` is usually the messaging window doing its job.
public struct BroadcastCounts: Codable, Sendable, Hashable {
  public let total: Int
  public let sent: Int
  public let skipped: Int
  public let failed: Int
  public let pending: Int
}

/// One message, sent into conversations the workspace already has.
public struct Broadcast: Codable, Sendable, Hashable {
  public let id: String
  /// Internal only; never sent to anyone.
  public let name: String
  public let text: String
  public let accountID: String?
  public let audience: AudienceFilter?
  public let status: BroadcastStatus?
  public let scheduledAt: Date?
  public let sentAt: Date?
  public let createdAt: Date?
  public let counts: BroadcastCounts?
  /// Set only on a listing that spans workspaces.
  public let workspaceID: String?

  enum CodingKeys: String, CodingKey {
    case id, name, text, audience, status, counts
    case accountID = "account_id"
    case scheduledAt = "scheduled_at"
    case sentAt = "sent_at"
    case createdAt = "created_at"
    case workspaceID = "workspace_id"
  }
}

/// One page of broadcasts: the rows plus their pagination block.
public struct BroadcastPage: Codable, Sendable, Hashable {
  public let data: [Broadcast]
  public let pagination: ContactPageMeta?

  /// True when another page follows this one.
  public var hasMore: Bool {
    guard let pagination, let page = pagination.page, let perPage = pagination.perPage,
      let total = pagination.total
    else { return false }
    return page * perPage < total
  }
}

/// One contact on one broadcast, and what became of their message.
public struct BroadcastRecipient: Codable, Sendable, Hashable {
  public let contactID: String
  public let displayName: String?
  public let status: RecipientStatus?
  /// Set when the status is `skipped`. `windowClosed` means nothing was
  /// attempted.
  public let skipReason: SkipReason?
  public let sentAt: Date?
  public let error: String?

  enum CodingKeys: String, CodingKey {
    case status, error
    case contactID = "contact_id"
    case displayName = "display_name"
    case skipReason = "skip_reason"
    case sentAt = "sent_at"
  }
}

/// One page of a broadcast's recipients.
public struct RecipientPage: Codable, Sendable, Hashable {
  public let data: [BroadcastRecipient]
  public let pagination: ContactPageMeta?
}

/// What a send started.
public struct BroadcastSent: Codable, Sendable, Hashable {
  public let id: String
  public let status: String
  /// How many contacts matched, not how many will be messaged — the messaging
  /// window decides that.
  public let recipients: Int
}

/// One message and how long after the previous step it goes out.
///
/// `delayHours` on the first step is measured from the enrollment, so 0 means
/// straight away.
public struct SequenceStep: Codable, Sendable, Hashable {
  public let delayHours: Double
  public let text: String
  public let mediaID: String?

  public init(delayHours: Double, text: String, mediaID: String? = nil) {
    self.delayHours = delayHours
    self.text = text
    self.mediaID = mediaID
  }

  enum CodingKeys: String, CodingKey {
    case text
    case delayHours = "delay_hours"
    case mediaID = "media_id"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(delayHours, forKey: .delayHours)
    try container.encode(text, forKey: .text)
    try container.encodeIfPresent(mediaID, forKey: .mediaID)
  }
}

/// Where a sequence's enrollments stand, by status.
public struct EnrollmentCounts: Codable, Sendable, Hashable {
  public let total: Int
  public let active: Int
  public let completed: Int
  public let stopped: Int
  public let failed: Int
}

/// A series of messages, each a delay after the one before.
public struct Sequence: Codable, Sendable, Hashable {
  public let id: String
  public let name: String
  public let accountID: String?
  public let steps: [SequenceStep]
  /// A paused sequence fires nothing.
  public let status: SequenceStatus?
  public let createdAt: Date?
  public let enrollments: EnrollmentCounts?
  /// Set only on a listing that spans workspaces.
  public let workspaceID: String?

  enum CodingKeys: String, CodingKey {
    case id, name, steps, status, enrollments
    case accountID = "account_id"
    case createdAt = "created_at"
    case workspaceID = "workspace_id"
  }
}

/// One page of sequences.
public struct SequencePage: Codable, Sendable, Hashable {
  public let data: [Sequence]
  public let pagination: ContactPageMeta?
}

/// One contact walking one sequence.
public struct Enrollment: Codable, Sendable, Hashable {
  public let id: String
  public let contactID: String
  public let displayName: String?
  /// Steps already sent, so also the index of the next one.
  public let step: Int
  public let nextAt: Date?
  public let status: EnrollmentStatus?
  public let lastSentAt: Date?
  /// On a skipped step, the reason it was skipped.
  public let error: String?

  enum CodingKeys: String, CodingKey {
    case id, step, status, error
    case contactID = "contact_id"
    case displayName = "display_name"
    case nextAt = "next_at"
    case lastSentAt = "last_sent_at"
  }
}

/// One page of a sequence's enrollments.
public struct EnrollmentPage: Codable, Sendable, Hashable {
  public let data: [Enrollment]
  public let pagination: ContactPageMeta?
}

/// How many contacts a call put on the sequence.
public struct Enrolled: Codable, Sendable, Hashable {
  public let id: String
  public let enrolled: Int
}

/// How many enrollments a call stopped.
public struct Unenrolled: Codable, Sendable, Hashable {
  public let id: String
  public let stopped: Int
}

/// A broadcast to create. It is written without being sent.
public struct CreateBroadcastRequest: Codable, Sendable {
  public var workspaceID: String
  /// The connected account the messages go out from.
  public var accountID: String
  public var name: String
  public var text: String
  public var mediaID: String?
  /// Absent means every contact in the workspace.
  public var audience: AudienceFilter?
  /// Set to have it go out on its own at that time.
  public var scheduledAt: Date?

  public init(
    workspaceID: String, accountID: String, name: String, text: String, mediaID: String? = nil,
    audience: AudienceFilter? = nil, scheduledAt: Date? = nil
  ) {
    self.workspaceID = workspaceID
    self.accountID = accountID
    self.name = name
    self.text = text
    self.mediaID = mediaID
    self.audience = audience
    self.scheduledAt = scheduledAt
  }

  enum CodingKeys: String, CodingKey {
    case name, text, audience
    case workspaceID = "workspace_id"
    case accountID = "account_id"
    case mediaID = "media_id"
    case scheduledAt = "scheduled_at"
  }
}

/// A partial update. Only what is set is sent, and only a draft or scheduled
/// broadcast can be edited.
public struct UpdateBroadcastRequest: Codable, Sendable {
  public var name: String?
  public var text: String?
  public var mediaID: String?
  public var audience: AudienceFilter?
  public var scheduledAt: Date?

  public init(
    name: String? = nil, text: String? = nil, mediaID: String? = nil,
    audience: AudienceFilter? = nil, scheduledAt: Date? = nil
  ) {
    self.name = name
    self.text = text
    self.mediaID = mediaID
    self.audience = audience
    self.scheduledAt = scheduledAt
  }

  enum CodingKeys: String, CodingKey {
    case name, text, audience
    case mediaID = "media_id"
    case scheduledAt = "scheduled_at"
  }
}

/// A sequence to create. Creating one enrolls nobody.
public struct CreateSequenceRequest: Codable, Sendable {
  public var workspaceID: String
  public var accountID: String
  public var name: String
  public var steps: [SequenceStep]
  public var status: SequenceStatus?

  public init(
    workspaceID: String, accountID: String, name: String, steps: [SequenceStep],
    status: SequenceStatus? = nil
  ) {
    self.workspaceID = workspaceID
    self.accountID = accountID
    self.name = name
    self.steps = steps
    self.status = status
  }

  enum CodingKeys: String, CodingKey {
    case name, steps, status
    case workspaceID = "workspace_id"
    case accountID = "account_id"
  }
}

/// A partial update. Pausing stops every enrollment from firing without ending
/// any of them.
public struct UpdateSequenceRequest: Codable, Sendable {
  public var name: String?
  public var steps: [SequenceStep]?
  public var status: SequenceStatus?

  public init(
    name: String? = nil, steps: [SequenceStep]? = nil, status: SequenceStatus? = nil
  ) {
    self.name = name
    self.steps = steps
    self.status = status
  }
}

/// Who to enroll: named contacts, or the audience they are drawn from.
public struct EnrollRequest: Codable, Sendable {
  public var contactIDs: [String]?
  public var audience: AudienceFilter?

  public init(contactIDs: [String]? = nil, audience: AudienceFilter? = nil) {
    self.contactIDs = contactIDs
    self.audience = audience
  }

  enum CodingKeys: String, CodingKey {
    case audience
    case contactIDs = "contact_ids"
  }
}

/// The contacts to take off a sequence.
public struct UnenrollRequest: Codable, Sendable {
  public var contactIDs: [String]

  public init(contactIDs: [String]) {
    self.contactIDs = contactIDs
  }

  enum CodingKeys: String, CodingKey {
    case contactIDs = "contact_ids"
  }
}
