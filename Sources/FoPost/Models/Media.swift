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
  public let size: Int?
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
  public let size: Int?

  /// Turns an uploaded asset into a content-block attachment.
  public func asMediaItem() -> MediaItem {
    MediaItem(type: type ?? "image", name: name, url: url, size: size.map(Double.init))
  }
}

/// One upload: a name and the bytes behind it.
public struct UploadFile: Sendable, Hashable {
  public var name: String
  public var data: Data
  /// Guessed from the file extension when left nil.
  public var mimeType: String?

  public init(name: String, data: Data, mimeType: String? = nil) {
    self.name = name
    self.data = data
    self.mimeType = mimeType
  }

  /// Reads a file off disk.
  public init(contentsOf url: URL, mimeType: String? = nil) throws {
    self.init(
      name: url.lastPathComponent, data: try Data(contentsOf: url), mimeType: mimeType)
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
}
