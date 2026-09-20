import Foundation

/// Contacts, the people behind the inbox.
///
/// One row per human, however many handles they write from. Contacts are built
/// for you: an inbound inbox item files its author, a reply files whoever you
/// answered, and both fold into whatever is already on file.
///
/// Everything here needs the `inbox` scope — a key that may read a message may
/// read who sent it — except ``conversationAnalytics(workspaceID:accountID:days:sort:page:perPage:)``,
/// which answers counts and reads under `analytics`.
public struct ContactsResource: Resource {
  let transport: Transport

  /// One page of contacts, most recently active first.
  ///
  /// `search` matches a display name or any of their handles; `platform`
  /// narrows to contacts with a handle on that network; `source` is `inbox`,
  /// `radar` or `import`.
  public func list(
    workspaceID: String? = nil, search: String? = nil, platform: String? = nil,
    source: String? = nil, page: Int? = nil, perPage: Int? = nil
  ) async throws -> ContactPage {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("search", search)
    query.add("platform", platform)
    query.add("source", source)
    query.add("page", page)
    query.add("per_page", perPage)
    // `unwrap: false`: the counters sit beside `data`, and unwrapping drops them.
    return try await httpGet("/contacts", query: query, unwrap: false, as: ContactPage.self)
  }

  /// One contact.
  ///
  /// A contact in a workspace the key cannot reach answers `404`, exactly as
  /// an id that never existed does.
  public func get(_ id: String) async throws -> Contact {
    try await httpGet("/contacts/\(escapePath(id))", as: Contact.self)
  }

  /// Files a person by hand.
  ///
  /// It folds into the contact that already holds the first channel, so it
  /// cannot duplicate someone the inbox has already met.
  public func create(_ body: CreateContactRequest) async throws -> Contact {
    try await httpPost("/contacts", body: body, as: Contact.self)
  }

  /// Changes a contact. Only what is set on `body` is sent.
  public func update(_ id: String, _ body: UpdateContactRequest) async throws -> Contact {
    try await httpPatch("/contacts/\(escapePath(id))", body: body, as: Contact.self)
  }

  /// Removes a contact. The messages stay in the inbox, and a later one files
  /// the person again.
  public func delete(_ id: String) async throws {
    try await httpDelete("/contacts/\(escapePath(id))")
  }

  /// The inbox threads one contact appears in, newest first.
  public func conversations(_ id: String, limit: Int? = nil) async throws
    -> [ContactConversation]
  {
    var query = Query()
    query.add("limit", limit)
    return try await httpGet(
      "/contacts/\(escapePath(id))/conversations", query: query, as: [ContactConversation].self)
  }

  /// Imports contacts from CSV text.
  ///
  /// `platform` and `handle` are required columns; `external_id`,
  /// `display_name` and `note` are optional, and every other column is read as
  /// a custom field key. A column matching no field is reported back rather
  /// than stored.
  public func importCSV(workspaceID: String, csv: String) async throws -> ContactImportResult {
    struct Body: Encodable, Sendable {
      let workspaceID: String
      let csv: String

      enum CodingKeys: String, CodingKey {
        case csv
        case workspaceID = "workspace_id"
      }
    }
    return try await httpPost(
      "/contacts/import", body: Body(workspaceID: workspaceID, csv: csv),
      as: ContactImportResult.self)
  }

  /// The columns this workspace keeps about a contact, in display order.
  public func listFields(workspaceID: String) async throws -> [ContactField] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/contacts/fields", query: query, as: [ContactField].self)
  }

  /// Adds a column. A duplicate key answers `409`.
  public func createField(_ body: CreateContactFieldRequest) async throws -> ContactField {
    var query = Query()
    query.add("workspace_id", body.workspaceID)
    return try await httpPost("/contacts/fields", body: body, query: query, as: ContactField.self)
  }

  /// Renames a field, changes its options, or moves it.
  public func updateField(_ id: String, _ body: UpdateContactFieldRequest) async throws
    -> ContactField
  {
    try await httpPatch("/contacts/fields/\(escapePath(id))", body: body, as: ContactField.self)
  }

  /// Removes a field and every contact answer to it.
  public func deleteField(_ id: String) async throws {
    try await httpDelete("/contacts/fields/\(escapePath(id))")
  }

  /// Inbox volume and reply time per thread.
  ///
  /// This one needs the `analytics` scope rather than `inbox`. `days` is the
  /// reporting period, 1 to 365, and the API defaults to 7; `sort` is
  /// `volume`, `slowest` or `recent`.
  public func conversationAnalytics(
    workspaceID: String? = nil, accountID: String? = nil, days: Int? = nil,
    sort: String? = nil, page: Int? = nil, perPage: Int? = nil
  ) async throws -> ConversationAnalytics {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("accountId", accountID)
    query.add("days", days)
    query.add("sort", sort)
    query.add("page", page)
    query.add("per_page", perPage)
    return try await httpGet(
      "/analytics/inbox/conversations", query: query, as: ConversationAnalytics.self)
  }
}
