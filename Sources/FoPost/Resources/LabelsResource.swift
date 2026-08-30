import Foundation

/// Labels, the campaign tags posts are grouped by.
public struct LabelsResource: Resource {
  let transport: Transport

  /// The labels the key can reach, optionally narrowed to one workspace.
  public func list(workspaceID: String? = nil) async throws -> [Label] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/labels", query: query, as: [Label].self)
  }

  /// One label.
  public func get(_ id: String) async throws -> Label {
    try await httpGet("/labels/\(escapePath(id))", as: Label.self)
  }

  /// Adds a label to a workspace.
  public func create(_ body: CreateLabelRequest) async throws -> Label {
    try await httpPost("/labels", body: body, as: Label.self)
  }

  /// Renames or recolors a label.
  public func update(_ id: String, _ body: UpdateLabelRequest) async throws -> Label {
    try await httpPut("/labels/\(escapePath(id))", body: body, as: Label.self)
  }

  /// Removes a label and unlinks it from every post carrying it.
  public func delete(_ id: String) async throws {
    try await httpDelete("/labels/\(escapePath(id))")
  }
}
