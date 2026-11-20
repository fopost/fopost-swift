import Foundation

/// Upright or italic.
public struct FontStyle: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let normal: Self = "normal"
  public static let italic: Self = "italic"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.normal, .italic]
}

/// One file of a library font: a subset at one weight and style.
public struct LibraryFontFile: Codable, Sendable, Hashable {
  public let path: String?
  public let subset: String?
  public let weight: Int?
  public let style: FontStyle?
  public let unicodeRange: String?

  enum CodingKeys: String, CodingKey {
    case path, subset, weight, style
    case unicodeRange = "unicode_range"
  }
}

/// A font from the built-in library every workspace can use.
public struct LibraryFont: Codable, Sendable, Hashable {
  public let slug: String
  public let family: String
  public let category: String?
  public let scripts: [String]?
  public let weights: [Int]?
  public let files: [LibraryFontFile]?
}

/// A font a workspace uploaded.
public struct UploadedFont: Codable, Sendable, Hashable {
  public let id: String
  public let family: String
  public let style: FontStyle?
  public let weight: Int?
  /// `woff2`, `woff`, `ttf` or `otf`.
  public let format: String?
  /// Needs the same API key to fetch.
  public let fileURL: String?
  public let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, family, style, weight, format
    case fileURL = "file_url"
    case createdAt = "created_at"
  }
}

/// What ``FontsResource/list(workspaceID:)`` answers.
public struct FontList: Codable, Sendable, Hashable {
  public let library: [LibraryFont]
  /// Empty unless a workspace was named.
  public let uploaded: [UploadedFont]
}
