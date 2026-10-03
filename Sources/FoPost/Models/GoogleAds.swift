import Foundation

/// The connection and the Google Ads account a call runs against.
///
/// `customerId` is digits only and has to name an account the connection's
/// grant reaches: any other answers 404. `workspaceId` may be left out on a
/// read, and is required on a write.
///
/// An object id carries the account it belongs to, because a Google resource
/// name cannot ride in a URL path segment: `1234567890~campaign~55`,
/// `1234567890~adGroup~77`, `1234567890~ad~77~88`.
public struct GoogleAdsScope: Codable, Sendable, Hashable {
  public var workspaceId: String?
  public var connectionId: String
  public var customerId: String

  public init(workspaceId: String? = nil, connectionId: String, customerId: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.customerId = customerId
  }
}

/// How closely a search has to match a keyword.
public enum GoogleMatchType: String, Codable, Sendable {
  case exact = "EXACT"
  case phrase = "PHRASE"
  case broad = "BROAD"
}

/// A portfolio bid strategy.
public enum GoogleBidStrategyType: String, Codable, Sendable {
  case targetSpend = "TARGET_SPEND"
  case maximizeConversions = "MAXIMIZE_CONVERSIONS"
  case maximizeConversionValue = "MAXIMIZE_CONVERSION_VALUE"
  case targetCpa = "TARGET_CPA"
  case targetRoas = "TARGET_ROAS"
}

/// Where an asset renders.
public enum GoogleAssetFieldType: String, Codable, Sendable {
  case sitelink = "SITELINK"
  case callout = "CALLOUT"
  case structuredSnippet = "STRUCTURED_SNIPPET"
}

/// A day of the week on an ad schedule.
public enum GoogleDayOfWeek: String, Codable, Sendable {
  case monday = "MONDAY"
  case tuesday = "TUESDAY"
  case wednesday = "WEDNESDAY"
  case thursday = "THURSDAY"
  case friday = "FRIDAY"
  case saturday = "SATURDAY"
  case sunday = "SUNDAY"
}

/// What a conversion adjustment does to a conversion already counted.
public enum GoogleAdjustmentType: String, Codable, Sendable {
  case restatement = "RESTATEMENT"
  case retraction = "RETRACTION"
  case enhancement = "ENHANCEMENT"
}

/// A keyword on an ad group.
public struct GoogleKeyword: Codable, Sendable, Hashable {
  /// `<customerId>~keyword~<adGroupId>~<criterionId>`
  public let id: String
  public let adGroupId: String?
  public let text: String?
  public let matchType: String?
  public let status: String?
  /// The account's currency, in minor units.
  public let cpcBidMinor: Int?
  public let negative: Bool?
}

/// A keyword idea, or the historical metrics of one.
public struct GoogleKeywordIdea: Codable, Sendable, Hashable {
  public let text: String?
  public let avgMonthlySearches: Int?
  public let competition: String?
  public let lowTopOfPageBidMinor: Int?
  public let highTopOfPageBidMinor: Int?
}

/// What someone actually searched, with the metrics it earned.
public struct GoogleSearchTerm: Codable, Sendable, Hashable {
  public let term: String?
  public let adGroupId: String?
  public let status: String?
  public let metrics: InsightsMetrics?
}

/// A portfolio bid strategy on the account.
public struct GoogleBidStrategy: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let type: String?
  public let status: String?
  public let campaignCount: Int?
}

/// One slot of a campaign's ad schedule.
public struct GoogleAdScheduleSlot: Codable, Sendable, Hashable {
  public let id: String
  public let dayOfWeek: String?
  public let startHour: Int?
  public let endHour: Int?
  public let bidModifier: Double?
}

/// A negative keyword list.
public struct GoogleSharedSet: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let type: String?
  public let memberCount: Int?
}

/// A sitelink, callout, or structured snippet.
public struct GoogleAsset: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let type: String?
  /// What a sitelink, callout, or snippet renders.
  public let text: String?
  public let finalUrl: String?
}

/// Where an asset is attached; one with no links serves nowhere.
public struct GoogleAssetLink: Codable, Sendable, Hashable {
  public let id: String
  public let assetId: String?
  public let level: String?
  public let ownerId: String?
  public let fieldType: String?
  public let status: String?
}

