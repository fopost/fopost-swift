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
  /// Query string appended to every link in the ad, e.g.
  /// `utm_source=meta&utm_medium=paid`.
  public var urlTags: String?
  /// A post already live on the network, from ``AdsResource/sparkPosts(_:)``.
  /// Runs it as a Spark ad, so `text`, `headline` and `mediaUrl` are ignored.
  /// Needs the network's `sparkAds` capability.
  public var sparkPostId: String?
  /// Create the ad paused; set to `false` to go live at once.
  public var paused: Bool?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, pageId: String, name: String,
    goal: AdGoal, budget: AdBudget, targeting: AdTargeting, text: String,
    headline: String? = nil, destinationUrl: String? = nil, mediaUrl: String? = nil,
    urlTags: String? = nil, sparkPostId: String? = nil, paused: Bool? = nil
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
    self.sparkPostId = sparkPostId
    self.urlTags = urlTags
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

/// The level of an object in an ad account's campaign tree.
public struct AdObjectLevel: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let campaign: Self = "campaign"
  public static let adSet: Self = "ad_set"
  public static let ad: Self = "ad"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.campaign, .adSet, .ad]
}

/// How an insights report is split.
public struct AdInsightsBreakdown: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let age: Self = "age"
  public static let gender: Self = "gender"
  public static let placement: Self = "placement"
  public static let country: Self = "country"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.age, .gender, .placement, .country]
}

/// The shape of a creative.
public struct AdCreativeFormat: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let image: Self = "image"
  public static let video: Self = "video"
  public static let carousel: Self = "carousel"
  public static let post: Self = "post"
  public static let other: Self = "other"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.image, .video, .carousel, .post, .other]
}

/// The button on a creative.
public struct AdCallToAction: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let learnMore: Self = "LEARN_MORE"
  public static let shopNow: Self = "SHOP_NOW"
  public static let signUp: Self = "SIGN_UP"
  public static let subscribe: Self = "SUBSCRIBE"
  public static let contactUs: Self = "CONTACT_US"
  public static let download: Self = "DOWNLOAD"
  public static let getOffer: Self = "GET_OFFER"
  public static let bookNow: Self = "BOOK_NOW"
  public static let applyNow: Self = "APPLY_NOW"
  public static let watchMore: Self = "WATCH_MORE"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [
    .learnMore, .shopNow, .signUp, .subscribe, .contactUs, .download, .getOffer, .bookNow,
    .applyNow, .watchMore,
  ]
}

/// An ad inside an ad set, by Meta's id. Read live, never stored.
public struct NetworkAd: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let campaignId: String?
  public let adSetId: String?
  public let creativeId: String?
  public let status: String?
  public let effectiveStatus: String?
  public let createdAt: String?
}

/// An ad set, by Meta's id. Read live, never stored.
public struct AdSet: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let campaignId: String?
  public let status: String?
  public let effectiveStatus: String?
  public let budgetMinor: Int?
  public let budgetType: AdBudgetType?
  public let endAt: String?
  public let optimizationGoal: String?
  public let createdAt: String?
  /// Only in ``AdsResource/accountTree(_:connectionID:workspaceID:)``.
  public let ads: [NetworkAd]?
}

/// A campaign, by Meta's id. Read live, never stored.
public struct AdCampaign: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  /// `ACTIVE`, `PAUSED`, `DELETED` or `ARCHIVED`.
  public let status: String?
  public let effectiveStatus: String?
  public let objective: String?
  /// `nil` when the budget lives on the ad sets.
  public let budgetMinor: Int?
  public let budgetType: AdBudgetType?
  public let createdAt: String?
  /// Only in ``AdsResource/accountTree(_:connectionID:workspaceID:)``.
  public let adSets: [AdSet]?
}

/// An ad account's campaigns, each with its ad sets and their ads.
public struct AdAccountTree: Codable, Sendable, Hashable {
  public let adAccountId: String?
  public let currency: String?
  public let workspaceId: String?
  public let campaigns: [AdCampaign]?
}

/// The id of the copy a duplicate call made.
public struct DuplicatedAdObject: Codable, Sendable, Hashable {
  public let id: String?
}

/// One object's outcome in ``AdsResource/bulkSetStatus(_:)``.
public struct BulkAdStatusResult: Codable, Sendable, Hashable {
  public let id: String
  public let level: AdObjectLevel?
  public let ok: Bool?
  public let error: String?
}

