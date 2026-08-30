import Foundation

/// Connected social accounts.
public struct AccountsResource: Resource {
  let transport: Transport

  /// The connected accounts the key can reach, optionally narrowed to one
  /// workspace.
  public func list(workspaceID: String? = nil) async throws -> [Account] {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/accounts", query: query, as: [Account].self)
  }

  /// One account.
  public func get(_ id: String) async throws -> AccountDetail {
    try await httpGet("/accounts/\(escapePath(id))", as: AccountDetail.self)
  }

  /// Connects an account with credentials.
  public func create(_ body: CreateAccountRequest) async throws -> CreatedAccount {
    try await httpPost("/accounts", body: body, as: CreatedAccount.self)
  }

  /// Disconnects an account.
  public func delete(_ id: String) async throws {
    try await httpDelete("/accounts/\(escapePath(id))")
  }

  /// Toggles which account leads its platform in the workspace.
  @discardableResult
  public func setPrimary(_ id: String) async throws -> PrimaryResult {
    try await httpPost("/accounts/\(escapePath(id))/primary", as: PrimaryResult.self)
  }

  /// Checks an account's credentials against the platform.
  public func validate(_ id: String) async throws -> ValidationResult {
    try await httpPost("/accounts/\(escapePath(id))/validate", as: ValidationResult.self)
  }

  /// An account's health. Pass `refresh` to re-check it live rather than
  /// reading the last stored result.
  public func health(_ id: String, refresh: Bool = false) async throws -> AccountHealth {
    var query = Query()
    if refresh { query.add("refresh", true) }
    return try await httpGet(
      "/accounts/\(escapePath(id))/health", query: query, as: AccountHealth.self)
  }

  /// The health of every account, optionally narrowed to one workspace.
  public func healthSummary(workspaceID: String? = nil) async throws -> HealthSummary {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/accounts/health", query: query, as: HealthSummary.self)
  }

  /// Renews an account's OAuth token ahead of its expiry.
  @discardableResult
  public func refreshToken(_ id: String) async throws -> RefreshedToken {
    try await httpPost("/accounts/\(escapePath(id))/refresh-token", as: RefreshedToken.self)
  }

  /// An account's stored snapshots, newest first. A nil limit leaves the
  /// API's default of 30 in place.
  public func analytics(_ id: String, limit: Int? = nil) async throws -> AccountAnalyticsHistory {
    var query = Query()
    query.add("limit", limit)
    return try await httpGet(
      "/accounts/\(escapePath(id))/analytics", query: query, as: AccountAnalyticsHistory.self)
  }
}
