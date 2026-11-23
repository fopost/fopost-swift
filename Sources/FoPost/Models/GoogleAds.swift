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

/// A portfolio bid strategy.
public enum GoogleBidStrategyType: String, Codable, Sendable {
  case targetSpend = "TARGET_SPEND"
  case maximizeConversions = "MAXIMIZE_CONVERSIONS"
  case maximizeConversionValue = "MAXIMIZE_CONVERSION_VALUE"
  case targetCpa = "TARGET_CPA"
  case targetRoas = "TARGET_ROAS"
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
