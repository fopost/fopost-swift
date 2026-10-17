import Foundation

/// Product catalogs, reach-and-frequency predictions, the public ad archive,
/// partnership allowlists, and the ad account's own settings. Every call needs
/// the `ads` scope; the ones that spend or go live — creating and changing a
/// catalog, and reserving a prediction — also need `publish`. Everything here
/// is read live from the ad platform and never stored.
extension AdsResource {

  // MARK: - Goals

  /// The goals this connection's ad platform can run right now. Ask rather than
  /// assume: a goal the deployment is not set up for is absent here and is
  /// refused if you send it anyway.
  public func goals(connectionID: String, workspaceID: String? = nil) async throws -> [String] {
    try await httpGet("/ads/goals", query: adQuery(workspaceID, connectionID), as: [String].self)
  }

  // MARK: - Product catalogs

  /// Catalogs the connection's business portfolios reach.
  public func catalogs(connectionID: String, workspaceID: String? = nil) async throws
    -> ProductCatalogsResult
  {
    try await httpGet(
      "/ads/catalogs", query: adQuery(workspaceID, connectionID), as: ProductCatalogsResult.self)
  }

  /// Creates a catalog on the connection's business portfolio. Also needs `publish`.
  public func createCatalog(_ body: CreateCatalogRequest) async throws -> ProductCatalog {
    try await httpPost("/ads/catalogs", body: body, as: ProductCatalog.self)
  }

  /// One catalog, read live.
  public func catalog(_ id: String, connectionID: String, workspaceID: String? = nil) async throws
    -> ProductCatalog
  {
    try await httpGet(
      "/ads/catalogs/\(escapePath(id))", query: adQuery(workspaceID, connectionID),
      as: ProductCatalog.self)
  }

  /// Renames a catalog. Also needs `publish`.
  public func updateCatalog(
    _ id: String, _ body: UpdateCatalogRequest, workspaceID: String, connectionID: String
  ) async throws -> ProductCatalog {
    try await httpPatch(
      "/ads/catalogs/\(escapePath(id))", body: body, query: adQuery(workspaceID, connectionID),
      as: ProductCatalog.self)
  }

