import Foundation

/// Whether an ad promotes an existing post or stands alone.
public struct AdKind: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let boost: Self = "boost"
  public static let ad: Self = "ad"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.boost, .ad]
}

/// What an ad is optimised for.
public struct AdGoal: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let engagement: Self = "engagement"
  public static let traffic: Self = "traffic"
  public static let awareness: Self = "awareness"
  public static let videoViews: Self = "video_views"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.engagement, .traffic, .awareness, .videoViews]
}

/// The delivery state a caller asks for.
public struct AdStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let active: Self = "active"
  public static let paused: Self = "paused"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.active, .paused]
}

/// How a budget is spent.
public struct AdBudgetType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let daily: Self = "daily"
  public static let lifetime: Self = "lifetime"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.daily, .lifetime]
}

/// The audience gender an ad targets.
public struct AdGender: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let all: Self = "all"
  public static let male: Self = "male"
  public static let female: Self = "female"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.all, .male, .female]
}

/// The granularity of a targeted location.
public struct AdLocationType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let region: Self = "region"
  public static let city: Self = "city"
  public static let zip: Self = "zip"
  public static let geoMarket: Self = "geo_market"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.region, .city, .zip, .geoMarket]
}

/// What ``AdsResource/searchTargeting(_:)`` looks up.
public struct TargetingSearchType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let country: Self = "country"
  public static let region: Self = "region"
  public static let city: Self = "city"
  public static let zip: Self = "zip"
  public static let metro: Self = "metro"
  public static let interest: Self = "interest"
  public static let behavior: Self = "behavior"
  public static let income: Self = "income"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .country, .region, .city, .zip, .metro, .interest, .behavior, .income,
  ]
}

/// The questions an Instant Form can ask.
public struct LeadFormQuestion: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let email: Self = "EMAIL"
  public static let fullName: Self = "FULL_NAME"
  public static let phone: Self = "PHONE"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.email, .fullName, .phone]
}

/// Which Meta login starts an ads connection.
public struct MetaAdsAuthMethod: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let business: Self = "business"
  public static let user: Self = "user"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.business, .user]
}

/// A targeted location as the platform names it.
public struct AdLocation: Codable, Sendable, Hashable {
  public var key: String
  public var name: String
  public var type: AdLocationType

  public init(key: String, name: String, type: AdLocationType) {
    self.key = key
    self.name = name
    self.type = type
  }
}

/// An interest, behaviour, or income bracket as the platform names it.
public struct AdTargetingEntry: Codable, Sendable, Hashable {
  public var id: String
  public var name: String

  public init(id: String, name: String) {
    self.id = id
    self.name = name
  }
}

/// Who an ad is shown to. `countries`, `ageMin`, `ageMax`, and `gender` are
/// required when creating; the rest narrow the audience further.
public struct AdTargeting: Codable, Sendable, Hashable {
  public var countries: [String]?
  public var ageMin: Int?
  public var ageMax: Int?
  public var gender: AdGender?
  public var audienceIds: [String]?
  public var locations: [AdLocation]?
  public var interests: [AdTargetingEntry]?
  public var behaviors: [AdTargetingEntry]?
  public var income: [AdTargetingEntry]?

  public init(
    countries: [String], ageMin: Int, ageMax: Int, gender: AdGender = .all,
    audienceIds: [String]? = nil, locations: [AdLocation]? = nil,
    interests: [AdTargetingEntry]? = nil, behaviors: [AdTargetingEntry]? = nil,
    income: [AdTargetingEntry]? = nil
  ) {
    self.countries = countries
    self.ageMin = ageMin
    self.ageMax = ageMax
    self.gender = gender
    self.audienceIds = audienceIds
    self.locations = locations
    self.interests = interests
    self.behaviors = behaviors
    self.income = income
  }
}

/// How much an ad may spend. `minor` is in the ad account's currency, in
/// minor units: `1500` is 15.00 on a two-decimal currency.
public struct AdBudget: Codable, Sendable, Hashable {
  public var minor: Int
  public var type: AdBudgetType
  public var endAt: Date?

  public init(minor: Int, type: AdBudgetType, endAt: Date? = nil) {
    self.minor = minor
    self.type = type
    self.endAt = endAt
  }
}

