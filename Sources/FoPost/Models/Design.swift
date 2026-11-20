import Foundation

/// A design document: its pages and layers, passed through as plain JSON.
public typealias DesignDocument = [String: JSONValue]

/// The shapes a design comes in.
public struct DesignKind: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let story: Self = "story"
  public static let post: Self = "post"
  public static let carousel: Self = "carousel"
  public static let thumbnail: Self = "thumbnail"
  public static let card: Self = "card"
  public static let collage: Self = "collage"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.story, .post, .carousel, .thumbnail, .card, .collage]
}

/// The file types a design exports to.
public struct DesignExportFormat: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let png: Self = "png"
  public static let jpg: Self = "jpg"
  public static let pdf: Self = "pdf"
  public static let mp4: Self = "mp4"
  public static let gif: Self = "gif"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.png, .jpg, .pdf, .mp4, .gif]
}

/// How ``DesignsResource/fromPost(_:)`` lays a post's text out.
public struct DesignTextStyle: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let quote: Self = "quote"
  public static let post: Self = "post"
  public static let plain: Self = "plain"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.quote, .post, .plain]
}

/// One design. Lists leave `document` out.
public struct Design: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let kind: DesignKind?
  public let width: Int?
  public let height: Int?
  public let document: DesignDocument?
  public let thumbnailMediaID: String?
  public let thumbnailURL: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, name, kind, width, height, document
    case thumbnailMediaID = "thumbnail_media_id"
    case thumbnailURL = "thumbnail_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// One saved version of a design. `document` is there only when asked for.
public struct DesignVersion: Codable, Sendable, Hashable {
  public let id: String
  public let version: Int?
  public let document: DesignDocument?
  public let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, version, document
    case createdAt = "created_at"
  }
}

/// What an update or a restore answers: the design, plus the version it saved.
public struct DesignSaveResult: Codable, Sendable, Hashable {
  public let design: Design
  /// Nil when no version was saved.
  public let version: DesignVersion?

  enum CodingKeys: String, CodingKey {
    case design = "data"
    case version
  }
}

/// What a delete answers.
public struct DesignDeleted: Codable, Sendable, Hashable {
  public let id: String
  public let deleted: Bool
}

/// One exported file, stored in the media library.
public struct DesignExportFile: Codable, Sendable, Hashable {
  public let mediaID: String
  public let pageIndex: Int?
  public let mimeType: String?
  public let previewURL: String?

  enum CodingKeys: String, CodingKey {
    case mediaID = "media_id"
    case pageIndex = "page_index"
    case mimeType = "mime_type"
    case previewURL = "preview_url"
  }
}

/// What an export answers: one file per exported page, or one for a PDF or video.
public struct DesignExport: Codable, Sendable, Hashable {
  public let format: DesignExportFormat
  public let files: [DesignExportFile]
}

/// A post that uses a design's exported media.
public struct DesignPost: Codable, Sendable, Hashable {
  public let id: String
  public let status: PostStatus?
  public let title: String?
  /// The first block's text, cut at 280 characters.
  public let text: String?
  public let scheduleAt: Date?
  public let publishedAt: Date?
  public let platforms: [String]?
  public let engagement: Int?
  public let views: Int?

  enum CodingKeys: String, CodingKey {
    case id, status, title, text, platforms, engagement, views
    case scheduleAt = "schedule_at"
    case publishedAt = "published_at"
  }
}

/// A heading and its body, one slide's worth.
public struct SlidePoint: Codable, Sendable, Hashable {
  public let heading: String
  public let body: String
}

/// The cover slide of a slides outline.
public struct SlidesCover: Codable, Sendable, Hashable {
  public let title: String
  public let subtitle: String
}

/// The fonts a brand uses.
public struct SlidesBrandFonts: Codable, Sendable, Hashable {
  public let heading: String?
  public let body: String?
}

/// The brand styling applied to a slides outline.
public struct SlidesBrand: Codable, Sendable, Hashable {
  public let colors: [String]?
  public let fonts: SlidesBrandFonts?
  public let logoMediaID: String?

  enum CodingKeys: String, CodingKey {
    case colors, fonts
    case logoMediaID = "logo_media_id"
  }
}

/// A carousel outline written from long text: a cover, the slides, and a closing call to action.
public struct SlidesOutline: Codable, Sendable, Hashable {
  public let cover: SlidesCover
  public let slides: [SlidePoint]
  public let cta: SlidePoint
  public let brand: SlidesBrand?
}

/// Filters for ``DesignsResource/list(_:)``.
public struct DesignListParams: Sendable, Hashable {
  public var workspaceID: String
  public var kind: DesignKind?
  public var limit: Int?
  public var offset: Int?

  public init(workspaceID: String, kind: DesignKind? = nil, limit: Int? = nil, offset: Int? = nil)
  {
    self.workspaceID = workspaceID
    self.kind = kind
    self.limit = limit
    self.offset = offset
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("kind", kind?.rawValue)
    query.add("limit", limit)
    query.add("offset", offset)
    return query
  }
}

