import Foundation

/// Where a messaging ad opens a conversation.
public struct MessagingDestination: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let messenger: Self = "messenger"
  public static let instagramDirect: Self = "instagram_direct"
  public static let whatsApp: Self = "whatsapp"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.messenger, .instagramDirect, .whatsApp]
}

/// How the ad platform reads a high-demand period's budget value.
public struct BudgetValueType: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let absolute: Self = "ABSOLUTE"
  public static let multiplier: Self = "MULTIPLIER"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.absolute, .multiplier]
}

// MARK: - Product catalogs

/// A product catalog on the connection's business portfolio, read live.
public struct ProductCatalog: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let vertical: String?
  public let productCount: Int?
}

/// The catalogs one connection reaches.
public struct ProductCatalogsResult: Codable, Sendable, Hashable {
  public let catalogs: [ProductCatalog]?
  public let workspaceId: String?
}

/// One product in a catalog. `priceMinor` is minor units of `currency`.
public struct CatalogProduct: Codable, Sendable, Hashable {
  public let id: String
  /// Your own key for the product.
  public let retailerId: String?
  public let name: String?
  public let description: String?
  public let availability: String?
  public let condition: String?
  public let priceMinor: Int?
  public let currency: String?
  public let imageUrl: String?
  public let url: String?
}

/// One page of catalog products; pass `nextCursor` back as `after`.
public struct CatalogProductsPage: Codable, Sendable, Hashable {
  public let products: [CatalogProduct]?
  public let nextCursor: String?
}

/// What a catalog product batch was accepted as.
public struct CatalogBatchResult: Codable, Sendable, Hashable {
  public let handles: [String]?
  /// Products sent in this batch.
  public let accepted: Int?
}

/// Keeps a catalog in step with a product file you host.
public struct ProductFeed: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  /// Set when the ad platform fetches the file on a schedule.
  public let url: String?
  public let schedule: String?
  public let createdAt: String?
}

/// One run the ad platform made of a product feed.
public struct ProductFeedUpload: Codable, Sendable, Hashable {
  public let id: String
  public let startedAt: String?
  public let endedAt: String?
  public let status: String?
  public let errorCount: Int?
  public let warningCount: Int?
}

/// The slice of a catalog one catalog ad runs from.
public struct ProductSet: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let productCount: Int?
}

/// One upsert or delete in a catalog batch, keyed by your own `retailerId`.
/// A delete needs only `op` and `retailerId`.
public struct CatalogProductWrite: Codable, Sendable, Hashable {
  /// `upsert` or `delete`.
  public var op: String
  public var retailerId: String
  public var name: String?
  public var description: String?
  public var url: String?
  public var imageUrl: String?
  /// Minor units of `currency`: 12900 with USD is $129.00.
  public var priceMinor: Int?
  public var currency: String?
  /// `in stock`, `out of stock`, `preorder`, and so on.
  public var availability: String?
  /// `new`, `refurbished` or `used`.
  public var condition: String?
  public var brand: String?

  /// Adds or replaces a product.
  public static func upsert(
    retailerId: String, name: String, url: String, imageUrl: String, priceMinor: Int,
    currency: String, description: String? = nil, availability: String? = nil,
    condition: String? = nil, brand: String? = nil
  ) -> Self {
    Self(
      op: "upsert", retailerId: retailerId, name: name, description: description, url: url,
      imageUrl: imageUrl, priceMinor: priceMinor, currency: currency, availability: availability,
      condition: condition, brand: brand)
  }

  /// Removes a product from the catalog.
  public static func delete(retailerId: String) -> Self {
    Self(op: "delete", retailerId: retailerId)
  }

  public init(
    op: String, retailerId: String, name: String? = nil, description: String? = nil,
    url: String? = nil, imageUrl: String? = nil, priceMinor: Int? = nil, currency: String? = nil,
    availability: String? = nil, condition: String? = nil, brand: String? = nil
  ) {
    self.op = op
    self.retailerId = retailerId
    self.name = name
    self.description = description
    self.url = url
    self.imageUrl = imageUrl
    self.priceMinor = priceMinor
    self.currency = currency
    self.availability = availability
    self.condition = condition
    self.brand = brand
  }
}