/// Lifetime results from the last refresh.
public struct AdInsights: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let clicks: Int?
  /// Account currency, minor units.
  public let spendMinor: Int?
}

/// A boost or ad created through FoPost.
public struct Ad: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let kind: AdKind?
  public let name: String?
  public let goal: AdGoal?
  /// What was asked for: `active` or `paused`.
  public let status: AdStatus?
  /// The platform's own delivery status, from the last refresh.
  public let effectiveStatus: String?
  public let connectionId: String?
  /// The connected account a boost was built from.
  public let accountId: String?
  public let platform: Platform?
  public let adAccountId: String?
  /// The FoPost post a boost promotes.
  public let sourcePostId: String?
  public let budgetMinor: Int?
  public let budgetType: AdBudgetType?
  public let currency: String?
  public let endAt: Date?
  public let targeting: AdTargeting?
  public let creative: [String: JSONValue]?
  public let insights: AdInsights?
  public let insightsAt: Date?
  public let lastError: String?
  public let createdAt: Date?
}

/// An ad on a connected ad account that was made elsewhere. Read live, never
/// stored.
public struct ExternalAd: Codable, Sendable, Hashable {
  /// The platform's ad id.
  public let id: String
  public let name: String?
  public let effectiveStatus: String?
  public let campaignId: String?
  public let campaignName: String?
  public let objective: String?
  public let budgetMinor: Int?
  public let budgetType: AdBudgetType?
  public let endAt: Date?
  public let createdAt: Date?
  public let connectionId: String?
  public let adAccountId: String?
  public let currency: String?
  public let workspaceId: String?
}

/// A published post with a delivery a connection can promote.
public struct BoostablePost: Codable, Sendable, Hashable {
  /// One delivery of the post, the account a boost is built from.
  public struct Delivery: Codable, Sendable, Hashable {
    public let accountId: String?
    public let platform: Platform?
    public let username: String?
    public let externalUrl: String?
    public let postedAt: Date?
  }

  public let id: String
  public let workspaceId: String?
  public let text: String?
  public let thumbnailUrl: String?
  public let deliveries: [Delivery]?
}

/// A Meta Ads login that reaches ad accounts and Pages.
public struct AdConnection: Codable, Sendable, Hashable {
  public let id: String
  /// `meta`.
  public let provider: String?
  /// `business` or `user`.
  public let authType: String?
  public let name: String?
  public let businessId: String?
  public let createdAt: Date?
  public let workspaceId: String?
}

/// One connection with the ad accounts and Pages its grant reaches.
public struct AdSource: Codable, Sendable, Hashable {
  /// An ad account, `act_…`.
  public struct AdAccount: Codable, Sendable, Hashable {
    public let id: String
    public let name: String?
    public let currency: String?
    /// The platform's account status code; 1 is active.
    public let status: Int?
  }

  /// A Facebook Page, with its linked Instagram user when there is one.
  public struct Page: Codable, Sendable, Hashable {
    public let id: String
    public let name: String?
    public let instagramUserId: String?
  }

  public let connectionId: String?
  public let name: String?
  public let workspaceId: String?
  public let adAccounts: [AdAccount]?
  public let pages: [Page]?
  /// Set when the platform refused the listing, usually a revoked grant.
  public let error: String?
}

/// A custom audience on an ad account.
public struct Audience: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let subtype: String?
  public let description: String?
  public let sizeLower: Int?
  public let sizeUpper: Int?
  public let deliveryStatus: String?
  public let createdAt: String?
}

/// A tracking pixel a website audience can be built from.
public struct AudiencePixel: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
}

/// The answer to ``AdsResource/audiences(_:)``.
public struct AudiencesResult: Codable, Sendable, Hashable {
  public let audiences: [Audience]?
  public let pixels: [AudiencePixel]?
  public let workspaceId: String?
}

/// One hit from the targeting catalogue.
public struct TargetingOption: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let detail: String?
}

/// An Instant Form on a Page.
public struct LeadForm: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let status: String?
  public let leadsCount: Int?
  public let createdAt: String?
  public let questions: [String]?
}

/// One connection's Page with its Instant Forms.
public struct LeadFormSource: Codable, Sendable, Hashable {
  public let connectionId: String?
  public let connectionName: String?
  public let pageId: String?
  public let pageName: String?
  public let forms: [LeadForm]?
  public let error: String?
  public let workspaceId: String?
}