/// The account's assets with the links that place them.
public struct GoogleAssets: Codable, Sendable, Hashable {
  public let assets: [GoogleAsset]?
  public let links: [GoogleAssetLink]?
}

/// A Performance Max asset group.
public struct GoogleAssetGroup: Codable, Sendable, Hashable {
  public let id: String
  public let campaignId: String?
  public let name: String?
  public let status: String?
  public let finalUrls: [String]?
}

/// A lead from Local Services Ads, read live and never stored.
public struct GoogleLocalServicesLead: Codable, Sendable, Hashable {
  public let id: String
  public let category: String?
  public let service: String?
  public let contactName: String?
  public let phone: String?
  public let email: String?
  public let status: String?
  public let type: String?
  public let createdAt: String?
}

/// A conversion action on the account.
public struct GoogleConversionAction: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let category: String?
  public let status: String?
  public let type: String?
  public let countingType: String?
  public let valueMinor: Int?
}

/// Rows exactly as Google returns them.
public struct GoogleQueryResult: Codable, Sendable {
  public let rows: [JSONValue]?
}

/// The id a create or update answers with.
public struct GoogleCreated: Codable, Sendable, Hashable {
  public let id: String
}

/// How many rows an upload accepted.
public struct GoogleUploaded: Codable, Sendable, Hashable {
  public let uploaded: Int?
}

/// How many keywords a negative list took.
public struct GoogleAdded: Codable, Sendable, Hashable {
  public let added: Int?
}

/// How many slots a schedule now has.
public struct GoogleSlots: Codable, Sendable, Hashable {
  public let slots: Int?
}

// ─── Request bodies ───────────────────────────────────────────────

/// Start a Google Ads connection.
public struct ConnectGoogleAdsRequest: Codable, Sendable {
  public var workspaceId: String
  /// Dashboard path to land on after Google redirects back.
  public var returnTo: String?

  public init(workspaceId: String, returnTo: String? = nil) {
    self.workspaceId = workspaceId
    self.returnTo = returnTo
  }
}

/// Add a keyword to an ad group.
public struct CreateGoogleKeywordRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var adGroupId: String
  public var text: String
  public var matchType: GoogleMatchType
  /// The account's currency, in minor units.
  public var cpcBidMinor: Int?

  public init(
    scope: GoogleAdsScope, adGroupId: String, text: String, matchType: GoogleMatchType,
    cpcBidMinor: Int? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.adGroupId = adGroupId
    self.text = text
    self.matchType = matchType
    self.cpcBidMinor = cpcBidMinor
  }
}

/// Pause, resume, or rebid a keyword.
public struct UpdateGoogleKeywordRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  /// `active` or `paused`.
  public var status: String?
  public var cpcBidMinor: Int?

  public init(scope: GoogleAdsScope, status: String? = nil, cpcBidMinor: Int? = nil) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.status = status
    self.cpcBidMinor = cpcBidMinor
  }
}

/// Ask for keyword ideas from seeds, a landing page, or both.
public struct GoogleKeywordIdeasRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var seeds: [String]?
  public var url: String?
  public var languageId: String?
  public var geoTargetIds: [String]?

  public init(
    scope: GoogleAdsScope, seeds: [String]? = nil, url: String? = nil, languageId: String? = nil,
    geoTargetIds: [String]? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.seeds = seeds
    self.url = url
    self.languageId = languageId
    self.geoTargetIds = geoTargetIds
  }
}

/// Read the historical metrics of keywords you already have.
public struct GoogleKeywordMetricsRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var keywords: [String]

  public init(scope: GoogleAdsScope, keywords: [String]) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.keywords = keywords
  }
}

/// Add a portfolio bid strategy.
public struct CreateGoogleBidStrategyRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var name: String
  public var type: GoogleBidStrategyType
  public var targetMinor: Int?

  public init(
    scope: GoogleAdsScope, name: String, type: GoogleBidStrategyType, targetMinor: Int? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.name = name
    self.type = type
    self.targetMinor = targetMinor
  }
}

