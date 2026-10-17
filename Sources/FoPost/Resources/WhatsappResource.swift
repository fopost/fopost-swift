import Foundation

/// WhatsApp Business — a number the customer already owns.
///
/// The platform owns templates, flows, the business profile and the commerce
/// settings, so every method here is a live read or write against the customer's
/// own WhatsApp Business Account. Nothing is cached, and all of it answers 503
/// until WhatsApp is set up on the deployment. Every method needs the `accounts`
/// scope, except the sandbox, which sends a template and needs `publish`.
public struct WhatsappResource: Resource {
  let transport: Transport

  private func base(_ accountID: String) -> String {
    "/accounts/\(escapePath(accountID))/whatsapp"
  }

  // MARK: - Profile

  /// The profile on the number, plus its quality rating and limit tier.
  public func profile(_ accountID: String) async throws -> WhatsappProfile {
    try await httpGet("\(base(accountID))/profile", as: WhatsappProfile.self)
  }

  /// A partial update: omitted fields keep their value.
  public func updateProfile(_ accountID: String, _ body: UpdateWhatsappProfileRequest) async throws
    -> WhatsappProfile
  {
    try await httpPatch("\(base(accountID))/profile", body: body, as: WhatsappProfile.self)
  }

  /// A review, not a write: the number keeps its old name until it passes.
  public func requestDisplayName(_ accountID: String, displayName: String) async throws {
    _ = try await httpPost(
      "\(base(accountID))/profile/display-name",
      body: ["display_name": displayName], as: JSONValue.self)
  }

  /// Sets the public username on the number.
  public func setUsername(_ accountID: String, username: String) async throws -> WhatsappProfile {
    try await httpPut(
      "\(base(accountID))/profile/username", body: ["username": username],
      as: WhatsappProfile.self)
  }

  // MARK: - Templates

  /// Every template on the account, with its review status.
  public func templates(_ accountID: String, after: String? = nil) async throws
    -> [WhatsappTemplate]
  {
    var query = Query()
    query.add("after", after)
    return try await httpGet(
      "\(base(accountID))/templates", query: query, as: [WhatsappTemplate].self)
  }

  /// The pre-written templates the platform offers, for adapting.
  public func templateLibrary(_ accountID: String, search: String? = nil) async throws
    -> [JSONValue]
  {
    var query = Query()
    query.add("search", search)
    return try await httpGet(
      "\(base(accountID))/templates/library", query: query, as: [JSONValue].self)
  }

  /// One template and the review status it currently has.
  public func template(_ accountID: String, _ templateID: String) async throws -> WhatsappTemplate {
    try await httpGet(
      "\(base(accountID))/templates/\(escapePath(templateID))", as: WhatsappTemplate.self)
  }

  /// Files a template for review. The result carries the status the platform
  /// assigned, which is `PENDING` on a normal submission.
  public func createTemplate(_ accountID: String, _ body: CreateWhatsappTemplateRequest)
    async throws -> WhatsappTemplate
  {
    try await httpPost("\(base(accountID))/templates", body: body, as: WhatsappTemplate.self)
  }

  /// Creates a template from one of the platform's library entries.
  public func importTemplate(_ accountID: String, _ body: ImportWhatsappTemplateRequest)
    async throws -> WhatsappTemplate
  {
    try await httpPost("\(base(accountID))/templates/import", body: body, as: WhatsappTemplate.self)
  }

  /// Edits a template. The name cannot change.
  public func updateTemplate(
    _ accountID: String, _ templateID: String, _ body: UpdateWhatsappTemplateRequest
  ) async throws -> WhatsappTemplate {
    try await httpPatch(
      "\(base(accountID))/templates/\(escapePath(templateID))", body: body,
      as: WhatsappTemplate.self)
  }

  /// The name is required: it is what the platform deletes by.
  public func deleteTemplate(_ accountID: String, _ templateID: String, name: String) async throws {
    var query = Query()
    query.add("name", name)
    _ = try await httpDelete(
      "\(base(accountID))/templates/\(escapePath(templateID))", query: query, as: JSONValue.self)
  }

  // MARK: - Groups

  /// The groups this number created.
  public func groups(_ accountID: String) async throws -> [WhatsappGroup] {
    try await httpGet("\(base(accountID))/groups", as: [WhatsappGroup].self)
  }

