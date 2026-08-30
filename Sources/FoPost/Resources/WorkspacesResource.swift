import Foundation

/// Workspaces, the tenant boundary every other resource is scoped to.
public struct WorkspacesResource: Resource {
  let transport: Transport

  /// Every workspace the key can reach. A key bound to a single workspace
  /// sees only that one.
  public func list() async throws -> [Workspace] {
    try await httpGet("/workspaces", as: [Workspace].self)
  }

  /// One workspace with its connected accounts.
  public func get(_ id: String) async throws -> Workspace {
    try await httpGet("/workspaces/\(escapePath(id))", as: Workspace.self)
  }

  /// Adds a workspace. Plans cap how many an account may have, so this
  /// answers 402 once the limit is reached.
  public func create(_ body: CreateWorkspaceRequest) async throws -> Workspace {
    try await httpPost("/workspaces", body: body, as: Workspace.self)
  }

  /// Edits a workspace.
  public func update(_ id: String, _ body: UpdateWorkspaceRequest) async throws -> Workspace {
    try await httpPut("/workspaces/\(escapePath(id))", body: body, as: Workspace.self)
  }

  /// Removes a workspace and everything scoped to it.
  public func delete(_ id: String) async throws {
    try await httpDelete("/workspaces/\(escapePath(id))")
  }

  /// A workspace's follower and post totals.
  public func analytics(_ id: String) async throws -> WorkspaceAnalytics {
    try await httpGet("/workspaces/\(escapePath(id))/analytics", as: WorkspaceAnalytics.self)
  }
}
