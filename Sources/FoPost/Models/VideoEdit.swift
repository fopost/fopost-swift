import Foundation

/// One video edit operation.
public struct VideoEditOp: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let trim: Self = "trim"
  public static let cut: Self = "cut"
  public static let speed: Self = "speed"
  public static let merge: Self = "merge"
  public static let volume: Self = "volume"
  public static let removeSilence: Self = "remove_silence"
  public static let denoise: Self = "denoise"
  public static let subtitles: Self = "subtitles"
  public static let translateSubtitles: Self = "translate_subtitles"
  public static let clips: Self = "clips"
  public static let music: Self = "music"
  public static let voiceover: Self = "voiceover"
  public static let watermark: Self = "watermark"
  public static let cover: Self = "cover"
  public static let reframe: Self = "reframe"
  public static let audiogram: Self = "audiogram"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .trim, .cut, .speed, .merge, .volume, .removeSilence, .denoise, .subtitles,
    .translateSubtitles, .clips, .music, .voiceover, .watermark, .cover, .reframe, .audiogram,
  ]
}

/// Where a video edit job is.
public struct VideoEditStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let queued: Self = "queued"
  public static let running: Self = "running"
  public static let succeeded: Self = "succeeded"
  public static let failed: Self = "failed"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.queued, .running, .succeeded, .failed]
}

/// Whether an operation can run on this server, and whether it spends AI.
public struct VideoEditOpInfo: Codable, Sendable, Hashable {
  public let name: VideoEditOp
  public let available: Bool
  /// An AI operation needs the `ai` scope and spends the prepaid balance.
  public let usesAI: Bool?

  enum CodingKeys: String, CodingKey {
    case name, available
    case usesAI = "uses_ai"
  }
}

/// One step of a video edit: an operation and its parameters.
public struct VideoEditOperation: Codable, Sendable, Hashable {
  public var op: VideoEditOp
  public var params: [String: JSONValue]?

  public init(op: VideoEditOp, params: [String: JSONValue]? = nil) {
    self.op = op
    self.params = params
  }
}

/// The finished video, in the media library.
public struct VideoEditResultMedia: Codable, Sendable, Hashable {
  public let id: String
  public let previewURL: String?
  public let mimeType: String?

  enum CodingKeys: String, CodingKey {
    case id
    case previewURL = "preview_url"
    case mimeType = "mime_type"
  }
}

/// A further file a job produced, such as a clip or a subtitle track.
public struct VideoEditOutput: Codable, Sendable, Hashable {
  public let mediaID: String
  public let label: String?
  public let mime: String?
  public let previewURL: String?

  enum CodingKeys: String, CodingKey {
    case label, mime
    case mediaID = "media_id"
    case previewURL = "preview_url"
  }
}

/// A video edit job. Poll ``VideoEditsResource/get(_:workspaceID:)`` until
/// `status` is `succeeded` or `failed`.
public struct VideoEditJob: Codable, Sendable, Hashable {
  public let id: String
  public let status: VideoEditStatus
  /// 0 to 1.
  public let progress: Double?
  public let sourceMediaID: String?
  public let operations: [VideoEditOperation]?
  public let resultMediaID: String?
  public let resultMedia: VideoEditResultMedia?
  public let extraOutputs: [VideoEditOutput]?
  public let result: [String: JSONValue]?
  public let error: String?
  public let createdAt: Date?
  public let updatedAt: Date?
  public let completedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, status, progress, operations, result, error
    case sourceMediaID = "source_media_id"
    case resultMediaID = "result_media_id"
    case resultMedia = "result_media"
    case extraOutputs = "extra_outputs"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case completedAt = "completed_at"
  }
}

/// The body of ``VideoEditsResource/create(_:)``.
public struct CreateVideoEditRequest: Codable, Sendable {
  /// The video to edit.
  public var mediaID: String
  /// 1 to 10 operations, run in order.
  public var operations: [VideoEditOperation]
  /// Left out, the media's own workspace is used.
  public var workspaceID: String?

  public init(mediaID: String, operations: [VideoEditOperation], workspaceID: String? = nil) {
    self.mediaID = mediaID
    self.operations = operations
    self.workspaceID = workspaceID
  }

  enum CodingKeys: String, CodingKey {
    case operations
    case mediaID = "media_id"
    case workspaceID = "workspace_id"
  }
}