  /// Participation is invite-only: send the invite link, there is no add.
  public func createGroup(_ accountID: String, _ body: WhatsappGroupRequest) async throws
    -> WhatsappGroup
  {
    try await httpPost("\(base(accountID))/groups", body: body, as: WhatsappGroup.self)
  }

  /// One group and its participant count.
  public func group(_ accountID: String, _ groupID: String) async throws -> WhatsappGroup {
    try await httpGet("\(base(accountID))/groups/\(escapePath(groupID))", as: WhatsappGroup.self)
  }

  /// Changes a group's subject or description.
  public func updateGroup(_ accountID: String, _ groupID: String, _ body: WhatsappGroupRequest)
    async throws -> WhatsappGroup
  {
    try await httpPatch(
      "\(base(accountID))/groups/\(escapePath(groupID))", body: body, as: WhatsappGroup.self)
  }

  /// Removes the group.
  public func deleteGroup(_ accountID: String, _ groupID: String) async throws {
    try await httpDelete("\(base(accountID))/groups/\(escapePath(groupID))")
  }

  /// The link someone joins the group with.
  public func groupInviteLink(_ accountID: String, _ groupID: String) async throws -> String? {
    let body = try await httpGet(
      "\(base(accountID))/groups/\(escapePath(groupID))/invite-link", as: JSONValue.self)
    return inviteLink(of: body)
  }

  /// Issues a new link and invalidates the old one.
  public func resetGroupInviteLink(_ accountID: String, _ groupID: String) async throws -> String? {
    let body = try await httpPost(
      "\(base(accountID))/groups/\(escapePath(groupID))/invite-link", as: JSONValue.self)
    return inviteLink(of: body)
  }

  private func inviteLink(of body: JSONValue) -> String? {
    if case .object(let fields) = body, case .string(let link)? = fields["inviteLink"] {
      return link
    }
    return nil
  }

  /// Removes people from the group. There is no matching add.
  public func removeGroupParticipants(_ accountID: String, _ groupID: String, users: [String])
    async throws
  {
    _ = try await transport.send(
      try deleteWithBody(
        "\(base(accountID))/groups/\(escapePath(groupID))/participants", ["users": users]),
      as: JSONValue.self)
  }

  // MARK: - Blocking

  /// The numbers this account has blocked.
  public func blocked(_ accountID: String, after: String? = nil) async throws -> [String] {
    var query = Query()
    query.add("after", after)
    return try await httpGet("\(base(accountID))/block", query: query, as: [String].self)
  }

  /// Blocks up to 100 numbers, and names the ones the platform refused.
  public func blockUsers(_ accountID: String, users: [String]) async throws -> WhatsappBlockResult {
    try await httpPost(
      "\(base(accountID))/block", body: ["users": users], as: WhatsappBlockResult.self)
  }

  /// Unblocks up to 100 numbers.
  public func unblockUsers(_ accountID: String, users: [String]) async throws
    -> WhatsappBlockResult
  {
    try await transport.send(
      try deleteWithBody("\(base(accountID))/block", ["users": users]),
      as: WhatsappBlockResult.self)
  }

  // MARK: - Commerce

  /// Whether the cart and catalog show on the number.
  public func commerceSettings(_ accountID: String) async throws -> WhatsappCommerceSettings {
    try await httpGet("\(base(accountID))/commerce", as: WhatsappCommerceSettings.self)
  }

  /// Turns the cart or the catalog on or off.
  public func updateCommerceSettings(_ accountID: String, _ body: UpdateWhatsappCommerceRequest)
    async throws -> WhatsappCommerceSettings
  {
    try await httpPatch(
      "\(base(accountID))/commerce", body: body, as: WhatsappCommerceSettings.self)
  }

  /// Points the number at a catalog the customer already owns.
  public func linkCatalog(_ accountID: String, catalogID: String) async throws
    -> WhatsappCommerceSettings
  {
    try await httpPost(
      "\(base(accountID))/commerce/catalog", body: ["catalog_id": catalogID],
      as: WhatsappCommerceSettings.self)
  }

  // MARK: - Flows

  /// The in-chat forms on this account, with their validation errors.
  public func flows(_ accountID: String) async throws -> [WhatsappFlow] {
    try await httpGet("\(base(accountID))/flows", as: [WhatsappFlow].self)
  }

  /// One flow and what the platform found wrong with it.
  public func flow(_ accountID: String, _ flowID: String) async throws -> WhatsappFlow {
    try await httpGet("\(base(accountID))/flows/\(escapePath(flowID))", as: WhatsappFlow.self)
  }

