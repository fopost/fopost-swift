import Foundation

/// Where an article stands, from the request to the live page.
public struct BlogArticleStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let queued: Self = "queued"
  public static let writing: Self = "writing"
  public static let draft: Self = "draft"
  /// Submitted for approval; publishing and scheduling are open from here.
  public static let inReview: Self = "in_review"
  public static let scheduled: Self = "scheduled"
  public static let publishing: Self = "publishing"
  public static let published: Self = "published"
  public static let failed: Self = "failed"
  public static let rejected: Self = "rejected"
}

/// Where a keyword stands in the plan.
public struct BlogKeywordStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let suggested: Self = "suggested"
  public static let planned: Self = "planned"
  public static let written: Self = "written"
  public static let dismissed: Self = "dismissed"
}

/// Where a published article goes.
public struct BlogTargetKind: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  /// The blog hosted with the product.
  public static let productBlog: Self = "product_blog"
  /// A connected account that takes long-form articles.
  public static let account: Self = "account"
  /// Your own website, reached through the signed `article.published` webhook.
  public static let website: Self = "website"
}

/// What the blog is for; steers suggested terms and keyword ranking.
public struct BlogGoal: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let traffic: Self = "traffic"
  public static let leads: Self = "leads"
  public static let sales: Self = "sales"
  public static let signups: Self = "signups"
  public static let authority: Self = "authority"
}

/// Where a keyword research run stands.
public struct BlogPlanRunStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let queued: Self = "queued"
  public static let running: Self = "running"
  public static let done: Self = "done"
  public static let failed: Self = "failed"
}

/// The last keyword research run.
public struct BlogPlanRun: Codable, Sendable, Hashable {
  public let status: BlogPlanRunStatus?
  public let error: String?
  /// New keywords the run found.
  public let added: Int?
  public let finishedAt: Date?

  enum CodingKeys: String, CodingKey {
    case status, error, added
    case finishedAt = "finished_at"
  }
}

/// Who asked for a keyword.
public struct BlogKeywordSource: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let provider: Self = "provider"
  public static let user: Self = "user"
  public static let agent: Self = "agent"
}

/// Who asked for an article.
public struct BlogArticleOrigin: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let plan: Self = "plan"
  public static let user: Self = "user"
  public static let agent: Self = "agent"
}

/// The image quality tier articles are illustrated at.
public struct BlogImageTier: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let draft: Self = "draft"
  public static let standard: Self = "standard"
  public static let best: Self = "best"
}

/// How a workspace's blog is planned, written, and published.
public struct BlogSettings: Codable, Sendable, Hashable {
  public let siteUrl: String?
  public let topic: String?
  public let audience: String?
  public let goal: BlogGoal?
  /// What the blog wants to write about.
  public let focusTopics: String?
  /// What the blog never writes about.
  public let avoidTopics: String?
  public let language: String?
  public let locationCode: Int?
  /// Articles planned per week; 0 turns planning off.
  public let cadencePerWeek: Int?
  /// Days before its planned date that a picked keyword starts being written.
  public let reviewHoldDays: Int?
  public let imageTier: BlogImageTier?
  public let inBodyImages: Int?
  public let minWords: Int?
  public let maxWords: Int?
  public let brandVoiceID: String?
  public let targetKind: BlogTargetKind?
  public let targetAccountID: String?
  public let targetPlatform: String?
  public let websiteUrl: String?
  public let hasWebsiteSecret: Bool?
  /// The last keyword research run; nil before the first.
  public let planRun: BlogPlanRun?
  /// Whether search volume and difficulty can be fetched on this deployment.
  public let keywordDataAvailable: Bool?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case topic, audience, goal, language
    case siteUrl = "site_url"
    case focusTopics = "focus_topics"
    case avoidTopics = "avoid_topics"
    case locationCode = "location_code"
    case cadencePerWeek = "cadence_per_week"
    case reviewHoldDays = "review_hold_days"
    case imageTier = "image_tier"
    case inBodyImages = "in_body_images"
    case minWords = "min_words"
    case maxWords = "max_words"
    case brandVoiceID = "brand_voice_id"
    case targetKind = "target_kind"
    case targetAccountID = "target_account_id"
    case targetPlatform = "target_platform"
    case websiteUrl = "website_url"
    case hasWebsiteSecret = "has_website_secret"
    case planRun = "plan_run"
    case keywordDataAvailable = "keyword_data_available"
    case updatedAt = "updated_at"
  }
}