/// One submission of an Instant Form.
public struct Lead: Codable, Sendable, Hashable {
  /// One answered question.
  public struct Field: Codable, Sendable, Hashable {
    public let name: String?
    public let values: [String]?
  }

  public let id: String
  public let createdAt: String?
  public let fields: [Field]?
  public let adName: String?
  public let campaignName: String?
  public let platform: String?
  public let isOrganic: Bool?
}

/// One page of leads. Pass `nextCursor` back as `after` for the next.
public struct LeadsPage: Codable, Sendable, Hashable {
  public let leads: [Lead]?
  public let nextCursor: String?
}

/// The Meta login URL ``AdsResource/authorizeMeta(_:)`` hands back.
public struct MetaAdsAuthorization: Codable, Sendable, Hashable {
  public let url: String
}

/// The audience ``AdsResource/createAudience(_:)`` made.
public struct CreatedAudience: Codable, Sendable, Hashable {
  public let id: String?
  /// Emails the platform accepted.
  public let added: Int?
}

/// The form ``AdsResource/createLeadForm(_:)`` made.
public struct CreatedLeadForm: Codable, Sendable, Hashable {
  public let id: String?
}

/// The body of ``AdsResource/authorizeMeta(_:)``.
public struct ConnectMetaAdsRequest: Codable, Sendable {
  public var workspaceId: String
  public var method: MetaAdsAuthMethod?
  /// Dashboard path to land on after the platform redirects back.
  public var returnTo: String?

  public init(workspaceId: String, method: MetaAdsAuthMethod? = nil, returnTo: String? = nil) {
    self.workspaceId = workspaceId
    self.method = method
    self.returnTo = returnTo
  }
}

/// The body of ``AdsResource/boost(_:)``. The boost starts paused unless
/// `paused` is `false`.
public struct BoostPostRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  /// A published FoPost post.
  public var postId: String
  /// The account the post was delivered to.
  public var accountId: String
  public var name: String
  public var goal: AdGoal
  public var budget: AdBudget
  public var targeting: AdTargeting
  /// Create the boost paused; set to `false` to go live at once.
  public var paused: Bool?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, postId: String,
    accountId: String, name: String, goal: AdGoal, budget: AdBudget, targeting: AdTargeting,
    paused: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.postId = postId
    self.accountId = accountId
    self.name = name
    self.goal = goal
    self.budget = budget
    self.targeting = targeting
    self.paused = paused
  }
}

/// The body of ``AdsResource/create(_:)``. The ad starts paused unless
/// `paused` is `false`.
public struct CreateAdRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  /// The Facebook Page the ad is published from.
  public var pageId: String
  public var name: String
  public var goal: AdGoal
  public var budget: AdBudget
  public var targeting: AdTargeting
  public var text: String
  public var headline: String?
  public var destinationUrl: String?
  /// A media library asset URL.
  public var mediaUrl: String?
  /// Create the ad paused; set to `false` to go live at once.
  public var paused: Bool?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, pageId: String, name: String,
    goal: AdGoal, budget: AdBudget, targeting: AdTargeting, text: String,
    headline: String? = nil, destinationUrl: String? = nil, mediaUrl: String? = nil,
    paused: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.pageId = pageId
    self.name = name
    self.goal = goal
    self.budget = budget
    self.targeting = targeting
    self.text = text
    self.headline = headline
    self.destinationUrl = destinationUrl
    self.mediaUrl = mediaUrl
    self.paused = paused
  }
}

struct SetAdStatusRequest: Codable, Sendable {
  var status: AdStatus
}

/// How a custom audience is built. Encodes as `{ "subtype": ..., ... }`.
public enum AudienceSpec: Codable, Sendable, Hashable {
  /// A list of email addresses the platform hashes and matches.
  case custom(emails: [String]? = nil)
  /// People who resemble an existing audience in one country.
  case lookalike(originAudienceId: String, country: String, ratio: Double? = nil)
  /// Visitors a pixel saw, optionally narrowed to URLs containing a string.
  case website(pixelId: String, retentionDays: Int? = nil, urlContains: String? = nil)

