import Foundation

/// Reach-and-frequency predictions, partnership allowlists, and the ad
/// account's own settings. Every call needs the `ads` scope; reserving a
/// prediction also needs `publish`. Everything here is read live from the ad
/// platform and never stored.
extension AdsResource {

  // MARK: - Goals

  /// The goals this connection's ad platform can run right now. Ask rather than
  /// assume: a goal the deployment is not set up for is absent here and is
  /// refused if you send it anyway.
  public func goals(connectionID: String, workspaceID: String? = nil) async throws -> [String] {
    try await httpGet("/ads/goals", query: adQuery(workspaceID, connectionID), as: [String].self)
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
}