/// The answer to ``BlogResource/updateSettings(workspaceID:_:)``.
public struct BlogSettingsUpdated: Codable, Sendable, Hashable {
  public let settings: BlogSettings
  /// The website signing secret, present only on the call that first set
  /// `websiteUrl`. Store it now; it is never shown again.
  public let websiteSecret: String?

  enum CodingKeys: String, CodingKey {
    case websiteSecret = "website_secret"
  }

  // The secret sits beside the settings fields, not in an envelope.
  public init(from decoder: any Decoder) throws {
    settings = try BlogSettings(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    websiteSecret = try container.decodeIfPresent(String.self, forKey: .websiteSecret)
  }

  public func encode(to encoder: any Encoder) throws {
    try settings.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(websiteSecret, forKey: .websiteSecret)
  }
}

/// A freshly rotated website signing secret, shown once.
public struct BlogWebsiteSecret: Codable, Sendable, Hashable {
  public let websiteSecret: String

  enum CodingKeys: String, CodingKey {
    case websiteSecret = "website_secret"
  }
}

/// What the website target answered to a test delivery. `error` explains a
/// failed test.
public struct BlogWebsiteTest: Codable, Sendable, Hashable {
  public var ok: Bool
  /// The HTTP status the website answered, when it answered.
  public var httpStatus: Int?
  public var error: String?

  public init(ok: Bool, httpStatus: Int?, error: String?) {
    self.ok = ok
    self.httpStatus = httpStatus
    self.error = error
  }

  enum CodingKeys: String, CodingKey {
    case ok, error
    case httpStatus = "http_status"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    ok = try container.decodeIfPresent(Bool.self, forKey: .ok) ?? true
    httpStatus = try container.decodeIfPresent(Int.self, forKey: .httpStatus)
    error = try container.decodeIfPresent(String.self, forKey: .error)
  }
}

/// The body of ``BlogResource/updateSettings(workspaceID:_:)``. Only the
/// fields you set are sent; a nullable field set to `.some(nil)` is cleared.
public struct UpdateBlogSettingsRequest: Codable, Sendable {
  public var siteUrl: String??
  public var topic: String??
  public var audience: String??
  public var goal: BlogGoal??
  /// What the blog wants to write about.
  public var focusTopics: String??
  /// What the blog never writes about.
  public var avoidTopics: String??
  public var language: String?
  public var locationCode: Int?
  public var cadencePerWeek: Int?
  /// Days before its planned date that a picked keyword starts being written, 0 to 14.
  public var reviewHoldDays: Int?
  public var imageTier: BlogImageTier?
  public var inBodyImages: Int?
  public var minWords: Int?
  public var maxWords: Int?
  public var brandVoiceID: String??
  public var targetKind: BlogTargetKind??
  public var targetAccountID: String??
  /// Where published articles are POSTed as a signed webhook. Setting it
  /// issues a secret, returned once on ``BlogSettingsUpdated/websiteSecret``.
  public var websiteUrl: String??

  public init(
    siteUrl: String?? = nil, topic: String?? = nil, audience: String?? = nil,
    goal: BlogGoal?? = nil, focusTopics: String?? = nil, avoidTopics: String?? = nil,
    language: String? = nil, locationCode: Int? = nil, cadencePerWeek: Int? = nil,
    reviewHoldDays: Int? = nil, imageTier: BlogImageTier? = nil,
    inBodyImages: Int? = nil, minWords: Int? = nil, maxWords: Int? = nil,
    brandVoiceID: String?? = nil, targetKind: BlogTargetKind?? = nil,
    targetAccountID: String?? = nil, websiteUrl: String?? = nil
  ) {
    self.siteUrl = siteUrl
    self.topic = topic
    self.audience = audience
    self.goal = goal
    self.focusTopics = focusTopics
    self.avoidTopics = avoidTopics
    self.language = language
    self.locationCode = locationCode
    self.cadencePerWeek = cadencePerWeek
    self.reviewHoldDays = reviewHoldDays
    self.imageTier = imageTier
    self.inBodyImages = inBodyImages
    self.minWords = minWords
    self.maxWords = maxWords
    self.brandVoiceID = brandVoiceID
    self.targetKind = targetKind
    self.targetAccountID = targetAccountID
    self.websiteUrl = websiteUrl
  }

