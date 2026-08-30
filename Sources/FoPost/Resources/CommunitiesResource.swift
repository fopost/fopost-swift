import Foundation

/// The X communities an account can post into.
public struct CommunitiesResource: Resource {
  let transport: Transport

  /// The communities linked to an account.
  public func list(accountID: String) async throws -> [Community] {
    try await httpGet("/accounts/\(escapePath(accountID))/communities", as: [Community].self)
  }

  /// Pulls the account's communities from X and stores them.
  public func sync(accountID: String) async throws -> [Community] {
    try await httpPost(
      "/accounts/\(escapePath(accountID))/communities/sync", as: [Community].self)
  }

  /// Looks a community up on X without linking it.
  public func search(accountID: String, query searchTerm: String) async throws
    -> [CommunitySearchResult]
  {
    var query = Query()
    query.add("q", searchTerm)
    return try await httpGet(
      "/accounts/\(escapePath(accountID))/communities/search", query: query,
      as: [CommunitySearchResult].self)
  }

  /// Links a community to the account by its X id, for the case where search
  /// and sync do not surface it.
  public func add(accountID: String, communityID: String, name: String? = nil) async throws
    -> Community
  {
    var body: [String: JSONValue] = ["communityId": .string(communityID)]
    if let name, !name.isEmpty { body["name"] = .string(name) }
    return try await httpPost(
      "/accounts/\(escapePath(accountID))/communities/manual", body: body, as: Community.self)
  }

  /// Unlinks a community. `id` is ``Community/id``, not the X community id.
  public func remove(accountID: String, id: Int) async throws {
    try await httpDelete("/accounts/\(escapePath(accountID))/communities/\(id)")
  }
}
