import Foundation

// Per-network extras under /accounts/{id}/<platform>/…, all on the accounts scope.

/// A Pinterest board a Pin can land on. Pass ``id`` as the `board_id` platform setting.
public struct PinterestBoard: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let privacy: String?
  public let description: String?
  /// The board cover image.
  public let image: String?
}

/// A new Pinterest board. `privacy` is `PUBLIC`, `PROTECTED` or `SECRET`.
public struct CreatePinterestBoardRequest: Encodable, Sendable {
  public var name: String
  public var description: String?
  public var privacy: String?

  public init(name: String, description: String? = nil, privacy: String? = nil) {
    self.name = name
    self.description = description
    self.privacy = privacy
  }
}

/// A playlist on the connected channel. ``isDefault`` marks the one a new video
/// joins when the post picks none.
public struct YouTubePlaylist: Codable, Sendable, Hashable {
  public let id: String
  public let title: String?
  public let description: String?
  public let privacy: String?
  public let itemCount: Int?
  public let thumbnailURL: String?
  public let isDefault: Bool?

  enum CodingKeys: String, CodingKey {
    case id, title, description, privacy
    case itemCount = "item_count"
    case thumbnailURL = "thumbnail_url"
    case isDefault = "is_default"
  }
}

/// A new playlist. `privacy` is `public`, `unlisted` or `private`.
public struct CreateYouTubePlaylistRequest: Encodable, Sendable {
  public var title: String
  public var description: String?
  public var privacy: String?

  public init(title: String, description: String? = nil, privacy: String? = nil) {
    self.title = title
    self.description = description
    self.privacy = privacy
  }
}

/// A caption track on one of the channel's videos.
public struct YouTubeCaptionTrack: Codable, Sendable, Hashable {
  public let id: String
  /// A BCP-47 tag.
  public let language: String?
  public let name: String?
  public let trackKind: String?
  public let isDraft: Bool?
  public let isAutoSynced: Bool?
  public let lastUpdated: String?

  enum CodingKeys: String, CodingKey {
    case id, language, name
    case trackKind = "track_kind"
    case isDraft = "is_draft"
    case isAutoSynced = "is_auto_synced"
    case lastUpdated = "last_updated"
  }
}

/// A caption track to upload. `body` is the subtitle file itself; YouTube reads
/// SRT and WebVTT and works out which from the bytes.
public struct UploadYouTubeCaptionsRequest: Encodable, Sendable {
  public var language: String
  public var body: String
  public var name: String?
  public var isDraft: Bool?

  public init(language: String, body: String, name: String? = nil, isDraft: Bool? = nil) {
    self.language = language
    self.body = body
    self.name = name
    self.isDraft = isDraft
  }

  enum CodingKeys: String, CodingKey {
    case language, body, name
    case isDraft = "is_draft"
  }
}

/// One caption track read back as text, in SRT.
public struct YouTubeTranscript: Codable, Sendable, Hashable {
  public let captionID: String
  public let transcript: String

  enum CodingKeys: String, CodingKey {
    case captionID = "caption_id"
    case transcript
  }
}

/// The default post languages for a Bluesky connection: up to three BCP-47 tags.
public struct BlueskyLanguages: Codable, Sendable, Hashable {
  public let languages: [String]
}

/// The switches TikTok enforces at publish time. They are set on the TikTok
/// account itself, not in FoPost.
public struct TikTokCreatorInfo: Codable, Sendable, Hashable {
  public let username: String?
  public let nickname: String?
  public let avatarURL: String?
  /// The levels this creator may publish at right now.
  public let privacyLevelOptions: [String]?
  public let commentDisabled: Bool?
  public let duetDisabled: Bool?
  public let stitchDisabled: Bool?
  public let maxVideoPostDurationSec: Int?

  enum CodingKeys: String, CodingKey {
    case username, nickname
    case avatarURL = "avatar_url"
    case privacyLevelOptions = "privacy_level_options"
    case commentDisabled = "comment_disabled"
    case duetDisabled = "duet_disabled"
    case stitchDisabled = "stitch_disabled"
    case maxVideoPostDurationSec = "max_video_post_duration_sec"
  }
}

