import Foundation

/// Boosts, ads, the campaign tree, creatives, audiences, insights, and lead
/// forms on a Meta Ads connection. Every call needs the `ads` scope; the ones
/// that spend money (``boost(_:)``, ``create(_:)``,
/// ``setStatus(_:workspaceID:status:)``, ``delete(_:workspaceID:)``,
/// ``bulkSetStatus(_:)``, and every create, update, delete, and duplicate on
/// campaigns, ad sets, and network ads) also need `publish`. Campaigns, ad
/// sets, network ads, creatives, and audiences are addressed by Meta's id plus
/// a connection, and are read live, never stored.
public struct AdsResource: Resource {
  let transport: Transport

  /// Boosts and ads created through FoPost, with insights from their last
  /// refresh.
  public func list(workspaceID: String? = nil) async throws -> [Ad] {
    try await httpGet("/ads", query: workspaceQuery(workspaceID), as: [Ad].self)
  }

  /// Ads on the connected ad accounts that were made elsewhere. Read live,
  /// never stored.
  public func external(workspaceID: String? = nil) async throws -> [ExternalAd] {
    try await httpGet("/ads/external", query: workspaceQuery(workspaceID), as: [ExternalAd].self)
  }

  /// Published posts with a delivery a connection can promote.
  public func boostable(workspaceID: String? = nil) async throws -> [BoostablePost] {
    try await httpGet(
      "/ads/boostable", query: workspaceQuery(workspaceID), as: [BoostablePost].self)
  }

  /// The Meta Ads connections in reach.
  public func connections(workspaceID: String? = nil) async throws -> [AdConnection] {
    try await httpGet(
      "/ads/connections", query: workspaceQuery(workspaceID), as: [AdConnection].self)
  }

  /// Each connection with the ad accounts and Pages its grant reaches.
  public func sources(workspaceID: String? = nil) async throws -> [AdSource] {
    try await httpGet("/ads/sources", query: workspaceQuery(workspaceID), as: [AdSource].self)
  }

  /// Starts a Meta Ads connection. The caller finishes the login at the
  /// returned URL in their own browser.
  public func authorizeMeta(_ body: ConnectMetaAdsRequest) async throws -> MetaAdsAuthorization {
    try await httpPost(
      "/ads/connections/meta/authorize", body: body, as: MetaAdsAuthorization.self)
  }

