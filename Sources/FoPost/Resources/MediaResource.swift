import Foundation

/// The media library. Uploads count against the plan's storage allowance and
/// are reachable with the `posts` scope.
public struct MediaResource: Resource {
  let transport: Transport

  /// The workspace's media library.
  public func list(workspaceID: String) async throws -> [MediaLibraryItem] {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/media", query: query, as: [MediaLibraryItem].self)
  }

  /// Stores files in the workspace's media library. Up to five files per
  /// call, 50 MB each.
  public func upload(workspaceID: String? = nil, files: [UploadFile]) async throws
    -> [UploadedMedia]
  {
    guard !files.isEmpty else {
      throw FoPostError.configuration(message: "At least one file is required.")
    }
    var form = MultipartForm()
    form.addField("workspaceId", workspaceID)
    for file in files {
      form.addFile(
        field: "files", filename: file.name, mimeType: file.mimeType, data: file.data)
    }
    return try await httpUpload("/media/upload", form: form, as: [UploadedMedia].self)
  }

  /// Stores one file in the workspace's media library.
  public func upload(workspaceID: String? = nil, file: UploadFile) async throws -> UploadedMedia {
    let uploaded = try await upload(workspaceID: workspaceID, files: [file])
    guard let first = uploaded.first else {
      throw FoPostError.decoding(
        message: "The upload succeeded but returned no media.", body: Data())
    }
    return first
  }

  /// Reserves a presigned slot for a direct upload of `size` bytes, at most
  /// 50 MB. The bytes then go straight to `uploadUrl` with `headers`.
  public func presign(workspaceID: String, filename: String, mimeType: String, size: Int)
    async throws -> PresignedUpload
  {
    try await httpPost(
      "/media/presign",
      body: PresignRequest(
        workspaceId: workspaceID, filename: filename, mimeType: mimeType, size: size),
      as: PresignedUpload.self)
  }

  /// Turns a finished direct upload into a library item.
  public func complete(uploadID: String) async throws -> UploadedMedia {
    try await httpPost(
      "/media/presign/\(escapePath(uploadID))/complete", as: UploadedMedia.self)
  }

  /// Presigns, PUTs the bytes to the returned URL, and completes the upload.
  public func uploadDirect(workspaceID: String, filename: String, mimeType: String, data: Data)
    async throws -> UploadedMedia
  {
    let presigned = try await presign(
      workspaceID: workspaceID, filename: filename, mimeType: mimeType, size: data.count)
    guard let url = URL(string: presigned.uploadUrl) else {
      throw FoPostError.decoding(
        message: "The presigned upload URL is not a valid URL.", body: Data())
    }
    try await transport.putRaw(
      to: url, method: presigned.method ?? "PUT", headers: presigned.headers ?? [:],
      body: data)
    return try await complete(uploadID: presigned.uploadId)
  }

  /// Removes an asset from the library.
  public func delete(_ id: String) async throws {
    try await httpDelete("/media/\(escapePath(id))")
  }
}

private struct PresignRequest: Encodable, Sendable {
  let workspaceId: String
  let filename: String
  let mimeType: String
  let size: Int
}