/// A track from TikTok's Commercial Music Library. Pass ``id`` as the
/// `music_id` platform setting.
public struct TikTokMusic: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let author: String?
  public let durationSec: Int?
  public let coverURL: String?
  public let previewURL: String?

  enum CodingKeys: String, CodingKey {
    case id, title, author
    case durationSec = "duration_sec"
    case coverURL = "cover_url"
    case previewURL = "preview_url"
  }
}

/// A place a post can be tagged with. Pass ``id`` as the `location_id` platform
/// setting.
public struct TikTokPlace: Codable, Sendable, Hashable {
  public let id: String
  public let name: String
  public let address: String?
  public let city: String?
  public let country: String?
}

/// One of the account's own videos, resolved from a share link. TikTok serves
/// no raw media file, so ``downloadURL`` is the share address, which is what a
/// repurpose run reads.
public struct TikTokVideoSource: Codable, Sendable, Hashable {
  public let videoID: String
  public let title: String?
  public let description: String?
  public let durationSec: Int?
  public let coverImageURL: String?
  public let shareURL: String?
  public let embedLink: String?
  public let downloadURL: String?

  enum CodingKeys: String, CodingKey {
    case videoID = "video_id"
    case title, description
    case durationSec = "duration_sec"
    case coverImageURL = "cover_image_url"
    case shareURL = "share_url"
    case embedLink = "embed_link"
    case downloadURL = "download_url"
  }
}

/// A track a Reel can carry. Pass ``id`` as the `audio_id` platform setting.
public struct InstagramAudio: Codable, Sendable, Hashable {
  public let id: String
  public let title: String?
  public let artist: String?
  public let durationMs: Int?
  public let audioType: String?
  public let coverArtworkURL: String?
  public let previewURL: String?
  public let username: String?
  public let isAdsEligible: Bool?

  enum CodingKeys: String, CodingKey {
    case id, title, artist, username
    case durationMs = "duration_ms"
    case audioType = "audio_type"
    case coverArtworkURL = "cover_artwork_url"
    case previewURL = "preview_url"
    case isAdsEligible = "is_ads_eligible"
  }
}

/// What this account has published in the rolling window, and what is left.
public struct InstagramPublishingLimit: Codable, Sendable, Hashable {
  public let quotaUsage: Int?
  public let quotaTotal: Int?
  public let quotaDurationSec: Int?
  public let remaining: Int?

  enum CodingKeys: String, CodingKey {
    case quotaUsage = "quota_usage"
    case quotaTotal = "quota_total"
    case quotaDurationSec = "quota_duration_sec"
    case remaining
  }
}

/// A story still inside its 24 hours. ``insights`` is present only when asked for.
public struct InstagramStory: Codable, Sendable, Hashable {
  public let id: String
  public let mediaType: String?
  public let mediaProductType: String?
  public let permalink: String?
  public let mediaURL: String?
  public let thumbnailURL: String?
  public let caption: String?
  public let timestamp: String?
  public let insights: [String: Int]?

  enum CodingKeys: String, CodingKey {
    case id, permalink, caption, timestamp, insights
    case mediaType = "media_type"
    case mediaProductType = "media_product_type"
    case mediaURL = "media_url"
    case thumbnailURL = "thumbnail_url"
  }
}

/// The insight set for one story.
public struct InstagramStoryInsights: Codable, Sendable, Hashable {
  public let storyID: String
  public let insights: [String: Int]

  enum CodingKeys: String, CodingKey {
    case storyID = "story_id"
    case insights
  }
}

/// An entity a LinkedIn post can mention. ``annotation`` is what the post text
/// carries for LinkedIn to render a link.
public struct LinkedInMention: Codable, Sendable, Hashable {
  public let urn: String
  public let name: String
  public let vanityName: String?
  public let logoURL: String?
  public let type: String?
  public let annotation: String

  enum CodingKeys: String, CodingKey {
    case urn, name, type, annotation
    case vanityName = "vanity_name"
    case logoURL = "logo_url"
  }
}
