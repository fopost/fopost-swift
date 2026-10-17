import Foundation

/// One stored asset in the media library.
public struct MediaLibraryItem: Codable, Sendable, Hashable {
  public let id: String
  public let userId: String?
  public let workspaceId: String?
  public let name: String?
  public let url: String?
  /// `image`, `video`, `gif`, or `document`.
  public let type: String?
  public let mimeType: String?
  public let size: Int64?
  public let altText: String?
  public let createdAt: Date?
}

/// An asset as it comes back from an upload, shaped to drop straight into a
/// post's content block.
public struct UploadedMedia: Codable, Sendable, Hashable {
  public let id: String?
  public let type: String?
  public let name: String?
  public let url: String
  public let size: Int64?

  /// Turns an uploaded asset into a content-block attachment.
  public func asMediaItem() -> MediaItem {
    MediaItem(type: type ?? "image", name: name, url: url, size: size.map(Double.init))
  }
}

/// One upload: a name and the bytes behind it, in memory or on disk. A file
/// on disk is streamed, so a multi-gigabyte video is never held in memory.
public struct UploadFile: Sendable, Hashable {
  /// Where the bytes come from.
  public enum Source: Sendable, Hashable {
    case data(Data)
    case file(URL)
  }

  public var name: String
  public var source: Source
  /// Guessed from the file extension when left nil.
  public var mimeType: String?

  public init(name: String, data: Data, mimeType: String? = nil) {
    self.name = name
    self.source = .data(data)
    self.mimeType = mimeType
  }

  /// Points at a file on disk. The bytes are read when the upload is sent.
  public init(contentsOf url: URL, name: String? = nil, mimeType: String? = nil) {
    self.name = name ?? url.lastPathComponent
    self.source = .file(url)
    self.mimeType = mimeType
  }

  /// The MIME type sent with the file.
  public var resolvedMimeType: String { mimeType ?? MultipartForm.mimeType(for: name) }

  /// The size in bytes, read off disk for a file.
  public func size() throws -> Int64 {
    switch source {
    case .data(let data):
      return Int64(data.count)
    case .file(let url):
      let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
      guard let size = attributes[.size] as? NSNumber else {
        throw FoPostError.configuration(message: "Could not read the size of \(url.path).")
      }
      return size.int64Value
    }
  }

  /// The whole file in memory, for the multipart route.
  public func bytes() throws -> Data {
    switch source {
    case .data(let data): return data
    case .file(let url): return try Data(contentsOf: url)
    }
  }

  /// `image`, `video`, or `gif`, as a content block names it.
  var mediaType: String {
    let mime = resolvedMimeType.lowercased()
    if mime == "image/gif" { return "gif" }
    if mime.hasPrefix("video/") { return "video" }
    return "image"
  }
}

/// A consent attestation for a `person` brand asset.
public struct PersonConsent: Codable, Sendable, Hashable {
  /// Who the person in the asset is.
  public var subject: String
  /// The statement they agreed to.
  public var statement: String

  public init(subject: String, statement: String) {
    self.subject = subject
    self.statement = statement
  }
}

/// Library placement for a presigned upload, all optional.
public struct PresignOptions: Sendable, Hashable {
  public var folderID: String?
  /// `chat` when the asset came out of an agent conversation.
  public var origin: String?
  /// `logo`, `product`, `person`, or `background`.
  public var brandRole: String?
  public var brandVoiceID: String?
  /// Required when `brandRole` is `person`.
  public var personConsent: PersonConsent?

  public init(
    folderID: String? = nil, origin: String? = nil, brandRole: String? = nil,
    brandVoiceID: String? = nil, personConsent: PersonConsent? = nil
  ) {
    self.folderID = folderID
    self.origin = origin
    self.brandRole = brandRole
    self.brandVoiceID = brandVoiceID
    self.personConsent = personConsent
  }
}

/// A presigned slot for a direct upload: where to PUT the bytes, with which
/// headers, and until when.
public struct PresignedUpload: Codable, Sendable, Hashable {
  public let uploadId: String
  public let uploadUrl: String
  /// Always `PUT`.
  public let method: String?
  /// Sent verbatim on the PUT.
  public let headers: [String: String]?
  public let expiresAt: Date?
  /// The largest file the account may upload.
  public let maxFileBytes: Int64?
}

/// The next size tier an account can reach by connecting more accounts.
public struct UploadLimitTier: Codable, Sendable, Hashable {
  /// The connected-account count that tier covers, nil for the open-ended one.
  public let upToAccounts: Int?
  public let maxFileBytes: Int64
}

/// What the account may upload, from ``MediaResource/limits(workspaceID:)``.
public struct UploadLimits: Codable, Sendable, Hashable {
  /// The largest file the account may upload by any route.
  public let maxFileBytes: Int64
  /// Where `maxFileBytes` comes from: `accounts`, `add_on`, or `bypass`.
  public let source: String?
  public let connectedAccounts: Int?
  public let largeUploadsEnabled: Bool?
  public let nextTier: UploadLimitTier?
  /// The most one file in a multipart request may carry; bigger files go direct.
  public let multipartMaxFileBytes: Int64
  public let maxFilesPerUpload: Int?
  public let directUploadAvailable: Bool?
  public let allowedTypes: [String]?
}
