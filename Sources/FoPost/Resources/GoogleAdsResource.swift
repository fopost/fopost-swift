import Foundation

/// The Google Ads surface no other network has: bid strategies, ad schedules,
/// Local Services leads, conversions, and raw GAQL.
///
/// Ads, audiences, and insights are on ``AdsResource`` and dispatch by
/// connection; a connection on another network answers 400
/// here. Every call needs the `ads` scope, and anything that changes what a
/// live account serves or bids also needs `publish`. Amounts are in the
/// account's currency, in minor units.
public struct GoogleAdsResource: Resource {
  let transport: Transport

  // ── Bid strategies and ad schedule ──

  /// The account's portfolio bid strategies.
  public func bidStrategies(_ scope: GoogleAdsScope) async throws -> [GoogleBidStrategy] {
    try await httpGet(
      "/ads/google/bid-strategies", query: query(scope), as: [GoogleBidStrategy].self)
  }

  /// Adds a bid strategy. Needs `publish` as well as `ads`.
  public func createBidStrategy(_ body: CreateGoogleBidStrategyRequest) async throws
    -> GoogleCreated
  {
    try await httpPost("/ads/google/bid-strategies", body: body, as: GoogleCreated.self)
  }

  /// A campaign's ad schedule.
  public func adSchedule(_ scope: GoogleAdsScope, campaignID: String) async throws
    -> [GoogleAdScheduleSlot]
  {
    try await httpGet(
      "/ads/google/ad-schedule", query: query(scope, ["campaign_id": campaignID]),
      as: [GoogleAdScheduleSlot].self)
  }

  /// Replaces every slot on the campaign: Google has no partial edit for a
  /// schedule. Needs `publish` as well as `ads`.
  public func setAdSchedule(_ body: SetGoogleAdScheduleRequest) async throws -> GoogleSlots {
    try await httpPut("/ads/google/ad-schedule", body: body, as: GoogleSlots.self)
  }

  // ── Local Services leads ──

  /// Leads from Local Services Ads, read live and never stored.
  public func localServicesLeads(_ scope: GoogleAdsScope, since: String, until: String)
    async throws -> [GoogleLocalServicesLead]
  {
    try await httpGet(
      "/ads/google/local-services", query: query(scope, ["since": since, "until": until]),
      as: [GoogleLocalServicesLead].self)
  }

  // ── Conversions ──

  /// The account's conversion actions.
  public func conversionActions(_ scope: GoogleAdsScope) async throws
    -> [GoogleConversionAction]
  {
    try await httpGet(
      "/ads/google/conversions", query: query(scope), as: [GoogleConversionAction].self)
  }

  /// Adds a conversion action. Needs `publish` as well as `ads`.
  public func createConversionAction(_ body: CreateGoogleConversionActionRequest) async throws
    -> GoogleCreated
  {
    try await httpPost("/ads/google/conversions", body: body, as: GoogleCreated.self)
  }

  /// Sends offline conversions; answers how many landed. Needs `publish`.
  public func uploadConversions(_ body: UploadGoogleConversionsRequest) async throws
    -> GoogleUploaded
  {
    try await httpPost("/ads/google/conversions/upload", body: body, as: GoogleUploaded.self)
  }

  /// Sends conversion adjustments; answers how many landed. Needs `publish`.
  public func uploadConversionAdjustments(_ body: UploadGoogleConversionAdjustmentsRequest)
    async throws -> GoogleUploaded
  {
    try await httpPost(
      "/ads/google/conversions/adjustments", body: body, as: GoogleUploaded.self)
  }

  // ── GAQL ──

  /// Runs a read-only GAQL SELECT; rows come back as Google sends them.
  public func query(_ body: GoogleQueryRequest) async throws -> GoogleQueryResult {
    try await httpPost("/ads/insights/query", body: body, as: GoogleQueryResult.self)
  }

  private func query(_ scope: GoogleAdsScope, _ extra: [String: String?] = [:]) -> Query {
    var query = Query()
    query.add("workspace_id", scope.workspaceId)
    query.add("connection_id", scope.connectionId)
    query.add("customer_id", scope.customerId)
    for key in extra.keys.sorted() { query.add(key, extra[key] ?? nil) }
    return query
  }
}