/// One slot to put on a campaign's schedule.
public struct GoogleAdScheduleInput: Codable, Sendable, Hashable {
  public var dayOfWeek: GoogleDayOfWeek
  public var startHour: Int
  public var endHour: Int
  public var bidModifier: Double?

  public init(
    dayOfWeek: GoogleDayOfWeek, startHour: Int, endHour: Int, bidModifier: Double? = nil
  ) {
    self.dayOfWeek = dayOfWeek
    self.startHour = startHour
    self.endHour = endHour
    self.bidModifier = bidModifier
  }
}

/// Replace a campaign's schedule; Google has no partial edit for one.
public struct SetGoogleAdScheduleRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var campaignId: String
  public var slots: [GoogleAdScheduleInput]

  public init(scope: GoogleAdsScope, campaignId: String, slots: [GoogleAdScheduleInput]) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.campaignId = campaignId
    self.slots = slots
  }
}

/// Create a negative keyword list.
public struct CreateGoogleNegativeKeywordListRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var name: String

  public init(scope: GoogleAdsScope, name: String) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.name = name
  }
}

/// One keyword in a negative list.
public struct GoogleNegativeKeyword: Codable, Sendable, Hashable {
  public var text: String
  public var matchType: GoogleMatchType

  public init(text: String, matchType: GoogleMatchType) {
    self.text = text
    self.matchType = matchType
  }
}

/// Add keywords to a negative list.
public struct AddGoogleNegativeKeywordsRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var sharedSetId: String
  public var keywords: [GoogleNegativeKeyword]

  public init(scope: GoogleAdsScope, sharedSetId: String, keywords: [GoogleNegativeKeyword]) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.sharedSetId = sharedSetId
    self.keywords = keywords
  }
}

/// Put a negative keyword list on a campaign.
public struct AttachGoogleNegativeKeywordListRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var sharedSetId: String
  public var campaignId: String

  public init(scope: GoogleAdsScope, sharedSetId: String, campaignId: String) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.sharedSetId = sharedSetId
    self.campaignId = campaignId
  }
}

/// The asset to create.
public struct GoogleAssetSpec: Codable, Sendable, Hashable {
  /// `sitelink`, `callout`, or `snippet`.
  public var kind: String
  public var text: String?
  public var description1: String?
  public var description2: String?
  public var finalUrl: String?
  public var header: String?
  public var values: [String]?

  public static func sitelink(
    text: String, finalUrl: String, description1: String? = nil, description2: String? = nil
  ) -> GoogleAssetSpec {
    GoogleAssetSpec(
      kind: "sitelink", text: text, description1: description1, description2: description2,
      finalUrl: finalUrl, header: nil, values: nil)
  }

  public static func callout(text: String) -> GoogleAssetSpec {
    GoogleAssetSpec(
      kind: "callout", text: text, description1: nil, description2: nil, finalUrl: nil,
      header: nil, values: nil)
  }

  public static func snippet(header: String, values: [String]) -> GoogleAssetSpec {
    GoogleAssetSpec(
      kind: "snippet", text: nil, description1: nil, description2: nil, finalUrl: nil,
      header: header, values: values)
  }
}

/// Add an asset to the library.
public struct CreateGoogleAssetRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var spec: GoogleAssetSpec

  public init(scope: GoogleAdsScope, spec: GoogleAssetSpec) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.spec = spec
  }
}

/// Attach an asset to the account, or to one campaign.
public struct AttachGoogleAssetRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var assetId: String
  public var fieldType: GoogleAssetFieldType
  /// Attaches to the account when left out.
  public var campaignId: String?

  public init(
    scope: GoogleAdsScope, assetId: String, fieldType: GoogleAssetFieldType,
    campaignId: String? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.assetId = assetId
    self.fieldType = fieldType
    self.campaignId = campaignId
  }
}

/// Create a Performance Max asset group.
public struct CreateGoogleAssetGroupRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var campaignId: String
  public var name: String
  public var finalUrls: [String]
  /// `active` or `paused`; starts paused when left out.
  public var status: String?

  public init(
    scope: GoogleAdsScope, campaignId: String, name: String, finalUrls: [String],
    status: String? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.campaignId = campaignId
    self.name = name
    self.finalUrls = finalUrls
    self.status = status
  }
}