/// The body of ``DesignsResource/create(_:)``.
public struct CreateDesignRequest: Codable, Sendable {
  public var workspaceID: String
  public var kind: DesignKind
  /// Defaults to `Untitled Design`.
  public var name: String?
  /// Left out, the design starts from a blank page in its kind's size.
  public var document: DesignDocument?
  /// Styles the design with this brand's kit instead of the workspace default.
  public var brandVoiceID: String?

  public init(
    workspaceID: String, kind: DesignKind, name: String? = nil, document: DesignDocument? = nil,
    brandVoiceID: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.kind = kind
    self.name = name
    self.document = document
    self.brandVoiceID = brandVoiceID
  }

  enum CodingKeys: String, CodingKey {
    case kind, name, document
    case workspaceID = "workspace_id"
    case brandVoiceID = "brand_voice_id"
  }
}

/// The body of ``DesignsResource/update(_:_:)``. Only the fields you set are sent.
public struct UpdateDesignRequest: Codable, Sendable {
  public var name: String?
  public var kind: DesignKind?
  public var document: DesignDocument?
  /// Saves the new document as a version too.
  public var createVersion: Bool?

  public init(
    name: String? = nil, kind: DesignKind? = nil, document: DesignDocument? = nil,
    createVersion: Bool? = nil
  ) {
    self.name = name
    self.kind = kind
    self.document = document
    self.createVersion = createVersion
  }

  enum CodingKeys: String, CodingKey {
    case name, kind, document
    case createVersion = "create_version"
  }
}

/// The body of ``DesignsResource/export(_:_:)``.
public struct ExportDesignRequest: Codable, Sendable {
  public var format: DesignExportFormat
  /// Zero-based pages to export; every page when nil.
  public var pageIndexes: [Int]?
  /// 5, 10 or 15 seconds, for `mp4` and `gif`.
  public var durationSec: Int?

  public init(format: DesignExportFormat, pageIndexes: [Int]? = nil, durationSec: Int? = nil) {
    self.format = format
    self.pageIndexes = pageIndexes
    self.durationSec = durationSec
  }

  enum CodingKeys: String, CodingKey {
    case format
    case pageIndexes = "page_indexes"
    case durationSec = "duration_sec"
  }
}

/// The body of ``DesignsResource/bulk(_:_:)``: one new design per row. A column
/// named after a layer's id or name fills it: text for a text layer, a media id
/// for an image layer.
public struct BulkDesignsRequest: Codable, Sendable {
  /// 1 to 50 rows of column name to value.
  public var rows: [[String: String]]
  /// The column each new design is named after.
  public var nameColumn: String?

  public init(rows: [[String: String]], nameColumn: String? = nil) {
    self.rows = rows
    self.nameColumn = nameColumn
  }

  enum CodingKeys: String, CodingKey {
    case rows
    case nameColumn = "name_column"
  }
}

/// The body of ``DesignsResource/textToSlides(_:)``. Send `text`, or a `postID`
/// whose text is read instead. Needs the `ai` scope.
public struct TextToSlidesRequest: Codable, Sendable {
  public var workspaceID: String
  public var text: String?
  public var postID: String?
  /// 2 to 18.
  public var maxSlides: Int?
  public var brandVoiceID: String?

  public init(
    workspaceID: String, text: String? = nil, postID: String? = nil, maxSlides: Int? = nil,
    brandVoiceID: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.text = text
    self.postID = postID
    self.maxSlides = maxSlides
    self.brandVoiceID = brandVoiceID
  }

  enum CodingKeys: String, CodingKey {
    case text
    case workspaceID = "workspace_id"
    case postID = "post_id"
    case maxSlides = "max_slides"
    case brandVoiceID = "brand_voice_id"
  }
}

/// The body of ``DesignsResource/fromPost(_:)``. Send `text`, or a `postID`
/// whose text is read instead.
public struct DesignFromPostRequest: Codable, Sendable {
  public var workspaceID: String
  public var text: String?
  public var postID: String?
  /// Defaults to `quote`.
  public var style: DesignTextStyle?
  public var preset: String?
  /// The account whose name and avatar a `post` style shows.
  public var accountID: String?
  /// Splits long text across carousel pages.
  public var carousel: Bool?
  public var name: String?
  public var brandVoiceID: String?

  public init(
    workspaceID: String, text: String? = nil, postID: String? = nil,
    style: DesignTextStyle? = nil, preset: String? = nil, accountID: String? = nil,
    carousel: Bool? = nil, name: String? = nil, brandVoiceID: String? = nil
  ) {
    self.workspaceID = workspaceID
    self.text = text
    self.postID = postID
    self.style = style
    self.preset = preset
    self.accountID = accountID
    self.carousel = carousel
    self.name = name
    self.brandVoiceID = brandVoiceID
  }

  enum CodingKeys: String, CodingKey {
    case text, style, preset, carousel, name
    case workspaceID = "workspace_id"
    case postID = "post_id"
    case accountID = "account_id"
    case brandVoiceID = "brand_voice_id"
  }
}