  enum CodingKeys: String, CodingKey {
    case subtype, emails, originAudienceId, country, ratio, pixelId, retentionDays, urlContains
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let subtype = try container.decode(String.self, forKey: .subtype)
    switch subtype {
    case "CUSTOM":
      self = .custom(emails: try container.decodeIfPresent([String].self, forKey: .emails))
    case "LOOKALIKE":
      self = .lookalike(
        originAudienceId: try container.decode(String.self, forKey: .originAudienceId),
        country: try container.decode(String.self, forKey: .country),
        ratio: try container.decodeIfPresent(Double.self, forKey: .ratio))
    case "WEBSITE":
      self = .website(
        pixelId: try container.decode(String.self, forKey: .pixelId),
        retentionDays: try container.decodeIfPresent(Int.self, forKey: .retentionDays),
        urlContains: try container.decodeIfPresent(String.self, forKey: .urlContains))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .subtype, in: container, debugDescription: "Unknown audience subtype \(subtype)")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .custom(let emails):
      try container.encode("CUSTOM", forKey: .subtype)
      try container.encodeIfPresent(emails, forKey: .emails)
    case .lookalike(let originAudienceId, let country, let ratio):
      try container.encode("LOOKALIKE", forKey: .subtype)
      try container.encode(originAudienceId, forKey: .originAudienceId)
      try container.encode(country, forKey: .country)
      try container.encodeIfPresent(ratio, forKey: .ratio)
    case .website(let pixelId, let retentionDays, let urlContains):
      try container.encode("WEBSITE", forKey: .subtype)
      try container.encode(pixelId, forKey: .pixelId)
      try container.encodeIfPresent(retentionDays, forKey: .retentionDays)
      try container.encodeIfPresent(urlContains, forKey: .urlContains)
    }
  }
}

/// The body of ``AdsResource/createAudience(_:)``.
public struct CreateAudienceRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String
  public var description: String?
  public var spec: AudienceSpec

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, name: String,
    description: String? = nil, spec: AudienceSpec
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
    self.description = description
    self.spec = spec
  }
}

/// The body of ``AdsResource/createLeadForm(_:)``.
public struct CreateLeadFormRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The Facebook Page id.
  public var pageId: String
  public var name: String
  public var questions: [LeadFormQuestion]
  public var privacyPolicyUrl: String
  public var thankYouMessage: String
  public var followUpUrl: String?

  public init(
    workspaceId: String, connectionId: String, pageId: String, name: String,
    questions: [LeadFormQuestion], privacyPolicyUrl: String, thankYouMessage: String,
    followUpUrl: String? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.pageId = pageId
    self.name = name
    self.questions = questions
    self.privacyPolicyUrl = privacyPolicyUrl
    self.thankYouMessage = thankYouMessage
    self.followUpUrl = followUpUrl
  }
}

/// Narrows ``AdsResource/audiences(_:)`` to one ad account on one connection.
public struct AudiencesParams: Sendable {
  public var connectionID: String
  public var adAccountID: String
  public var workspaceID: String?

  public init(connectionID: String, adAccountID: String, workspaceID: String? = nil) {
    self.connectionID = connectionID
    self.adAccountID = adAccountID
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("ad_account_id", adAccountID)
    return query
  }
}

/// What ``AdsResource/searchTargeting(_:)`` looks for.
public struct TargetingSearchParams: Sendable {
  public var connectionID: String
  public var type: TargetingSearchType
  public var q: String?
  public var workspaceID: String?

  public init(
    connectionID: String, type: TargetingSearchType, q: String? = nil, workspaceID: String? = nil
  ) {
    self.connectionID = connectionID
    self.type = type
    self.q = q
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("type", type.rawValue)
    query.add("q", q)
    return query
  }
}

/// Which Page's form ``AdsResource/leads(formID:_:)`` reads, and from where.
public struct LeadsParams: Sendable {
  public var connectionID: String
  public var pageID: String
  /// The `nextCursor` of the previous page.
  public var after: String?
  public var workspaceID: String?

  public init(
    connectionID: String, pageID: String, after: String? = nil, workspaceID: String? = nil
  ) {
    self.connectionID = connectionID
    self.pageID = pageID
    self.after = after
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("page_id", pageID)
    query.add("after", after)
    return query
  }
}
