import Foundation

/// One attachment to check as part of a post, by URL.
public struct ValidateMediaItem: Codable, Sendable, Hashable {
  public var url: String
  public var mimeType: String
  /// Size in bytes, when known.
  public var size: Int?

  public init(url: String, mimeType: String, size: Int? = nil) {
    self.url = url
    self.mimeType = mimeType
    self.size = size
  }

  enum CodingKeys: String, CodingKey {
    case url, size
    case mimeType = "mime_type"
  }
}

/// A post to check against one or more platforms without creating it.
public struct ValidatePostRequest: Codable, Sendable, Hashable {
  public var content: String?
  public var media: [ValidateMediaItem]?
  public var platforms: [Platform]

  public init(content: String? = nil, media: [ValidateMediaItem]? = nil, platforms: [Platform]) {
    self.content = content
    self.media = media
    self.platforms = platforms
  }
}

/// One platform's readiness. `issues` block publishing; `signals` are advisory.
public struct ValidatePostPlatform: Codable, Sendable, Hashable {
  public let platform: String?
  public let ready: Bool?
  public let issues: [String]?
  public let score: Double?
  public let signals: [ContentSignal]?
}

/// Per-platform blockers and advisory content signals for a post.
public struct ValidatePostResult: Codable, Sendable, Hashable {
  public let ready: Bool?
  public let platforms: [ValidatePostPlatform]?
}

/// Text to measure against one or more platforms' limits.
public struct ValidateLengthRequest: Codable, Sendable, Hashable {
  public var text: String
  public var platforms: [Platform]

  public init(text: String, platforms: [Platform]) {
    self.text = text
    self.platforms = platforms
  }
}

/// How one platform counts the text and whether it fits.
public struct ValidateLengthPlatform: Codable, Sendable, Hashable {
  public let platform: String?
  public let length: Int?
  /// `nil` when the platform has no text limit.
  public let limit: Int?
  /// `chars` or `bytes`.
  public let unit: String?
  public let ok: Bool?
  public let signals: [ContentSignal]?
}

/// Per-platform length checks for a piece of text.
public struct ValidateLengthResult: Codable, Sendable, Hashable {
  public let ok: Bool?
  public let platforms: [ValidateLengthPlatform]?
}

/// A public file URL to check.
public struct ValidateMediaRequest: Codable, Sendable, Hashable {
  public var url: String

  public init(url: String) {
    self.url = url
  }
}

/// What the API found at a media URL. Answers 200 even when a check fails.
public struct ValidateMediaResult: Codable, Sendable, Hashable {
  public let ok: Bool?
  public let issues: [String]?
  public let name: String?
  /// Bytes fetched.
  public let size: Int?
  /// Present only when `ok`.
  public let mimeType: String?
  /// `image`, `video`, `audio`, or `document`. Present only when `ok`.
  public let type: String?

  enum CodingKeys: String, CodingKey {
    case ok, issues, name, size, type
    case mimeType = "mime_type"
  }
}