/// A creative in an ad account's library.
public struct AdCreative: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let format: AdCreativeFormat?
  public let status: String?
  public let title: String?
  public let body: String?
  public let link: String?
  public let thumbnailUrl: String?
  public let callToAction: String?
  public let urlTags: String?
}

/// The answer to ``AdsResource/creatives(connectionID:adAccountID:workspaceID:)``.
public struct AdCreativesResult: Codable, Sendable, Hashable {
  public let creatives: [AdCreative]?
  public let workspaceId: String?
}

/// How many emails ``AdsResource/addAudienceUsers(_:emails:workspaceID:connectionID:)`` sent.
public struct AddedAudienceUsers: Codable, Sendable, Hashable {
  public let added: Int?
}

/// The audience size Meta estimates for a targeting spec.
public struct ReachEstimate: Codable, Sendable, Hashable {
  public let lower: Int?
  public let upper: Int?
  /// `false` while Meta is still computing the estimate.
  public let ready: Bool?
}

/// Delivery figures for a date range.
public struct InsightsMetrics: Codable, Sendable, Hashable {
  public let impressions: Int?
  public let reach: Int?
  public let clicks: Int?
  /// Account currency, minor units.
  public let spendMinor: Int?
  /// Clicks per impression, as a percentage.
  public let ctr: Double?
  public let leads: Int?
}

/// Insights for one object over a date range.
public struct AdInsightsReport: Codable, Sendable, Hashable {
  /// One slice of a breakdown.
  public struct BreakdownRow: Codable, Sendable, Hashable {
    public let key: String?
    public let metrics: InsightsMetrics?
  }

  /// One day of a daily report.
  public struct TimelineRow: Codable, Sendable, Hashable {
    public let date: String?
    public let metrics: InsightsMetrics?
  }

  public let objectId: String?
  public let currency: String?
  public let since: String?
  public let until: String?
  public let breakdownBy: AdInsightsBreakdown?
  public let totals: InsightsMetrics?
  public let breakdown: [BreakdownRow]?
  public let timeline: [TimelineRow]?
}

/// An Instant Form with its settings.
public struct LeadFormDetail: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let status: String?
  public let leadsCount: Int?
  public let createdAt: String?
  public let questions: [String]?
  public let pageId: String?
  public let privacyPolicyUrl: String?
  public let locale: String?
}

/// A lead stored from a subscribed Page.
public struct FeedLead: Codable, Sendable, Hashable {
  public let id: String
  /// Meta's lead id.
  public let leadId: String?
  public let connectionId: String?
  public let pageId: String?
  public let formId: String?
  public let adId: String?
  public let adName: String?
  public let campaignName: String?
  public let platform: String?
  public let isOrganic: Bool?
  public let fields: [Lead.Field]?
  public let submittedAt: Date?
  public let workspaceId: String?
}

/// One page of the leads feed. Pass `nextCursor` back as `cursor` for the next.
public struct LeadsFeedPage: Codable, Sendable, Hashable {
  public let leads: [FeedLead]?
  public let nextCursor: String?
}

/// A Page whose new leads are stored as they arrive.
public struct LeadPage: Codable, Sendable, Hashable {
  public let connectionId: String?
  public let pageId: String
  public let pageName: String?
  public let createdAt: Date?
  public let workspaceId: String?
}

/// The answer to ``AdsResource/subscribeLeadPage(_:)``.
public struct SubscribedLeadPage: Codable, Sendable, Hashable {
  public let pageId: String?
  /// Past leads stored on subscribing.
  public let backfilled: Int?
}

/// The body of ``AdsResource/createCampaign(_:)``. The campaign starts paused
/// unless `paused` is `false`.
public struct CreateAdCampaignRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String
  public var goal: AdGoal
  public var paused: Bool?
  /// Hands targeting and creative rotation to the network. Needs its
  /// `smartPlus` capability.
  public var smartPlus: Bool?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, name: String, goal: AdGoal,
    paused: Bool? = nil, smartPlus: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
    self.goal = goal
    self.paused = paused
    self.smartPlus = smartPlus
  }
}

/// The body of ``AdsResource/updateCampaign(_:_:workspaceID:connectionID:)``.
public struct UpdateAdCampaignRequest: Codable, Sendable {
  public var name: String?
  public var status: AdStatus?

  public init(name: String? = nil, status: AdStatus? = nil) {
    self.name = name
    self.status = status
  }
}