  enum CodingKeys: String, CodingKey {
    case siteUrl, topic, audience, goal, focusTopics, avoidTopics, language, locationCode
    case cadencePerWeek, reviewHoldDays, imageTier, inBodyImages, minWords, maxWords, targetKind
    case websiteUrl
    case brandVoiceID = "brandVoiceId"
    case targetAccountID = "targetAccountId"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    // Outer nil leaves the key out, inner nil sends null to clear the value.
    if let siteUrl { try container.encode(siteUrl, forKey: .siteUrl) }
    if let topic { try container.encode(topic, forKey: .topic) }
    if let audience { try container.encode(audience, forKey: .audience) }
    if let goal { try container.encode(goal, forKey: .goal) }
    if let focusTopics { try container.encode(focusTopics, forKey: .focusTopics) }
    if let avoidTopics { try container.encode(avoidTopics, forKey: .avoidTopics) }
    try container.encodeIfPresent(language, forKey: .language)
    try container.encodeIfPresent(locationCode, forKey: .locationCode)
    try container.encodeIfPresent(cadencePerWeek, forKey: .cadencePerWeek)
    try container.encodeIfPresent(reviewHoldDays, forKey: .reviewHoldDays)
    try container.encodeIfPresent(imageTier, forKey: .imageTier)
    try container.encodeIfPresent(inBodyImages, forKey: .inBodyImages)
    try container.encodeIfPresent(minWords, forKey: .minWords)
    try container.encodeIfPresent(maxWords, forKey: .maxWords)
    if let brandVoiceID { try container.encode(brandVoiceID, forKey: .brandVoiceID) }
    if let targetKind { try container.encode(targetKind, forKey: .targetKind) }
    if let targetAccountID { try container.encode(targetAccountID, forKey: .targetAccountID) }
    if let websiteUrl { try container.encode(websiteUrl, forKey: .websiteUrl) }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    siteUrl = try container.decodeIfPresent(String?.self, forKey: .siteUrl)
    topic = try container.decodeIfPresent(String?.self, forKey: .topic)
    audience = try container.decodeIfPresent(String?.self, forKey: .audience)
    goal = try container.decodeIfPresent(BlogGoal?.self, forKey: .goal)
    focusTopics = try container.decodeIfPresent(String?.self, forKey: .focusTopics)
    avoidTopics = try container.decodeIfPresent(String?.self, forKey: .avoidTopics)
    language = try container.decodeIfPresent(String.self, forKey: .language)
    locationCode = try container.decodeIfPresent(Int.self, forKey: .locationCode)
    cadencePerWeek = try container.decodeIfPresent(Int.self, forKey: .cadencePerWeek)
    reviewHoldDays = try container.decodeIfPresent(Int.self, forKey: .reviewHoldDays)
    imageTier = try container.decodeIfPresent(BlogImageTier.self, forKey: .imageTier)
    inBodyImages = try container.decodeIfPresent(Int.self, forKey: .inBodyImages)
    minWords = try container.decodeIfPresent(Int.self, forKey: .minWords)
    maxWords = try container.decodeIfPresent(Int.self, forKey: .maxWords)
    brandVoiceID = try container.decodeIfPresent(String?.self, forKey: .brandVoiceID)
    targetKind = try container.decodeIfPresent(BlogTargetKind?.self, forKey: .targetKind)
    targetAccountID = try container.decodeIfPresent(String?.self, forKey: .targetAccountID)
    websiteUrl = try container.decodeIfPresent(String?.self, forKey: .websiteUrl)
  }
}

/// One keyword in the plan.
public struct BlogKeyword: Codable, Sendable, Hashable {
  public let id: String
  public let keyword: String
  public let searchVolume: Int?
  /// 0 to 100.
  public let difficulty: Int?
  public let cpc: Double?
  public let intent: String?
  public let source: BlogKeywordSource?
  public let status: BlogKeywordStatus?
  /// The day an article on it is planned for, as `YYYY-MM-DD`.
  public let plannedFor: String?
  /// Why the keyword serves the blog goal.
  public let fitReason: String?
  public let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, keyword, difficulty, cpc, intent, source, status
    case searchVolume = "search_volume"
    case plannedFor = "planned_for"
    case fitReason = "fit_reason"
    case createdAt = "created_at"
  }
}

/// The body of ``BlogResource/addKeyword(workspaceID:_:)``.
public struct AddBlogKeywordRequest: Codable, Sendable {
  public var keyword: String
  /// `YYYY-MM-DD`.
  public var plannedFor: String?

  public init(keyword: String, plannedFor: String? = nil) {
    self.keyword = keyword
    self.plannedFor = plannedFor
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(keyword, forKey: .keyword)
    try container.encodeIfPresent(plannedFor, forKey: .plannedFor)
  }
}

/// The body of ``BlogResource/updateKeyword(workspaceID:_:_:)``. Only the
/// fields you set are sent; `plannedFor: .some(nil)` takes it off the calendar.
/// Setting `status` to ``BlogKeywordStatus/planned`` picks the keyword onto the
/// next free date.
public struct UpdateBlogKeywordRequest: Codable, Sendable {
  public var status: BlogKeywordStatus?
  public var plannedFor: String??