/// Rename, pause, or resume an asset group.
public struct UpdateGoogleAssetGroupRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var name: String?
  public var status: String?

  public init(scope: GoogleAdsScope, name: String? = nil, status: String? = nil) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.name = name
    self.status = status
  }
}

/// Create a conversion action.
public struct CreateGoogleConversionActionRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var name: String
  public var category: String
  public var valueMinor: Int?
  public var countingType: String?

  public init(
    scope: GoogleAdsScope, name: String, category: String, valueMinor: Int? = nil,
    countingType: String? = nil
  ) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.name = name
    self.category = category
    self.valueMinor = valueMinor
    self.countingType = countingType
  }
}

/// One offline conversion. One of `gclid`, `gbraid`, or `wbraid` is required:
/// it is what matches the click.
public struct GoogleClickConversion: Codable, Sendable, Hashable {
  public var gclid: String?
  public var gbraid: String?
  public var wbraid: String?
  public var conversionActionId: String
  /// `yyyy-MM-dd HH:mm:ss+|-HH:mm`, the only shape Google accepts.
  public var conversionDateTime: String
  public var valueMinor: Int?
  public var currencyCode: String?
  public var orderId: String?

  public init(
    conversionActionId: String, conversionDateTime: String, gclid: String? = nil,
    gbraid: String? = nil, wbraid: String? = nil, valueMinor: Int? = nil,
    currencyCode: String? = nil, orderId: String? = nil
  ) {
    self.conversionActionId = conversionActionId
    self.conversionDateTime = conversionDateTime
    self.gclid = gclid
    self.gbraid = gbraid
    self.wbraid = wbraid
    self.valueMinor = valueMinor
    self.currencyCode = currencyCode
    self.orderId = orderId
  }
}

/// Send offline conversions.
public struct UploadGoogleConversionsRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var conversions: [GoogleClickConversion]

  public init(scope: GoogleAdsScope, conversions: [GoogleClickConversion]) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.conversions = conversions
  }
}

/// Restate, retract, or enhance a conversion already counted.
public struct GoogleConversionAdjustment: Codable, Sendable, Hashable {
  public var conversionActionId: String
  public var adjustmentType: GoogleAdjustmentType
  public var adjustmentDateTime: String
  public var orderId: String?
  public var gclid: String?
  public var conversionDateTime: String?
  public var restatementValueMinor: Int?
  public var currencyCode: String?

  public init(
    conversionActionId: String, adjustmentType: GoogleAdjustmentType, adjustmentDateTime: String,
    orderId: String? = nil, gclid: String? = nil, conversionDateTime: String? = nil,
    restatementValueMinor: Int? = nil, currencyCode: String? = nil
  ) {
    self.conversionActionId = conversionActionId
    self.adjustmentType = adjustmentType
    self.adjustmentDateTime = adjustmentDateTime
    self.orderId = orderId
    self.gclid = gclid
    self.conversionDateTime = conversionDateTime
    self.restatementValueMinor = restatementValueMinor
    self.currencyCode = currencyCode
  }
}

/// Send conversion adjustments.
public struct UploadGoogleConversionAdjustmentsRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String
  public var adjustments: [GoogleConversionAdjustment]

  public init(scope: GoogleAdsScope, adjustments: [GoogleConversionAdjustment]) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.adjustments = adjustments
  }
}

/// A raw read-only GAQL SELECT. The account read is `customerId`, never
/// anything named inside `query`.
public struct GoogleQueryRequest: Codable, Sendable {
  public var workspaceId: String?
  public var connectionId: String
  public var customerId: String
  public var query: String

  public init(scope: GoogleAdsScope, query: String) {
    self.workspaceId = scope.workspaceId
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
    self.query = query
  }
}

/// The scope alone, for a delete that carries it in the body.
public struct GoogleAdsScopeRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var customerId: String

  public init(scope: GoogleAdsScope) {
    self.workspaceId = scope.workspaceId ?? ""
    self.connectionId = scope.connectionId
    self.customerId = scope.customerId
  }
}