/// The body of ``AdsResource/createAdSet(_:)``. The ad set starts paused
/// unless `paused` is `false`.
public struct CreateAdSetRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  public var campaignId: String
  /// The Page the ads in this set run as.
  public var pageId: String
  public var name: String
  public var goal: AdGoal
  public var budget: AdBudget
  public var targeting: AdTargeting
  public var paused: Bool?

  public init(
    workspaceId: String, connectionId: String, campaignId: String, pageId: String, name: String,
    goal: AdGoal, budget: AdBudget, targeting: AdTargeting, paused: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.campaignId = campaignId
    self.pageId = pageId
    self.name = name
    self.goal = goal
    self.budget = budget
    self.targeting = targeting
    self.paused = paused
  }
}

/// The body of ``AdsResource/updateAdSet(_:_:workspaceID:connectionID:)``.
public struct UpdateAdSetRequest: Codable, Sendable {
  public var name: String?
  public var status: AdStatus?
  /// New budget in minor units; the budget type set at creation stays.
  public var budgetMinor: Int?
  public var endAt: Date?
  public var targeting: AdTargeting?

  public init(
    name: String? = nil, status: AdStatus? = nil, budgetMinor: Int? = nil, endAt: Date? = nil,
    targeting: AdTargeting? = nil
  ) {
    self.name = name
    self.status = status
    self.budgetMinor = budgetMinor
    self.endAt = endAt
    self.targeting = targeting
  }
}

/// The body of ``AdsResource/createNetworkAd(_:)``. The ad starts paused
/// unless `paused` is `false`.
public struct CreateNetworkAdRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  public var adSetId: String
  /// From ``AdsResource/createCreative(_:)`` or the creative library.
  public var creativeId: String
  public var name: String
  public var paused: Bool?

  public init(
    workspaceId: String, connectionId: String, adSetId: String, creativeId: String, name: String,
    paused: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adSetId = adSetId
    self.creativeId = creativeId
    self.name = name
    self.paused = paused
  }
}

/// The body of ``AdsResource/updateNetworkAd(_:_:workspaceID:connectionID:)``.
public struct UpdateNetworkAdRequest: Codable, Sendable {
  public var name: String?
  public var status: AdStatus?
  public var creativeId: String?

  public init(name: String? = nil, status: AdStatus? = nil, creativeId: String? = nil) {
    self.name = name
    self.status = status
    self.creativeId = creativeId
  }
}

/// One object ``AdsResource/bulkSetStatus(_:)`` acts on.
public struct AdObjectRef: Codable, Sendable, Hashable {
  /// Meta's id.
  public var id: String
  public var level: AdObjectLevel

  public init(id: String, level: AdObjectLevel) {
    self.id = id
    self.level = level
  }
}

/// The body of ``AdsResource/bulkSetStatus(_:)``.
public struct BulkAdStatusRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  public var status: AdStatus
  /// One to 50 objects.
  public var objects: [AdObjectRef]

  public init(
    workspaceId: String, connectionId: String, status: AdStatus, objects: [AdObjectRef]
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.status = status
    self.objects = objects
  }
}

/// One card of a carousel creative.
public struct AdCreativeCard: Codable, Sendable, Hashable {
  /// A media library image.
  public var mediaUrl: String
  public var destinationUrl: String?
  public var headline: String?
  public var description: String?

  public init(
    mediaUrl: String, destinationUrl: String? = nil, headline: String? = nil,
    description: String? = nil
  ) {
    self.mediaUrl = mediaUrl
    self.destinationUrl = destinationUrl
    self.headline = headline
    self.description = description
  }
}

/// The body of ``AdsResource/createCreative(_:)``: an image, a video (needs
/// `mediaUrl`), or a carousel (needs `cards`).
public struct CreateAdCreativeRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var pageId: String
  public var name: String
  public var format: AdCreativeFormat
  /// Primary text.
  public var text: String
  public var headline: String?
  public var destinationUrl: String?
  /// Defaults to `LEARN_MORE`.
  public var callToAction: AdCallToAction?
  /// Query string appended to every link in the ad.
  public var urlTags: String?
  /// A media library asset URL: the image, or the video.
  public var mediaUrl: String?
  /// A video's poster frame, as a library image.
  public var thumbnailMediaUrl: String?
  public var cards: [AdCreativeCard]?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, pageId: String, name: String,
    format: AdCreativeFormat, text: String, headline: String? = nil,
    destinationUrl: String? = nil, callToAction: AdCallToAction? = nil, urlTags: String? = nil,
    mediaUrl: String? = nil, thumbnailMediaUrl: String? = nil, cards: [AdCreativeCard]? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.pageId = pageId
    self.name = name
    self.format = format
    self.text = text
    self.headline = headline
    self.destinationUrl = destinationUrl
    self.callToAction = callToAction
    self.urlTags = urlTags
    self.mediaUrl = mediaUrl
    self.thumbnailMediaUrl = thumbnailMediaUrl
    self.cards = cards
  }
}

