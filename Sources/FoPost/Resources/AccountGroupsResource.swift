import Foundation

/// Account groups, named sets of accounts a post can target at once.
public struct AccountGroupsResource: Resource {
  let transport: Transport

  /// The groups the key can reach, optionally narrowed to one workspace.
  public func list(workspaceID: String? = nil) async throws -> [AccountGroup] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/account-groups", query: query, as: [AccountGroup].self)
  }

  /// One group.
  public func get(_ id: String) async throws -> AccountGroup {
    try await httpGet("/account-groups/\(escapePath(id))", as: AccountGroup.self)
  }

  /// Adds a group to a workspace.
  public func create(_ body: CreateAccountGroupRequest) async throws -> AccountGroup {
    try await httpPost("/account-groups", body: body, as: AccountGroup.self)
  }

  /// Renames a group.
  public func update(_ id: String, _ body: UpdateAccountGroupRequest) async throws
    -> AccountGroup
  {
    try await httpPatch("/account-groups/\(escapePath(id))", body: body, as: AccountGroup.self)
  }

  /// Removes a group. The accounts in it stay connected.
  public func delete(_ id: String) async throws {
    try await httpDelete("/account-groups/\(escapePath(id))")
  }

  /// Replaces a group's members with `accountIDs`.
  public func setMembers(_ id: String, accountIDs: [String]) async throws -> AccountGroup {
    try await httpPut(
      "/account-groups/\(escapePath(id))/members",
      body: SetAccountGroupMembersBody(accountIDs: accountIDs), as: AccountGroup.self)
  }
}

struct SetAccountGroupMembersBody: Encodable, Sendable {
  let accountIDs: [String]

  enum CodingKeys: String, CodingKey {
    case accountIDs = "account_ids"
  }
}