  public init(status: BlogKeywordStatus? = nil, plannedFor: String?? = nil) {
    self.status = status
    self.plannedFor = plannedFor
  }

  enum CodingKeys: String, CodingKey { case status, plannedFor }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(status, forKey: .status)
    if let plannedFor { try container.encode(plannedFor, forKey: .plannedFor) }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    status = try container.decodeIfPresent(BlogKeywordStatus.self, forKey: .status)
    plannedFor = try container.decodeIfPresent(String?.self, forKey: .plannedFor)
  }
}

/// The body of ``BlogResource/planKeywords(workspaceID:seeds:)``.
struct PlanBlogKeywordsRequest: Codable, Sendable {
  var workspaceId: String
  var seeds: [String]?

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(workspaceId, forKey: .workspaceId)
    try container.encodeIfPresent(seeds, forKey: .seeds)
  }
}

/// The body of ``BlogResource/suggestSeeds(workspaceID:seeds:prompt:)``.
struct SuggestBlogSeedsRequest: Codable, Sendable {
  var workspaceId: String
  var seeds: [String]?
  var prompt: String?

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(workspaceId, forKey: .workspaceId)
    try container.encodeIfPresent(seeds, forKey: .seeds)
    try container.encodeIfPresent(prompt, forKey: .prompt)
  }
}

/// Search terms suggested from the blog goal and topics.
public struct BlogSeedSuggestions: Codable, Sendable, Hashable {
  public let seeds: [String]
}

/// The answer to a queued job.
public struct BlogQueued: Codable, Sendable, Hashable {
  public let status: String
}

/// One image on an article. The URL is fetchable for six hours; download and
/// store your own copy.
public struct BlogArticleImage: Codable, Sendable, Hashable {
  public let mediaID: String
  public let url: String
  public let alt: String
  /// Index of the outline heading the image sits under; absent on the
  /// featured image.
  public let position: Int?

  public init(mediaID: String, url: String, alt: String, position: Int? = nil) {
    self.mediaID = mediaID
    self.url = url
    self.alt = alt
    self.position = position
  }

  enum CodingKeys: String, CodingKey {
    case url, alt, position
    case mediaID = "media_id"
    case legacyMediaID = "mediaId"
  }

  // Articles answer `media_id`; the `article.published` webhook sends `mediaId`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    mediaID =
      try container.decodeIfPresent(String.self, forKey: .mediaID)
      ?? container.decode(String.self, forKey: .legacyMediaID)
    url = try container.decode(String.self, forKey: .url)
    alt = try container.decode(String.self, forKey: .alt)
    position = try container.decodeIfPresent(Int.self, forKey: .position)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(mediaID, forKey: .mediaID)
    try container.encode(url, forKey: .url)
    try container.encode(alt, forKey: .alt)
    try container.encodeIfPresent(position, forKey: .position)
  }
}

/// An article as a listing shows it: everything but the body.
public struct BlogArticle: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let slug: String
  public let keyword: String?
  public let excerpt: String?
  public let metaTitle: String?
  public let metaDescription: String?
  public let featuredImage: BlogArticleImage?
  public let tags: [String]?
  public let wordCount: Int?
  public let status: BlogArticleStatus?
  public let origin: BlogArticleOrigin?
  public let reviewUntil: Date?
  public let publishAt: Date?
  public let publishedAt: Date?
  public let publishedUrl: String?
  public let error: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, title, slug, keyword, excerpt, tags, status, origin, error
    case metaTitle = "meta_title"
    case metaDescription = "meta_description"
    case featuredImage = "featured_image"
    case wordCount = "word_count"
    case reviewUntil = "review_until"
    case publishAt = "publish_at"
    case publishedAt = "published_at"
    case publishedUrl = "published_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

/// An article with its body, outline, brief, and images.
public struct BlogArticleFull: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let slug: String
  public let keyword: String?
  public let excerpt: String?
  public let metaTitle: String?
  public let metaDescription: String?
  public let featuredImage: BlogArticleImage?
  public let tags: [String]?
  public let wordCount: Int?
  public let status: BlogArticleStatus?
  public let origin: BlogArticleOrigin?
  public let reviewUntil: Date?
  public let publishAt: Date?
  public let publishedAt: Date?
  public let publishedUrl: String?
  public let error: String?
  public let createdAt: Date?
  public let updatedAt: Date?
  public let instructions: String?
  public let outline: [String]?
  /// The research the writer worked from.
  public let brief: JSONValue?
  public let bodyMarkdown: String?
  public let bodyHtml: String?
  public let images: [BlogArticleImage]?

  enum CodingKeys: String, CodingKey {
    case id, title, slug, keyword, excerpt, tags, status, origin, error, instructions, outline
    case brief, images
    case metaTitle = "meta_title"
    case metaDescription = "meta_description"
    case featuredImage = "featured_image"
    case wordCount = "word_count"
    case reviewUntil = "review_until"
    case publishAt = "publish_at"
    case publishedAt = "published_at"
    case publishedUrl = "published_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case bodyMarkdown = "body_markdown"
    case bodyHtml = "body_html"
  }
}

