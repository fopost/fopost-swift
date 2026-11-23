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