  /// Creates a draft flow; its screens are uploaded separately.
  public func createFlow(_ accountID: String, _ body: CreateWhatsappFlowRequest) async throws
    -> WhatsappFlow
  {
    try await httpPost("\(base(accountID))/flows", body: body, as: WhatsappFlow.self)
  }

  /// Changes a flow's name, categories or endpoint.
  public func updateFlow(_ accountID: String, _ flowID: String, _ body: UpdateWhatsappFlowRequest)
    async throws -> WhatsappFlow
  {
    try await httpPatch(
      "\(base(accountID))/flows/\(escapePath(flowID))", body: body, as: WhatsappFlow.self)
  }

  /// Drafts only; a published flow is deprecated instead.
  public func deleteFlow(_ accountID: String, _ flowID: String) async throws {
    try await httpDelete("\(base(accountID))/flows/\(escapePath(flowID))")
  }

  /// Replaces the flow's screens. The platform answers with its validation
  /// errors rather than refusing, so they come back as data.
  public func uploadFlowJSON(_ accountID: String, _ flowID: String, flowJSON: JSONValue)
    async throws -> WhatsappFlowJSONResult
  {
    try await httpPut(
      "\(base(accountID))/flows/\(escapePath(flowID))/json", body: ["flow_json": flowJSON],
      as: WhatsappFlowJSONResult.self)
  }

  /// Makes the flow sendable. A published flow can no longer be deleted.
  public func publishFlow(_ accountID: String, _ flowID: String) async throws -> WhatsappFlow {
    try await httpPost(
      "\(base(accountID))/flows/\(escapePath(flowID))/publish", as: WhatsappFlow.self)
  }

  /// Retires a published flow.
  public func deprecateFlow(_ accountID: String, _ flowID: String) async throws -> WhatsappFlow {
    try await httpPost(
      "\(base(accountID))/flows/\(escapePath(flowID))/deprecate", as: WhatsappFlow.self)
  }

  /// What people submitted through this account's flows.
  public func flowResponses(_ accountID: String) async throws -> [WhatsappFlowResponse] {
    try await httpGet("\(base(accountID))/flows/responses", as: [WhatsappFlowResponse].self)
  }

  /// Whether a business public key is registered, and how the platform judged it.
  public func encryptionKeyStatus(_ accountID: String) async throws
    -> WhatsappEncryptionKeyStatus
  {
    try await httpGet(
      "\(base(accountID))/flows/encryption-key", as: WhatsappEncryptionKeyStatus.self)
  }

  /// Registers the public half of the key the platform encrypts a flow
  /// endpoint's payloads with. The private half stays with the customer.
  public func setEncryptionKey(_ accountID: String, businessPublicKey: String) async throws
    -> WhatsappEncryptionKeyStatus
  {
    try await httpPut(
      "\(base(accountID))/flows/encryption-key",
      body: ["business_public_key": businessPublicKey], as: WhatsappEncryptionKeyStatus.self)
  }

  // MARK: - Account state and sandbox

  /// The account review state and the number's quality and limit tier.
  public func accountEvents(_ accountID: String) async throws -> JSONValue {
    try await httpGet("\(base(accountID))/events", as: JSONValue.self)
  }

  /// Sandbox invitations for a workspace.
  public func sandboxSessions(workspaceID: String) async throws -> [WhatsappSandboxSession] {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet(
      "/whatsapp/sandbox/sessions", query: query, as: [WhatsappSandboxSession].self)
  }

  /// Invites one tester to the platform-owned test number. Inviting sends a
  /// template, so it needs the `publish` scope.
  public func createSandboxSession(workspaceID: String, phoneNumber: String) async throws
    -> WhatsappSandboxSession
  {
    try await httpPost(
      "/whatsapp/sandbox/sessions",
      body: ["workspaceId": workspaceID, "phoneNumber": phoneNumber],
      as: WhatsappSandboxSession.self)
  }

  /// DELETE with a body, which the block and participant routes both take.
  private func deleteWithBody(_ path: String, _ body: [String: [String]]) throws -> HTTPRequest {
    var request = HTTPRequest(method: "DELETE", path: path, unwrap: true)
    do {
      request.body = try Coding.encoder.encode(body)
    } catch {
      throw FoPostError.encoding(message: "Could not encode the request body: \(error)")
    }
    request.contentType = "application/json"
    return request
  }
}
