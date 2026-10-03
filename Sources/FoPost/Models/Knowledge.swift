import Foundation

/// Where a knowledge source's text comes from.
public enum KnowledgeSourceKind: String, Codable, Sendable, Hashable {
  /// Question and answer pairs, one pair per paragraph.
  case faq
  /// A free-form note.
  case text
  /// A page on your own site, re-read whenever you sync it.
  case url
  /// A plain-text or CSV item from the media library.
  case file
}

/// Where a knowledge source is in its ingest cycle.
public enum KnowledgeSourceStatus: String, Codable, Sendable, Hashable {
  case pending
  case syncing
  /// The only status that is searched.
  case ready
  case failed
}

/// One thing the workspace has told FoPost about itself: an FAQ, a note, a page
/// on its own site, or a plain-text/CSV file from the media library.
public struct KnowledgeSource: Codable, Sendable, Hashable {
  public let id: String
  public let kind: KnowledgeSourceKind
  public let title: String
  public let status: KnowledgeSourceStatus
  /// Why the last sync failed, in plain words.
  public let statusMessage: String?
  /// Set for `url` sources.
  public let url: String?
  /// Set for `file` sources: the media library item read.
  public let mediaID: String?
  /// `nil` means the source serves the whole workspace.
  public let brandVoiceID: String?
  /// Searchable passages the last sync produced.
  public let chunkCount: Int?
  /// The typed text, for `faq` and `text` sources only.
  public let content: String?
  public let lastSyncedAt: Date?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, kind, title, status, url, content
    case statusMessage, chunkCount, lastSyncedAt, createdAt, updatedAt
    case mediaID = "mediaId"
    case brandVoiceID = "brandVoiceId"
  }
}

/// One retrieved passage, with the source it came from so a reply can cite it.
public struct KnowledgeMatch: Codable, Sendable, Hashable {
  public let sourceID: String
  public let sourceTitle: String
  public let sourceKind: KnowledgeSourceKind
  public let sourceURL: String?
  public let text: String
  /// Similarity to the question, 0-1.
  public let score: Double

  enum CodingKeys: String, CodingKey {
    case sourceTitle, sourceKind, text, score
    case sourceID = "sourceId"
    case sourceURL = "sourceUrl"
  }
}

/// What a sync answers: the source, and that it is queued.
public struct KnowledgeSyncResult: Codable, Sendable, Hashable {
  public let id: String
  public let status: KnowledgeSourceStatus
}

/// The body of ``KnowledgeResource/create(_:)``.
///
/// An `faq` or `text` source needs `content`, a `url` source needs `url`, and a
/// `file` source needs `mediaID` pointing at a plain-text or CSV item in the
/// same workspace.
public struct CreateKnowledgeSourceRequest: Codable, Sendable {
  public var kind: KnowledgeSourceKind
  public var title: String
  public var content: String?
  public var url: String?
  public var mediaID: String?
  public var brandVoiceID: String?
  public var workspaceID: String?

  public init(
    kind: KnowledgeSourceKind,
    title: String,
    content: String? = nil,
    url: String? = nil,
    mediaID: String? = nil,
    brandVoiceID: String? = nil,
    workspaceID: String? = nil
  ) {
    self.kind = kind
    self.title = title
    self.content = content
    self.url = url
    self.mediaID = mediaID
    self.brandVoiceID = brandVoiceID
    self.workspaceID = workspaceID
  }

  enum CodingKeys: String, CodingKey {
    case kind, title, content, url
    case mediaID = "media_id"
    case brandVoiceID = "brand_voice_id"
    case workspaceID = "workspace_id"
  }
}

/// The body of ``KnowledgeResource/update(_:_:)``. Only the fields you set are
/// sent, so it stays a partial update. Changing the content or the URL returns
/// the source to `pending` and re-indexes it.
public struct UpdateKnowledgeSourceRequest: Codable, Sendable {
  public var title: String?
  public var content: String?
  public var url: String?
  public var brandVoiceID: String?

  public init(
    title: String? = nil,
    content: String? = nil,
    url: String? = nil,
    brandVoiceID: String? = nil
  ) {
    self.title = title
    self.content = content
    self.url = url
    self.brandVoiceID = brandVoiceID
  }

  enum CodingKeys: String, CodingKey {
    case title, content, url
    case brandVoiceID = "brand_voice_id"
  }
}