/// The body of ``AdsResource/updateAudience(_:_:workspaceID:connectionID:)``.
public struct UpdateAudienceRequest: Codable, Sendable {
  public var name: String?
  public var description: String?

  public init(name: String? = nil, description: String? = nil) {
    self.name = name
    self.description = description
  }
}

/// The body of ``AdsResource/estimateReach(_:)``.
public struct ReachEstimateRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var pageId: String
  public var targeting: AdTargeting

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, pageId: String,
    targeting: AdTargeting
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.pageId = pageId
    self.targeting = targeting
  }
}

/// The body of ``AdsResource/subscribeLeadPage(_:)``.
public struct SubscribeLeadPageRequest: Codable, Sendable {
  public var workspaceId: String
  /// A Meta Ads connection in the workspace.
  public var connectionId: String
  public var pageId: String

  public init(workspaceId: String, connectionId: String, pageId: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.pageId = pageId
  }
}

struct DuplicateAdObjectRequest: Codable, Sendable {
  var paused: Bool?
}

struct AddAudienceUsersRequest: Codable, Sendable {
  var emails: [String]
}

struct ArchiveLeadFormRequest: Codable, Sendable {
  var workspaceId: String
  var connectionId: String
  var pageId: String
}

/// What ``AdsResource/insights(_:)`` reads: any campaign, ad set, or ad by
/// Meta's id, between two `YYYY-MM-DD` dates.
public struct InsightsParams: Sendable {
  public var connectionID: String
  public var objectID: String
  public var since: String
  public var until: String
  public var breakdown: AdInsightsBreakdown?
  /// Adds a per-day `timeline`.
  public var daily: Bool?
  public var workspaceID: String?

  public init(
    connectionID: String, objectID: String, since: String, until: String,
    breakdown: AdInsightsBreakdown? = nil, daily: Bool? = nil, workspaceID: String? = nil
  ) {
    self.connectionID = connectionID
    self.objectID = objectID
    self.since = since
    self.until = until
    self.breakdown = breakdown
    self.daily = daily
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("object_id", objectID)
    query.add("since", since)
    query.add("until", until)
    query.add("breakdown", breakdown?.rawValue)
    query.add("daily", daily)
    return query
  }
}

/// What ``AdsResource/adInsights(_:_:)`` reads for a FoPost ad, between two
/// `YYYY-MM-DD` dates.
public struct AdInsightsParams: Sendable {
  public var workspaceID: String
  public var since: String
  public var until: String
  public var breakdown: AdInsightsBreakdown?
  /// Adds a per-day `timeline`.
  public var daily: Bool?

  public init(
    workspaceID: String, since: String, until: String, breakdown: AdInsightsBreakdown? = nil,
    daily: Bool? = nil
  ) {
    self.workspaceID = workspaceID
    self.since = since
    self.until = until
    self.breakdown = breakdown
    self.daily = daily
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("since", since)
    query.add("until", until)
    query.add("breakdown", breakdown?.rawValue)
    query.add("daily", daily)
    return query
  }
}

/// Filters for ``AdsResource/leadsFeed(_:)``.
public struct LeadsFeedParams: Sendable {
  public var workspaceID: String?
  public var formID: String?
  public var pageID: String?
  /// The `nextCursor` of the previous page.
  public var cursor: String?
  /// 1 to 100.
  public var limit: Int?

  public init(
    workspaceID: String? = nil, formID: String? = nil, pageID: String? = nil,
    cursor: String? = nil, limit: Int? = nil
  ) {
    self.workspaceID = workspaceID
    self.formID = formID
    self.pageID = pageID
    self.cursor = cursor
    self.limit = limit
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("form_id", formID)
    query.add("page_id", pageID)
    query.add("cursor", cursor)
    query.add("limit", limit)
    return query
  }
}

// MARK: - Identities, Spark posts, conversions and ad comments