/// Creates a catalog on the connection's business portfolio.
public struct CreateCatalogRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var name: String
  /// The ad platform's catalog vertical; `commerce` when unset.
  public var vertical: String?

  public init(workspaceId: String, connectionId: String, name: String, vertical: String? = nil) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.name = name
    self.vertical = vertical
  }
}

/// Renames a catalog.
public struct UpdateCatalogRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var name: String

  public init(workspaceId: String, connectionId: String, name: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.name = name
  }
}

/// Up to 500 product upserts and deletes in one batch.
public struct CatalogProductBatchRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var products: [CatalogProductWrite]

  public init(workspaceId: String, connectionId: String, products: [CatalogProductWrite]) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.products = products
  }
}

/// Creates a product feed. A `schedule` needs a `url`.
public struct CreateProductFeedRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var name: String
  /// Where the ad platform fetches the file; omit for manual uploads.
  public var url: String?
  /// `HOURLY`, `DAILY` or `WEEKLY`.
  public var schedule: String?

  public init(
    workspaceId: String, connectionId: String, name: String, url: String? = nil,
    schedule: String? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.name = name
    self.url = url
    self.schedule = schedule
  }
}

/// Fetches a product feed now.
public struct StartFeedUploadRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// Overrides the feed's own url for this run.
  public var url: String?

  public init(workspaceId: String, connectionId: String, url: String? = nil) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.url = url
  }
}

/// Creates or updates a product set. Without a `filter` the set is the whole catalog.
public struct ProductSetRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var name: String

  public init(workspaceId: String, connectionId: String, name: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.name = name
  }
}

/// The id of a feed upload the ad platform started.
public struct StartedFeedUpload: Codable, Sendable, Hashable {
  public let id: String?
}

// MARK: - Reach and frequency

/// A priced flight. Nothing is bought until it is reserved.
public struct ReachFrequencyPrediction: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let status: String?
  public let reach: Int?
  public let impressions: Int?
  public let frequencyCap: Int?
  /// Account currency, minor units.
  public let budgetMinor: Int?
  public let startAt: String?
  public let endAt: String?
  /// `true` once the prediction holds inventory.
  public let reserved: Bool?
}

/// The predictions on one ad account.
public struct ReachFrequencyResult: Codable, Sendable, Hashable {
  public let predictions: [ReachFrequencyPrediction]?
  public let workspaceId: String?
}

/// Prices a flight. Nothing is bought until you reserve it. Times are ISO 8601.
public struct CreateReachFrequencyRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String
  public var targeting: AdTargeting
  public var placements: [String]
  public var budgetMinor: Int
  public var startAt: String
  public var endAt: String
  /// How often one person should see the ad over the flight.
  public var frequencyCap: Int?

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, name: String,
    targeting: AdTargeting, placements: [String], budgetMinor: Int, startAt: String,
    endAt: String, frequencyCap: Int? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
    self.targeting = targeting
    self.placements = placements
    self.budgetMinor = budgetMinor
    self.startAt = startAt
    self.endAt = endAt
    self.frequencyCap = frequencyCap
  }
}

/// Reserves or cancels a prediction. Reserving spends on the ad account.
public struct ReachFrequencyActionRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String

  public init(workspaceId: String, connectionId: String, adAccountId: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
  }
}

// MARK: - Ad Library

/// One public archive entry. Read live on every search and stored nowhere.
public struct AdLibraryEntry: Codable, Sendable, Hashable {
  public let id: String
  public let pageId: String?
  public let pageName: String?
  public let bodies: [String]?
  public let titles: [String]?
  public let linkUrls: [String]?
  public let snapshotUrl: String?
  public let publisherPlatforms: [String]?
  public let startedAt: String?
  public let endedAt: String?
  /// Only on the archive's disclosure entries.
  public let currency: String?
  public let spendLower: Int?
  public let spendUpper: Int?
  public let impressionsLower: Int?
  public let impressionsUpper: Int?
}

/// One page of archive results.
public struct AdLibraryPage: Codable, Sendable, Hashable {
  public let entries: [AdLibraryEntry]?
  public let nextCursor: String?
}

// MARK: - Partnership ads

/// A creator who allowlisted this advertiser for partnership ads.
public struct PartnershipCreator: Codable, Sendable, Hashable {
  public let id: String
  public let username: String?
  public let name: String?
  public let status: String?
  public let permissions: [String]?
}

