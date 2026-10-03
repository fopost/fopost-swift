import Foundation

/// The Google Ads surface no other network has: keywords, assets, Performance
/// Max asset groups, Local Services leads, conversions, and raw GAQL.
///
/// Campaigns, ad groups, ads, audiences, and insights are on ``AdsResource``
/// and dispatch by connection; a connection on another network answers 400
/// here. Every call needs the `ads` scope, and anything that changes what a
/// live account serves or bids also needs `publish`. Amounts are in the
/// account's currency, in minor units.
public struct GoogleAdsResource: Resource {
  let transport: Transport

  // ── Keywords ──

  /// Keywords on the account, or on one ad group.
  public func keywords(_ scope: GoogleAdsScope, adGroupID: String? = nil) async throws
    -> [GoogleKeyword]
  {
    try await httpGet(
      "/ads/google/keywords", query: query(scope, ["ad_group_id": adGroupID]),
      as: [GoogleKeyword].self)
  }

  /// Adds a keyword. Needs `publish` as well as `ads`.
  public func createKeyword(_ body: CreateGoogleKeywordRequest) async throws -> GoogleCreated {
    try await httpPost("/ads/google/keywords", body: body, as: GoogleCreated.self)
  }

  /// Pauses, resumes, or rebids a keyword. Needs `publish` as well as `ads`.
  public func updateKeyword(_ id: String, _ body: UpdateGoogleKeywordRequest) async throws
    -> GoogleCreated
  {
    try await httpPatch("/ads/google/keywords/\(escaped(id))", body: body, as: GoogleCreated.self)
  }

  /// Removes a keyword. Needs `publish` as well as `ads`.
  public func deleteKeyword(_ id: String, scope: GoogleAdsScope) async throws {
    try await delete("/ads/google/keywords/\(escaped(id))", scope: scope)
  }

  /// Ideas from seed keywords, a landing page, or both.
  public func keywordIdeas(_ body: GoogleKeywordIdeasRequest) async throws -> [GoogleKeywordIdea] {
    try await httpPost("/ads/google/keyword-ideas", body: body, as: [GoogleKeywordIdea].self)
  }

  /// Historical metrics for keywords you already have.
  public func keywordMetrics(_ body: GoogleKeywordMetricsRequest) async throws
    -> [GoogleKeywordIdea]
  {
    try await httpPost("/ads/google/keyword-metrics", body: body, as: [GoogleKeywordIdea].self)
  }

  /// What people actually searched, with the metrics each term earned.
  public func searchTerms(_ scope: GoogleAdsScope, since: String, until: String) async throws
    -> [GoogleSearchTerm]
  {
    try await httpGet(
      "/ads/google/search-terms", query: query(scope, ["since": since, "until": until]),
      as: [GoogleSearchTerm].self)
  }

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

  // ── Negative keyword lists ──

  /// The account's negative keyword lists.
  public func negativeKeywordLists(_ scope: GoogleAdsScope) async throws -> [GoogleSharedSet] {
    try await httpGet(
      "/ads/google/negative-keywords", query: query(scope), as: [GoogleSharedSet].self)
  }

  /// Creates a negative keyword list. Needs `publish` as well as `ads`.
  public func createNegativeKeywordList(_ body: CreateGoogleNegativeKeywordListRequest)
    async throws -> GoogleCreated
  {
    try await httpPost("/ads/google/negative-keywords", body: body, as: GoogleCreated.self)
  }

  /// Adds keywords to a list; answers how many landed. Needs `publish`.
  public func addNegativeKeywords(_ body: AddGoogleNegativeKeywordsRequest) async throws
    -> GoogleAdded
  {
    try await httpPost(
      "/ads/google/negative-keywords/keywords", body: body, as: GoogleAdded.self)
  }

  /// Puts a list on a campaign. Needs `publish` as well as `ads`.
  public func attachNegativeKeywordList(_ body: AttachGoogleNegativeKeywordListRequest)
    async throws
  {
    _ = try await httpPost(
      "/ads/google/negative-keywords/attach", body: body, as: JSONValue.self)
  }

  // ── Assets ──

  /// Sitelinks, callouts, and snippets, with the links that place each one.
  public func assets(_ scope: GoogleAdsScope) async throws -> GoogleAssets {
    try await httpGet("/ads/google/assets", query: query(scope), as: GoogleAssets.self)
  }

  /// Adds an asset to the library. Needs `publish` as well as `ads`.
  public func createAsset(_ body: CreateGoogleAssetRequest) async throws -> GoogleCreated {
    try await httpPost("/ads/google/assets", body: body, as: GoogleCreated.self)
  }

  /// Puts an asset under the ads it belongs to. Needs `publish`.
  public func attachAsset(_ body: AttachGoogleAssetRequest) async throws {
    _ = try await httpPost("/ads/google/assets/attach", body: body, as: JSONValue.self)
  }

  /// Removes the links that put an asset under an ad; on Google the asset
  /// itself is permanent. Needs `publish` as well as `ads`.
  public func deleteAsset(_ id: String, scope: GoogleAdsScope) async throws {
    try await delete("/ads/google/assets/\(escaped(id))", scope: scope)
  }

  // ── Performance Max asset groups ──

  /// Performance Max asset groups on the account, or on one campaign.
  public func assetGroups(_ scope: GoogleAdsScope, campaignID: String? = nil) async throws
    -> [GoogleAssetGroup]
  {
    try await httpGet(
      "/ads/google/asset-groups", query: query(scope, ["campaign_id": campaignID]),
      as: [GoogleAssetGroup].self)
  }

  /// Creates an asset group. Needs `publish` as well as `ads`.
  public func createAssetGroup(_ body: CreateGoogleAssetGroupRequest) async throws
    -> GoogleCreated
  {
    try await httpPost("/ads/google/asset-groups", body: body, as: GoogleCreated.self)
  }

  /// Renames, pauses, or resumes an asset group. Needs `publish`.
  public func updateAssetGroup(_ id: String, _ body: UpdateGoogleAssetGroupRequest) async throws
    -> GoogleCreated
  {
    try await httpPatch(
      "/ads/google/asset-groups/\(escaped(id))", body: body, as: GoogleCreated.self)
  }

  /// Removes an asset group. Needs `publish` as well as `ads`.
  public func deleteAssetGroup(_ id: String, scope: GoogleAdsScope) async throws {
    try await delete("/ads/google/asset-groups/\(escaped(id))", scope: scope)
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

  /// A delete carries the scope in its body, the way the API takes it.
  private func delete(_ path: String, scope: GoogleAdsScope) async throws {
    var request = HTTPRequest(method: "DELETE", path: path, unwrap: false)
    do {
      request.body = try Coding.encoder.encode(GoogleAdsScopeRequest(scope: scope))
    } catch {
      throw FoPostError.encoding(message: "Could not encode the request body: \(error)")
    }
    try await transport.send(request)
  }

  private func query(_ scope: GoogleAdsScope, _ extra: [String: String?] = [:]) -> Query {
    var query = Query()
    query.add("workspace_id", scope.workspaceId)
    query.add("connection_id", scope.connectionId)
    query.add("customer_id", scope.customerId)
    for key in extra.keys.sorted() { query.add(key, extra[key] ?? nil) }
    return query
  }

  private func escaped(_ id: String) -> String {
    id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
  }
}