  /// Deletes the catalog with every product, feed, and set in it. Also needs `publish`.
  @discardableResult
  public func deleteCatalog(_ id: String, workspaceID: String, connectionID: String) async throws
    -> MessageResponse
  {
    try await httpDelete(
      "/ads/catalogs/\(escapePath(id))", query: adQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// One page of products; pass `nextCursor` back as `after`.
  public func catalogProducts(
    _ id: String, connectionID: String, workspaceID: String? = nil, after: String? = nil
  ) async throws -> CatalogProductsPage {
    var query = adQuery(workspaceID, connectionID)
    query.add("after", after)
    return try await httpGet(
      "/ads/catalogs/\(escapePath(id))/products", query: query, as: CatalogProductsPage.self)
  }

  /// Up to 500 upserts and deletes in one batch, keyed by your own retailer id.
  /// Also needs `publish`.
  public func writeCatalogProducts(_ id: String, _ body: CatalogProductBatchRequest) async throws
    -> CatalogBatchResult
  {
    try await httpPost(
      "/ads/catalogs/\(escapePath(id))/products", body: body, as: CatalogBatchResult.self)
  }

  /// The feeds keeping a catalog in step with a hosted product file.
  public func productFeeds(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> [ProductFeed]
  {
    try await httpGet(
      "/ads/catalogs/\(escapePath(id))/feeds", query: adQuery(workspaceID, connectionID),
      as: [ProductFeed].self)
  }

  /// Creates a product feed. Also needs `publish`.
  public func createProductFeed(_ id: String, _ body: CreateProductFeedRequest) async throws
    -> ProductFeed
  {
    try await httpPost("/ads/catalogs/\(escapePath(id))/feeds", body: body, as: ProductFeed.self)
  }

  /// Deletes a product feed. Also needs `publish`.
  @discardableResult
  public func deleteProductFeed(
    _ id: String, feedID: String, workspaceID: String, connectionID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      feedPath(id, feedID), query: adQuery(workspaceID, connectionID), as: MessageResponse.self)
  }

  /// Each run the ad platform made of the feed.
  public func feedUploads(
    _ id: String, feedID: String, connectionID: String, workspaceID: String? = nil
  ) async throws -> [ProductFeedUpload] {
    try await httpGet(
      "\(feedPath(id, feedID))/uploads", query: adQuery(workspaceID, connectionID),
      as: [ProductFeedUpload].self)
  }

  /// Fetches the feed now. Also needs `publish`.
  public func startFeedUpload(_ id: String, feedID: String, _ body: StartFeedUploadRequest)
    async throws -> StartedFeedUpload
  {
    try await httpPost("\(feedPath(id, feedID))/uploads", body: body, as: StartedFeedUpload.self)
  }

  /// A catalog ad runs from a product set, not the whole catalog.
  public func productSets(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> [ProductSet]
  {
    try await httpGet(
      "/ads/catalogs/\(escapePath(id))/product-sets", query: adQuery(workspaceID, connectionID),
      as: [ProductSet].self)
  }

  /// Creates a product set. Also needs `publish`.
  public func createProductSet(_ id: String, _ body: ProductSetRequest) async throws -> ProductSet {
    try await httpPost(
      "/ads/catalogs/\(escapePath(id))/product-sets", body: body, as: ProductSet.self)
  }

  /// Renames a product set. Also needs `publish`.
  public func updateProductSet(
    _ id: String, setID: String, _ body: ProductSetRequest, workspaceID: String,
    connectionID: String
  ) async throws -> ProductSet {
    try await httpPatch(
      productSetPath(id, setID), body: body, query: adQuery(workspaceID, connectionID),
      as: ProductSet.self)
  }

  /// Deletes a product set. Also needs `publish`.
  @discardableResult
  public func deleteProductSet(
    _ id: String, setID: String, workspaceID: String, connectionID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      productSetPath(id, setID), query: adQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  // MARK: - Reach and frequency

  /// The predictions on one ad account.
  public func reachFrequency(
    connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> ReachFrequencyResult {
    try await httpGet(
      "/ads/reach-frequency", query: accountQuery(workspaceID, connectionID, adAccountID),
      as: ReachFrequencyResult.self)
  }

  /// Prices a flight. Nothing is bought until you reserve it.
  public func createReachFrequency(_ body: CreateReachFrequencyRequest) async throws
    -> ReachFrequencyPrediction
  {
    try await httpPost("/ads/reach-frequency", body: body, as: ReachFrequencyPrediction.self)
  }

  /// One prediction, read live.
  public func reachFrequencyPrediction(
    _ id: String, connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> ReachFrequencyPrediction {
    try await httpGet(
      "/ads/reach-frequency/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID),
      as: ReachFrequencyPrediction.self)
  }

  /// Holds the inventory the prediction priced. Also needs `publish`.
  public func reserveReachFrequency(_ id: String, _ body: ReachFrequencyActionRequest)
    async throws -> ReachFrequencyPrediction
  {
    try await httpPost(
      "/ads/reach-frequency/\(escapePath(id))/reserve", body: body,
      as: ReachFrequencyPrediction.self)
  }

  /// Cancels a reservation. Also needs `publish`.
  public func cancelReachFrequency(_ id: String, _ body: ReachFrequencyActionRequest)
    async throws -> ReachFrequencyPrediction
  {
    try await httpPost(
      "/ads/reach-frequency/\(escapePath(id))/cancel", body: body,
      as: ReachFrequencyPrediction.self)
  }

  // MARK: - Ad Library

  /// The public ad archive: ads anyone is running, by keyword or by Page. Read
  /// live on every call and stored nowhere, so an ad that stops running is
  /// simply absent from the next search. `countries` are two-letter codes the
  /// ad reached.
  public func library(
    connectionID: String, countries: [String], q: String? = nil, pageIDs: [String]? = nil,
    activeStatus: String? = nil, limit: Int? = nil, after: String? = nil,
    workspaceID: String? = nil
  ) async throws -> AdLibraryPage {
    var query = adQuery(workspaceID, connectionID)
    query.add("countries", countries.joined(separator: ","))
    query.add("q", q)
    if let pageIDs, !pageIDs.isEmpty { query.add("page_ids", pageIDs.joined(separator: ",")) }
    query.add("active_status", activeStatus)
    if let limit { query.add("limit", String(limit)) }
    query.add("after", after)
    return try await httpGet("/ads/library", query: query, as: AdLibraryPage.self)
  }

  // MARK: - Partnership ads

  /// Creators who allowlisted this Page to run partnership ads on their posts.
  public func partnershipCreators(
    connectionID: String, pageID: String, workspaceID: String? = nil
  ) async throws -> [PartnershipCreator] {
    var query = adQuery(workspaceID, connectionID)
    query.add("page_id", pageID)
    return try await httpGet(
      "/ads/partnership/creators", query: query, as: [PartnershipCreator].self)
  }

  /// Asks a creator for permission; the list as it now stands.
  public func requestPartnership(_ body: PartnershipRequest) async throws -> [PartnershipCreator] {
    try await httpPost("/ads/partnership/creators", body: body, as: [PartnershipCreator].self)
  }

  /// Revokes a creator's partnership permission.
  @discardableResult
  public func revokePartnership(
    _ creatorID: String, workspaceID: String, connectionID: String, pageID: String
  ) async throws -> MessageResponse {
    var query = adQuery(workspaceID, connectionID)
    query.add("page_id", pageID)
    return try await httpDelete(
      "/ads/partnership/creators/\(escapePath(creatorID))", query: query,
      as: MessageResponse.self)
  }

  // MARK: - Ad account settings

  /// Who changed what on the ad account, and when. Dates are `YYYY-MM-DD`.
  public func accountActivity(
    connectionID: String, adAccountID: String, since: String? = nil, until: String? = nil,
    workspaceID: String? = nil
  ) async throws -> AdActivityResult {
    var query = accountQuery(workspaceID, connectionID, adAccountID)
    query.add("since", since)
    query.add("until", until)
    return try await httpGet("/ads/account/activity", query: query, as: AdActivityResult.self)
  }

  /// The labels on an ad account.
  public func labels(connectionID: String, adAccountID: String, workspaceID: String? = nil)
    async throws -> [AdLabel]
  {
    try await httpGet(
      "/ads/account/labels", query: accountQuery(workspaceID, connectionID, adAccountID),
      as: [AdLabel].self)
  }

  /// Creates a label.
  public func createLabel(_ body: AdLabelRequest) async throws -> AdLabel {
    try await httpPost("/ads/account/labels", body: body, as: AdLabel.self)
  }

  /// Renames a label.
  public func updateLabel(
    _ id: String, _ body: AdLabelRequest, workspaceID: String, connectionID: String
  ) async throws -> AdLabel {
    try await httpPatch(
      "/ads/account/labels/\(escapePath(id))", body: body,
      query: adQuery(workspaceID, connectionID), as: AdLabel.self)
  }

  /// Deletes a label.
  @discardableResult
  public func deleteLabel(
    _ id: String, workspaceID: String, connectionID: String, adAccountID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/account/labels/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: MessageResponse.self)
  }

  /// Puts a label on a campaign, ad set, or ad, keeping whatever labels it
  /// already carries.
  @discardableResult
  public func applyLabel(_ id: String, _ body: ApplyAdLabelRequest) async throws
    -> MessageResponse
  {
    try await httpPost(
      "/ads/account/labels/\(escapePath(id))/apply", body: body, as: MessageResponse.self)
  }

  /// The A/B studies on an ad account.
  public func studies(connectionID: String, adAccountID: String, workspaceID: String? = nil)
    async throws -> [AdStudy]
  {
    try await httpGet(
      "/ads/account/studies", query: accountQuery(workspaceID, connectionID, adAccountID),
      as: [AdStudy].self)
  }

  /// Splits traffic evenly across the cells for the length of the flight.
  public func createStudy(_ body: CreateAdStudyRequest) async throws -> AdStudy {
    try await httpPost("/ads/account/studies", body: body, as: AdStudy.self)
  }

  /// One A/B study, read live.
  public func study(
    _ id: String, connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> AdStudy {
    try await httpGet(
      "/ads/account/studies/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: AdStudy.self)
  }

  /// Deletes an A/B study.
  @discardableResult
  public func deleteStudy(
    _ id: String, workspaceID: String, connectionID: String, adAccountID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/account/studies/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: MessageResponse.self)
  }

  /// How many iOS 14 campaigns the account may run at once, per app.
  public func iosCampaignLimits(
    connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> [IosCampaignLimits] {
    try await httpGet(
      "/ads/account/ios-limits", query: accountQuery(workspaceID, connectionID, adAccountID),
      as: [IosCampaignLimits].self)
  }

  /// The high-demand windows declared on an ad account.
  public func highDemandPeriods(
    connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> [HighDemandPeriod] {
    try await httpGet(
      "/ads/account/high-demand-periods",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: [HighDemandPeriod].self)
  }

  /// Tells the ad platform to expect heavier spend over a window, so pacing
  /// allows for it.
  public func createHighDemandPeriod(_ body: CreateHighDemandPeriodRequest) async throws
    -> HighDemandPeriod
  {
    try await httpPost("/ads/account/high-demand-periods", body: body, as: HighDemandPeriod.self)
  }

  /// Deletes a high-demand window.
  @discardableResult
  public func deleteHighDemandPeriod(
    _ id: String, workspaceID: String, connectionID: String, adAccountID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/account/high-demand-periods/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: MessageResponse.self)
  }

  /// The value rule sets on an ad account.
  public func valueRuleSets(
    connectionID: String, adAccountID: String, workspaceID: String? = nil
  ) async throws -> [ValueRuleSet] {
    try await httpGet(
      "/ads/account/value-rule-sets", query: accountQuery(workspaceID, connectionID, adAccountID),
      as: [ValueRuleSet].self)
  }

  /// Weights conversions so some audiences count for more than others.
  public func createValueRuleSet(_ body: CreateValueRuleSetRequest) async throws -> ValueRuleSet {
    try await httpPost("/ads/account/value-rule-sets", body: body, as: ValueRuleSet.self)
  }

  /// Deletes a value rule set.
  @discardableResult
  public func deleteValueRuleSet(
    _ id: String, workspaceID: String, connectionID: String, adAccountID: String
  ) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/account/value-rule-sets/\(escapePath(id))",
      query: accountQuery(workspaceID, connectionID, adAccountID), as: MessageResponse.self)
  }

  // MARK: - Query helpers

  private func adQuery(_ workspaceID: String?, _ connectionID: String) -> Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    return query
  }

  private func accountQuery(
    _ workspaceID: String?, _ connectionID: String, _ adAccountID: String
  ) -> Query {
    var query = adQuery(workspaceID, connectionID)
    query.add("ad_account_id", adAccountID)
    return query
  }

  private func feedPath(_ catalogID: String, _ feedID: String) -> String {
    "/ads/catalogs/\(escapePath(catalogID))/feeds/\(escapePath(feedID))"
  }

  private func productSetPath(_ catalogID: String, _ setID: String) -> String {
    "/ads/catalogs/\(escapePath(catalogID))/product-sets/\(escapePath(setID))"
  }
}