/// Asks a creator for partnership permission.
public struct PartnershipRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  public var pageId: String
  /// The creator's account id.
  public var creatorId: String

  public init(workspaceId: String, connectionId: String, pageId: String, creatorId: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.pageId = pageId
    self.creatorId = creatorId
  }
}

// MARK: - Ad account settings

/// One change recorded on an ad account.
public struct AdActivity: Codable, Sendable, Hashable {
  public let id: String
  public let eventType: String?
  public let actorName: String?
  public let objectName: String?
  public let objectType: String?
  public let extraData: String?
  public let createdAt: String?
}

/// The change log of one ad account.
public struct AdActivityResult: Codable, Sendable, Hashable {
  public let activity: [AdActivity]?
  public let workspaceId: String?
}

/// Groups campaigns, ad sets and ads for reporting.
public struct AdLabel: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let createdAt: String?
}

/// An A/B study splitting traffic across its cells.
public struct AdStudy: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let description: String?
  public let type: String?
  public let status: String?
  public let startAt: String?
  public let endAt: String?
}

/// How many iOS 14 campaigns an ad account may run at once, per app.
public struct IosCampaignLimits: Codable, Sendable, Hashable {
  public let limit: Int?
  public let used: Int?
  public let appId: String?
}

/// A window the ad platform should expect heavier spend over.
public struct HighDemandPeriod: Codable, Sendable, Hashable {
  public let id: String
  public let startAt: String?
  public let endAt: String?
  public let budgetValue: Double?
  public let budgetValueType: String?
}

/// Weights one condition's conversions.
public struct ValueRule: Codable, Sendable, Hashable {
  public var condition: String?
  public var multiplier: Double?

  public init(condition: String? = nil, multiplier: Double? = nil) {
    self.condition = condition
    self.multiplier = multiplier
  }
}

/// Weights conversions so some audiences count for more than others.
public struct ValueRuleSet: Codable, Sendable, Hashable {
  public let id: String
  public let name: String?
  public let status: String?
  public let rules: [ValueRule]?
}

/// Creates or renames an ad label.
public struct AdLabelRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String

  public init(workspaceId: String, connectionId: String, adAccountId: String, name: String) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
  }
}

/// Puts a label on a campaign, ad set or ad, keeping whatever labels it already carries.
public struct ApplyAdLabelRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var objectId: String
  /// `campaign`, `ad_set` or `ad`.
  public var level: AdObjectLevel

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, objectId: String,
    level: AdObjectLevel
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.objectId = objectId
    self.level = level
  }
}

/// One arm of an A/B study.
public struct AdStudyCell: Codable, Sendable, Hashable {
  public var name: String
  /// The campaigns this cell tests.
  public var objectIds: [String]

  public init(name: String, objectIds: [String]) {
    self.name = name
    self.objectIds = objectIds
  }
}

/// An A/B study splitting traffic evenly across two to five cells. Times are ISO 8601.
public struct CreateAdStudyRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String
  public var description: String?
  public var startAt: String
  public var endAt: String
  public var cells: [AdStudyCell]

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, name: String,
    startAt: String, endAt: String, cells: [AdStudyCell], description: String? = nil
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
    self.description = description
    self.startAt = startAt
    self.endAt = endAt
    self.cells = cells
  }
}

/// Tells the ad platform to expect heavier spend over a window, so pacing allows for it.
public struct CreateHighDemandPeriodRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var startAt: String
  public var endAt: String
  public var budgetValue: Double
  public var budgetValueType: BudgetValueType

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, startAt: String,
    endAt: String, budgetValue: Double, budgetValueType: BudgetValueType
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.startAt = startAt
    self.endAt = endAt
    self.budgetValue = budgetValue
    self.budgetValueType = budgetValueType
  }
}

/// Weights conversions across one to twenty rules.
public struct CreateValueRuleSetRequest: Codable, Sendable {
  public var workspaceId: String
  public var connectionId: String
  /// The ad account, `act_…`.
  public var adAccountId: String
  public var name: String
  public var rules: [ValueRule]

  public init(
    workspaceId: String, connectionId: String, adAccountId: String, name: String,
    rules: [ValueRule]
  ) {
    self.workspaceId = workspaceId
    self.connectionId = connectionId
    self.adAccountId = adAccountId
    self.name = name
    self.rules = rules
  }
}