  /// Removes a connection and every ad record created through it.
  @discardableResult
  public func deleteConnection(_ id: String, workspaceID: String) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/connections/\(escapePath(id))", query: workspaceQuery(workspaceID),
      as: MessageResponse.self)
  }

  /// Boosts a published post. Needs the `publish` scope as well as `ads`. The
  /// boost starts paused unless `paused` is `false`.
  public func boost(_ body: BoostPostRequest) async throws -> Ad {
    try await httpPost("/ads/boost", body: body, as: Ad.self)
  }

  /// Creates a standalone ad. Needs the `publish` scope as well as `ads`. The
  /// ad starts paused unless `paused` is `false`.
  public func create(_ body: CreateAdRequest) async throws -> Ad {
    try await httpPost("/ads", body: body, as: Ad.self)
  }

  /// Reads the delivery status and lifetime insights from the platform.
  public func refresh(_ id: String, workspaceID: String) async throws -> Ad {
    try await httpPost(
      "/ads/\(escapePath(id))/refresh", query: workspaceQuery(workspaceID), as: Ad.self)
  }

  /// Pauses or resumes an ad. Needs the `publish` scope as well as `ads`.
  public func setStatus(_ id: String, workspaceID: String, status: AdStatus) async throws -> Ad {
    try await httpPatch(
      "/ads/\(escapePath(id))", body: SetAdStatusRequest(status: status),
      query: workspaceQuery(workspaceID), as: Ad.self)
  }

  /// Ends delivery and deletes the ad on the platform. Needs the `publish`
  /// scope as well as `ads`.
  @discardableResult
  public func delete(_ id: String, workspaceID: String) async throws -> MessageResponse {
    try await httpDelete(
      "/ads/\(escapePath(id))", query: workspaceQuery(workspaceID), as: MessageResponse.self)
  }

  /// The custom audiences and pixels on one ad account.
  public func audiences(_ params: AudiencesParams) async throws -> AudiencesResult {
    try await httpGet("/ads/audiences", query: params.query, as: AudiencesResult.self)
  }

  /// Builds a custom, lookalike, or website audience.
  public func createAudience(_ body: CreateAudienceRequest) async throws -> CreatedAudience {
    try await httpPost("/ads/audiences", body: body, as: CreatedAudience.self)
  }

  /// Locations, interests, behaviours, and income brackets as the platform
  /// names them.
  public func searchTargeting(_ params: TargetingSearchParams) async throws -> [TargetingOption] {
    try await httpGet("/ads/targeting/search", query: params.query, as: [TargetingOption].self)
  }

  /// Each connection's Page with its Instant Forms.
  public func leadForms(workspaceID: String? = nil) async throws -> [LeadFormSource] {
    try await httpGet(
      "/ads/lead-forms", query: workspaceQuery(workspaceID), as: [LeadFormSource].self)
  }

  /// Creates an Instant Form on a Page.
  public func createLeadForm(_ body: CreateLeadFormRequest) async throws -> CreatedLeadForm {
    try await httpPost("/ads/lead-forms", body: body, as: CreatedLeadForm.self)
  }

  /// One page of a form's leads. Pass `nextCursor` back as `after` for the
  /// next.
  public func leads(formID: String, _ params: LeadsParams) async throws -> LeadsPage {
    try await httpGet(
      "/ads/lead-forms/\(escapePath(formID))/leads", query: params.query, as: LeadsPage.self)
  }

  /// An ad account's campaigns, each with its ad sets and their ads.
  public func accountTree(_ adAccountID: String, connectionID: String, workspaceID: String? = nil)
    async throws -> AdAccountTree
  {
    try await httpGet(
      "/ads/accounts/\(escapePath(adAccountID))/tree",
      query: metaQuery(workspaceID, connectionID), as: AdAccountTree.self)
  }

  /// Creates a campaign. Needs the `publish` scope as well as `ads`. It starts
  /// paused unless `paused` is `false`.
  public func createCampaign(_ body: CreateAdCampaignRequest) async throws -> AdCampaign {
    try await httpPost("/ads/campaigns", body: body, as: AdCampaign.self)
  }

  /// One campaign, read live.
  public func campaign(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> AdCampaign
  {
    try await httpGet(
      "/ads/campaigns/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: AdCampaign.self)
  }

  /// Renames, pauses, or resumes a campaign. Needs the `publish` scope as well
  /// as `ads`.
  public func updateCampaign(
    _ id: String, _ body: UpdateAdCampaignRequest, workspaceID: String, connectionID: String
  ) async throws -> AdCampaign {
    try await httpPatch(
      "/ads/campaigns/\(escapePath(id))", body: body,
      query: metaQuery(workspaceID, connectionID), as: AdCampaign.self)
  }

  /// Deletes a campaign on Meta. Needs the `publish` scope as well as `ads`.
  @discardableResult
  public func deleteCampaign(_ id: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/campaigns/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// Copies a campaign. Needs the `publish` scope as well as `ads`. The copy
  /// starts paused unless `paused` is `false`.
  public func duplicateCampaign(
    _ id: String, workspaceID: String, connectionID: String, paused: Bool? = nil
  ) async throws -> DuplicatedAdObject {
    try await duplicate("/ads/campaigns/\(escapePath(id))", workspaceID, connectionID, paused)
  }

  /// Creates an ad set in a campaign. Needs the `publish` scope as well as
  /// `ads`. It starts paused unless `paused` is `false`.
  public func createAdSet(_ body: CreateAdSetRequest) async throws -> AdSet {
    try await httpPost("/ads/ad-sets", body: body, as: AdSet.self)
  }

  /// One ad set, read live.
  public func adSet(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> AdSet
  {
    try await httpGet(
      "/ads/ad-sets/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: AdSet.self)
  }

  /// Changes an ad set's name, status, budget, end, or targeting. Needs the
  /// `publish` scope as well as `ads`.
  public func updateAdSet(
    _ id: String, _ body: UpdateAdSetRequest, workspaceID: String, connectionID: String
  ) async throws -> AdSet {
    try await httpPatch(
      "/ads/ad-sets/\(escapePath(id))", body: body, query: metaQuery(workspaceID, connectionID),
      as: AdSet.self)
  }

  /// Deletes an ad set on Meta. Needs the `publish` scope as well as `ads`.
  @discardableResult
  public func deleteAdSet(_ id: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/ad-sets/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// Copies an ad set. Needs the `publish` scope as well as `ads`.
  public func duplicateAdSet(
    _ id: String, workspaceID: String, connectionID: String, paused: Bool? = nil
  ) async throws -> DuplicatedAdObject {
    try await duplicate("/ads/ad-sets/\(escapePath(id))", workspaceID, connectionID, paused)
  }

  /// Creates an ad inside an ad set from a creative. Needs the `publish` scope
  /// as well as `ads`. Distinct from ``create(_:)``, which builds a whole
  /// campaign in one call.
  public func createNetworkAd(_ body: CreateNetworkAdRequest) async throws -> NetworkAd {
    try await httpPost("/ads/ads", body: body, as: NetworkAd.self)
  }

  /// One ad inside an ad set, read live.
  public func networkAd(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> NetworkAd
  {
    try await httpGet(
      "/ads/ads/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: NetworkAd.self)
  }

  /// Renames, pauses, resumes, or swaps the creative of an ad. Needs the
  /// `publish` scope as well as `ads`.
  public func updateNetworkAd(
    _ id: String, _ body: UpdateNetworkAdRequest, workspaceID: String, connectionID: String
  ) async throws -> NetworkAd {
    try await httpPatch(
      "/ads/ads/\(escapePath(id))", body: body, query: metaQuery(workspaceID, connectionID),
      as: NetworkAd.self)
  }

  /// Deletes an ad on Meta. Needs the `publish` scope as well as `ads`.
  @discardableResult
  public func deleteNetworkAd(_ id: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/ads/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// Copies an ad. Needs the `publish` scope as well as `ads`.
  public func duplicateNetworkAd(
    _ id: String, workspaceID: String, connectionID: String, paused: Bool? = nil
  ) async throws -> DuplicatedAdObject {
    try await duplicate("/ads/ads/\(escapePath(id))", workspaceID, connectionID, paused)
  }

  /// Pauses or resumes up to 50 campaigns, ad sets, and ads at once. Each
  /// object reports its own outcome. Needs the `publish` scope as well as
  /// `ads`.
  public func bulkSetStatus(_ body: BulkAdStatusRequest) async throws -> [BulkAdStatusResult] {
    try await httpPost("/ads/status", body: body, as: [BulkAdStatusResult].self)
  }

  /// The creatives in one ad account's library.
  public func creatives(connectionID: String, adAccountID: String, workspaceID: String? = nil)
    async throws -> AdCreativesResult
  {
    var query = metaQuery(workspaceID, connectionID)
    query.add("ad_account_id", adAccountID)
    return try await httpGet("/ads/creatives", query: query, as: AdCreativesResult.self)
  }

  /// Builds an image, video, or carousel creative.
  public func createCreative(_ body: CreateAdCreativeRequest) async throws -> AdCreative {
    try await httpPost("/ads/creatives", body: body, as: AdCreative.self)
  }

  /// One creative, read live.
  public func creative(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> AdCreative
  {
    try await httpGet(
      "/ads/creatives/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: AdCreative.self)
  }

  /// Deletes a creative from the library.
  @discardableResult
  public func deleteCreative(_ id: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/creatives/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// One custom audience, read live.
  public func audience(_ id: String, connectionID: String, workspaceID: String? = nil)
    async throws -> Audience
  {
    try await httpGet(
      "/ads/audiences/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: Audience.self)
  }

  /// Renames an audience or changes its description.
  public func updateAudience(
    _ id: String, _ body: UpdateAudienceRequest, workspaceID: String, connectionID: String
  ) async throws -> Audience {
    try await httpPatch(
      "/ads/audiences/\(escapePath(id))", body: body,
      query: metaQuery(workspaceID, connectionID), as: Audience.self)
  }

  /// Deletes an audience on Meta.
  @discardableResult
  public func deleteAudience(_ id: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/audiences/\(escapePath(id))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  /// Adds emails to a custom audience. They are hashed before they leave the
  /// API.
  public func addAudienceUsers(
    _ id: String, emails: [String], workspaceID: String, connectionID: String
  ) async throws -> AddedAudienceUsers {
    try await httpPost(
      "/ads/audiences/\(escapePath(id))/users", body: AddAudienceUsersRequest(emails: emails),
      query: metaQuery(workspaceID, connectionID), as: AddedAudienceUsers.self)
  }

  /// How many people a targeting spec reaches, as Meta estimates it.
  public func estimateReach(_ body: ReachEstimateRequest) async throws -> ReachEstimate {
    try await httpPost("/ads/reach-estimate", body: body, as: ReachEstimate.self)
  }

  /// Insights for any campaign, ad set, or ad on a connection, by Meta's id.
  public func insights(_ params: InsightsParams) async throws -> AdInsightsReport {
    try await httpGet("/ads/insights", query: params.query, as: AdInsightsReport.self)
  }

  /// Insights for an ad created through FoPost, by its FoPost id.
  public func adInsights(_ id: String, _ params: AdInsightsParams) async throws
    -> AdInsightsReport
  {
    try await httpGet(
      "/ads/\(escapePath(id))/insights", query: params.query, as: AdInsightsReport.self)
  }

  /// One Instant Form with its settings.
  public func leadForm(
    _ formID: String, connectionID: String, pageID: String, workspaceID: String? = nil
  ) async throws -> LeadFormDetail {
    var query = metaQuery(workspaceID, connectionID)
    query.add("page_id", pageID)
    return try await httpGet(
      "/ads/lead-forms/\(escapePath(formID))", query: query, as: LeadFormDetail.self)
  }

  /// Archives an Instant Form so it stops collecting leads.
  public func archiveLeadForm(
    _ formID: String, workspaceID: String, connectionID: String, pageID: String
  ) async throws -> LeadFormDetail {
    try await httpPost(
      "/ads/lead-forms/\(escapePath(formID))/archive",
      body: ArchiveLeadFormRequest(
        workspaceId: workspaceID, connectionId: connectionID, pageId: pageID),
      as: LeadFormDetail.self)
  }

  /// Stored leads from subscribed Pages, newest first. Pass `nextCursor` back
  /// as `cursor` for the next page.
  public func leadsFeed(_ params: LeadsFeedParams = LeadsFeedParams()) async throws
    -> LeadsFeedPage
  {
    try await httpGet("/ads/leads", query: params.query, as: LeadsFeedPage.self)
  }

  /// The Pages whose leads are stored as they arrive.
  public func leadPages(workspaceID: String? = nil) async throws -> [LeadPage] {
    try await httpGet("/ads/lead-pages", query: workspaceQuery(workspaceID), as: [LeadPage].self)
  }

  /// Starts storing a Page's leads, backfilling recent ones.
  public func subscribeLeadPage(_ body: SubscribeLeadPageRequest) async throws
    -> SubscribedLeadPage
  {
    try await httpPost("/ads/lead-pages", body: body, as: SubscribedLeadPage.self)
  }

  /// Stops storing a Page's leads.
  @discardableResult
  public func unsubscribeLeadPage(_ pageID: String, workspaceID: String, connectionID: String)
    async throws -> MessageResponse
  {
    try await httpDelete(
      "/ads/lead-pages/\(escapePath(pageID))", query: metaQuery(workspaceID, connectionID),
      as: MessageResponse.self)
  }

  private func duplicate(
    _ path: String, _ workspaceID: String, _ connectionID: String, _ paused: Bool?
  ) async throws -> DuplicatedAdObject {
    try await httpPost(
      "\(path)/duplicate", body: DuplicateAdObjectRequest(paused: paused),
      query: metaQuery(workspaceID, connectionID), as: DuplicatedAdObject.self)
  }

  private func metaQuery(_ workspaceID: String?, _ connectionID: String) -> Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("connection_id", connectionID)
    return query
  }

  private func workspaceQuery(_ workspaceID: String?) -> Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return query
  }
}