/// The body of ``BlogResource/requestArticle(workspaceID:_:)``. One of
/// `title`, `keyword` or `keywordID` is required.
public struct RequestBlogArticleRequest: Codable, Sendable {
  public var title: String?
  public var keyword: String?
  /// A keyword from the plan; its term becomes the target.
  public var keywordID: String?
  public var instructions: String?

  public init(
    title: String? = nil, keyword: String? = nil, keywordID: String? = nil,
    instructions: String? = nil
  ) {
    self.title = title
    self.keyword = keyword
    self.keywordID = keywordID
    self.instructions = instructions
  }

  enum CodingKeys: String, CodingKey {
    case title, keyword, instructions
    case keywordID = "keywordId"
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(keyword, forKey: .keyword)
    try container.encodeIfPresent(keywordID, forKey: .keywordID)
    try container.encodeIfPresent(instructions, forKey: .instructions)
  }
}

/// The body of ``BlogResource/updateArticle(workspaceID:_:_:)``. Only the
/// fields you set are sent; a nullable field set to `.some(nil)` is cleared.
public struct UpdateBlogArticleRequest: Codable, Sendable {
  public var title: String?
  public var slug: String?
  public var excerpt: String??
  public var metaTitle: String??
  public var metaDescription: String??
  public var bodyMarkdown: String?
  public var tags: [String]?
  /// Puts the article on the calendar; `.some(nil)` returns it to review. Needs
  /// the article in review (or already scheduled or failed); a draft answers `409`.
  public var publishAt: Date??

  public init(
    title: String? = nil, slug: String? = nil, excerpt: String?? = nil,
    metaTitle: String?? = nil, metaDescription: String?? = nil, bodyMarkdown: String? = nil,
    tags: [String]? = nil, publishAt: Date?? = nil
  ) {
    self.title = title
    self.slug = slug
    self.excerpt = excerpt
    self.metaTitle = metaTitle
    self.metaDescription = metaDescription
    self.bodyMarkdown = bodyMarkdown
    self.tags = tags
    self.publishAt = publishAt
  }

  enum CodingKeys: String, CodingKey {
    case title, slug, excerpt, metaTitle, metaDescription, bodyMarkdown, tags, publishAt
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(slug, forKey: .slug)
    if let excerpt { try container.encode(excerpt, forKey: .excerpt) }
    if let metaTitle { try container.encode(metaTitle, forKey: .metaTitle) }
    if let metaDescription { try container.encode(metaDescription, forKey: .metaDescription) }
    try container.encodeIfPresent(bodyMarkdown, forKey: .bodyMarkdown)
    try container.encodeIfPresent(tags, forKey: .tags)
    if let publishAt { try container.encode(publishAt, forKey: .publishAt) }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    slug = try container.decodeIfPresent(String.self, forKey: .slug)
    excerpt = try container.decodeIfPresent(String?.self, forKey: .excerpt)
    metaTitle = try container.decodeIfPresent(String?.self, forKey: .metaTitle)
    metaDescription = try container.decodeIfPresent(String?.self, forKey: .metaDescription)
    bodyMarkdown = try container.decodeIfPresent(String.self, forKey: .bodyMarkdown)
    tags = try container.decodeIfPresent([String].self, forKey: .tags)
    publishAt = try container.decodeIfPresent(Date?.self, forKey: .publishAt)
  }
}

/// The `data` of an `article.published` webhook: the whole article, ready to
/// store. Image URLs are fetchable for six hours; download your own copy.
public struct BlogArticleWebhookPayload: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let slug: String
  public let excerpt: String?
  public let metaTitle: String?
  public let metaDescription: String?
  public let bodyMarkdown: String?
  public let bodyHtml: String?
  public let featuredImage: BlogArticleImage?
  public let images: [BlogArticleImage]?
  public let tags: [String]?
  public let keyword: String?
  public let wordCount: Int?
  public let publishedAt: Date?
  /// Where the article went live, when the target reported it.
  public let publishedUrl: String?
}
