import Foundation

/// Designs: stories, posts, carousels, thumbnails, cards and collages built in
/// the editor, their saved versions, and exports into the media library. Needs
/// the `posts` scope; ``textToSlides(_:)`` also needs `ai`.
public struct DesignsResource: Resource {
  let transport: Transport

  /// The workspace's designs, most recently updated first, without their documents.
  public func list(_ params: DesignListParams) async throws -> [Design] {
    try await httpGet("/designs", query: params.query, as: [Design].self)
  }

  /// Creates a design.
  public func create(_ body: CreateDesignRequest) async throws -> Design {
    try await httpPost("/designs", body: body, as: Design.self)
  }

  /// One design, with its document.
  public func get(_ id: String) async throws -> Design {
    try await httpGet("/designs/\(escapePath(id))", as: Design.self)
  }

  /// Edits a design. Set `createVersion` to also save the result as a version.
  public func update(_ id: String, _ body: UpdateDesignRequest) async throws -> DesignSaveResult {
    try await httpPatch(
      "/designs/\(escapePath(id))", body: body, unwrap: false, as: DesignSaveResult.self)
  }

  /// Deletes a design.
  @discardableResult
  public func delete(_ id: String) async throws -> DesignDeleted {
    try await httpDelete("/designs/\(escapePath(id))", as: DesignDeleted.self)
  }

  /// The design's saved versions, newest first. Documents are left out unless
  /// `includeDocument` is true.
  public func versions(_ id: String, includeDocument: Bool = false) async throws
    -> [DesignVersion]
  {
    var query = Query()
    query.add("include", includeDocument ? "document" : nil)
    return try await httpGet(
      "/designs/\(escapePath(id))/versions", query: query, as: [DesignVersion].self)
  }

  /// Puts a saved version's document back on the design.
  public func restoreVersion(_ id: String, versionID: String) async throws -> DesignSaveResult {
    try await httpPost(
      "/designs/\(escapePath(id))/versions/\(escapePath(versionID))/restore", unwrap: false,
      as: DesignSaveResult.self)
  }

  /// Copies a design. The copy is named `name`, or the original's name plus "(Copy)".
  public func duplicate(_ id: String, name: String? = nil) async throws -> Design {
    try await httpPost(
      "/designs/\(escapePath(id))/duplicate", body: DuplicateDesignRequest(name: name),
      as: Design.self)
  }

  /// Renders a design into the media library as images, a PDF or a video.
  public func export(_ id: String, _ body: ExportDesignRequest) async throws -> DesignExport {
    try await httpPost("/designs/\(escapePath(id))/export", body: body, as: DesignExport.self)
  }

  /// Creates one design per row from a template design.
  public func bulk(_ id: String, _ body: BulkDesignsRequest) async throws -> [Design] {
    try await httpPost("/designs/\(escapePath(id))/bulk", body: body, as: [Design].self)
  }

  /// Posts that use media exported from this design, newest first.
  public func posts(_ id: String) async throws -> [DesignPost] {
    try await httpGet("/designs/\(escapePath(id))/posts", as: [DesignPost].self)
  }

  /// Writes a carousel outline from long text or a post. Nothing is saved;
  /// build a design from the outline. Spends AI balance.
  public func textToSlides(_ body: TextToSlidesRequest) async throws -> SlidesOutline {
    try await httpPost("/designs/text-to-slides", body: body, as: SlidesOutline.self)
  }

  /// Creates a design that lays out a post's text.
  public func fromPost(_ body: DesignFromPostRequest) async throws -> Design {
    try await httpPost("/designs/from-post", body: body, as: Design.self)
  }
}

private struct DuplicateDesignRequest: Encodable, Sendable {
  let name: String?
}