/// A Business Center, or the network's equivalent grouping of ad accounts.
public struct AdBusinessCenter: Codable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var role: String?
}

/// The account an ad runs as. Meta calls it a Page, TikTok an identity; an
/// identity id is what every route calls a `pageId`.
public struct AdIdentity: Codable, Sendable, Identifiable {
  public var id: String
  /// The network's own identity kind, e.g. `CUSTOMIZED_USER`.
  public var type: String
  public var name: String
  public var avatarUrl: String?
}

/// A post already live on the network, offered as the source of a Spark ad.
public struct SparkPost: Codable, Sendable, Identifiable {
  public var id: String
  public var identityId: String
  public var caption: String?
  public var thumbnailUrl: String?
  public var createdAt: String?
  public var views: Int?
}

/// A comment on an ad, read live from the network and never stored.
public struct AdComment: Codable, Sendable, Identifiable {
  public var id: String
  public var adId: String?
  public var text: String
  public var authorName: String?
  public var authorAvatarUrl: String?
  public var createdAt: String?
  public var likes: Int
  public var replyCount: Int
  public var hidden: Bool
  /// The comment this one answers, when it is not on the ad itself.
  public var parentId: String?
}

/// One page of an ad's comments. Pass `nextCursor` back as `after`.
public struct AdCommentsPage: Codable, Sendable {
  public var comments: [AdComment]
  public var nextCursor: String?
}

/// Which identity's posts ``AdsResource/sparkPosts(_:)`` reads.
public struct SparkPostsParams: Sendable {
  public var connectionID: String
  public var adAccountID: String
  public var identityID: String
  public var workspaceID: String?

  public init(
    connectionID: String, adAccountID: String, identityID: String, workspaceID: String? = nil
  ) {
    self.connectionID = connectionID
    self.adAccountID = adAccountID
    self.identityID = identityID
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("ad_account_id", adAccountID)
    query.add("identity_id", identityID)
    return query
  }
}

/// Which ad's comments ``AdsResource/comments(_:)`` reads, and from where.
public struct AdCommentsParams: Sendable {
  public var connectionID: String
  public var adID: String
  /// The previous page's `nextCursor`.
  public var after: String?
  public var workspaceID: String?

  public init(
    connectionID: String, adID: String, after: String? = nil, workspaceID: String? = nil
  ) {
    self.connectionID = connectionID
    self.adID = adID
    self.after = after
    self.workspaceID = workspaceID
  }

  var query: Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    query.add("ad_id", adID)
    query.add("after", after)
    return query
  }
}

/// One offline conversion. Identifiers are hashed by the API before anything
/// leaves FoPost.
public struct ConversionEvent: Codable, Sendable {
  public var eventName: String
  /// ISO 8601.
  public var occurredAt: String
  public var email: String?
  public var phone: String?
  /// Account currency, minor units.
  public var valueMinor: Int?
  public var currency: String?
  public var orderId: String?

  public init(
    eventName: String, occurredAt: String, email: String? = nil, phone: String? = nil,
    valueMinor: Int? = nil, currency: String? = nil, orderId: String? = nil
  ) {
    self.eventName = eventName
    self.occurredAt = occurredAt
    self.email = email
    self.phone = phone
    self.valueMinor = valueMinor
    self.currency = currency
    self.orderId = orderId
  }
}

/// The body of ``AdsResource/uploadConversions(_:)``.
public struct UploadConversionsRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var adAccountId: String
  /// A pixel the ad account owns, from ``AdsResource/audiences(_:)``.
  public var pixelId: String
  /// Up to 1000 per call.
  public var events: [ConversionEvent]

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, pixelId: String,
    events: [ConversionEvent]
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.pixelId = pixelId
    self.events = events
  }
}

/// How many events the network accepted.
public struct ConversionsAccepted: Codable, Sendable {
  public var accepted: Int
}

/// The reply's id on the network.
public struct AdCommentReply: Codable, Sendable {
  public var replyId: String
}

/// Scopes a comment write; the comment id travels in the path.
public struct AdCommentRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var adId: String
  /// The reply, on ``AdsResource/replyToComment(_:_:)`` only.
  public var text: String?
  /// The new state, on ``AdsResource/setCommentHidden(_:_:)`` only.
  public var hidden: Bool?

  public init(
    workspaceId: String, connectionId: String, adId: String, text: String? = nil,
    hidden: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adId = adId
    self.text = text
    self.hidden = hidden
  }
}
