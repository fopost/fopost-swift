import Foundation

/// The workspace knowledge base: what the workspace has told FoPost about itself.
///
/// A source is an FAQ, a note, a page on your own site, or a plain-text/CSV item
/// from the media library. Retrieval over these is what grounds a drafted inbox
/// reply in your own answers instead of an invented one. Needs the `inbox` scope.
public struct KnowledgeResource: Resource {
  let transport: Transport

  /// Every source in the workspace. Only a `ready` one is searched.
  public func list(workspaceID: String? = nil) async throws -> [KnowledgeSource] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/knowledge/sources", query: query, as: [KnowledgeSource].self)
  }

  /// Adds a source and queues it for indexing, so it comes back `pending`.
  public func create(_ body: CreateKnowledgeSourceRequest) async throws -> KnowledgeSource {
    try await httpPost("/knowledge/sources", body: body, as: KnowledgeSource.self)
  }

  /// Edits a source. Changing the content or the URL re-indexes it.
  public func update(_ id: String, _ body: UpdateKnowledgeSourceRequest) async throws
    -> KnowledgeSource
  {
    try await httpPatch(
      "/knowledge/sources/\(escapePath(id))", body: body, as: KnowledgeSource.self)
  }

  /// Removes a source and every passage indexed from it.
  public func delete(_ id: String) async throws {
    try await httpDelete("/knowledge/sources/\(escapePath(id))")
  }

  /// Reads the source again — a `url` source is re-fetched. Returns once the
  /// re-index is queued, not once it has finished.
  @discardableResult
  public func sync(_ id: String) async throws -> KnowledgeSyncResult {
    try await httpPost("/knowledge/sources/\(escapePath(id))/sync", as: KnowledgeSyncResult.self)
  }

  /// The passages closest to a question, best first. An empty array is the
  /// honest answer when nothing stored answers it. `topK` defaults to 5 and
  /// caps at 20.
  public func search(
    _ q: String, topK: Int? = nil, brandVoiceID: String? = nil, workspaceID: String? = nil
  ) async throws -> [KnowledgeMatch] {
    var query = Query()
    query.add("q", q)
    query.add("top_k", topK)
    query.add("brand_voice_id", brandVoiceID)
    query.add("workspace_id", workspaceID)
    return try await httpGet("/knowledge/search", query: query, as: [KnowledgeMatch].self)
  }
}
