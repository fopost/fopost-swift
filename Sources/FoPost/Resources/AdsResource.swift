import Foundation

/// Boosts, ads, audiences, and lead forms on a Meta Ads connection. Every call
/// needs the `ads` scope; the four that spend money (``boost(_:)``,
/// ``create(_:)``, ``setStatus(_:workspaceID:status:)``, and
/// ``delete(_:workspaceID:)``) also need `publish`.
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

  private func workspaceQuery(_ workspaceID: String?) -> Query {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return query
  }
}
