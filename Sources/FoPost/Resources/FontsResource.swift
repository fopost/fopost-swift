import Foundation

/// Fonts designs can use: the built-in library plus fonts a workspace uploaded.
/// Needs the `posts` scope.
public struct FontsResource: Resource {
  let transport: Transport

  /// The library, plus the workspace's uploaded fonts when one is named.
  public func list(workspaceID: String? = nil) async throws -> FontList {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/fonts", query: query, as: FontList.self)
  }

  /// Uploads a WOFF2, WOFF, TTF or OTF file of up to 5 MB. `family` defaults
  /// to the file name, `weight` to 400 and `style` to normal.
  public func upload(
    workspaceID: String, file: UploadFile, family: String? = nil, weight: Int? = nil,
    style: FontStyle? = nil
  ) async throws -> UploadedFont {
    var form = MultipartForm()
    form.addField("workspace_id", workspaceID)
    form.addField("family", family)
    form.addField("weight", weight.map(String.init))
    form.addField("style", style?.rawValue)
    form.addFile(
      field: "file", filename: file.name, mimeType: file.mimeType, data: try file.bytes())
    return try await httpUpload("/fonts", form: form, as: UploadedFont.self)
  }

  /// Uploads a font file from disk.
  public func upload(
    workspaceID: String, fileURL: URL, family: String? = nil, weight: Int? = nil,
    style: FontStyle? = nil
  ) async throws -> UploadedFont {
    try await upload(
      workspaceID: workspaceID, file: UploadFile(contentsOf: fileURL), family: family,
      weight: weight, style: style)
  }

  /// Uploads a font from bytes in memory.
  public func upload(
    workspaceID: String, filename: String, data: Data, family: String? = nil,
    weight: Int? = nil, style: FontStyle? = nil
  ) async throws -> UploadedFont {
    try await upload(
      workspaceID: workspaceID, file: UploadFile(name: filename, data: data), family: family,
      weight: weight, style: style)
  }

  /// Deletes an uploaded font.
  public func delete(_ id: String) async throws {
    try await httpDelete("/fonts/\(escapePath(id))")
  }
}
