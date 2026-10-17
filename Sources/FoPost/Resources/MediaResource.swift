import Foundation

/// The media library. Uploads count against the plan's storage allowance and
/// are reachable with the `posts` scope.
public struct MediaResource: Resource {
  let transport: Transport

  /// The multipart ceiling assumed when ``limits(workspaceID:)`` cannot be read.
  static let fallbackMultipartMaxFileBytes: Int64 = 100 * 1024 * 1024

  /// The workspace's media library.
  public func list(workspaceID: String) async throws -> [MediaLibraryItem] {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/media", query: query, as: [MediaLibraryItem].self)
  }

  /// What the account may upload: the per-file ceiling, the multipart ceiling,
  /// and the tier more connected accounts would unlock.
  public func limits(workspaceID: String? = nil) async throws -> UploadLimits {
    var query = Query()
    query.add("workspaceId", workspaceID)
    return try await httpGet("/media/limits", query: query, as: UploadLimits.self)
  }

  /// Stores files in the workspace's media library through one multipart
  /// request. Up to five files per call, each within the multipart ceiling
  /// ``UploadLimits/multipartMaxFileBytes``; bigger files take
  /// ``uploadDirect(workspaceID:file:options:)``.
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
        field: "files", filename: file.name, mimeType: file.mimeType, data: try file.bytes())
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

  /// Reserves a presigned slot for a direct upload of `size` bytes, up to the
  /// account's ``UploadLimits/maxFileBytes``. The bytes then go straight to
  /// `uploadUrl` with `headers`. An oversize file is a 413 `file_too_large`.
  public func presign(
    workspaceID: String, filename: String, mimeType: String, size: Int64,
    options: PresignOptions = PresignOptions()
  ) async throws -> PresignedUpload {
    try await httpPost(
      "/media/presign",
      body: PresignRequest(
        workspaceId: workspaceID, filename: filename, mimeType: mimeType, size: size,
        folderId: options.folderID, origin: options.origin, brandRole: options.brandRole,
        brandVoiceId: options.brandVoiceID, personConsent: options.personConsent),
      as: PresignedUpload.self)
  }

  /// Turns a finished direct upload into a library item.
  public func complete(uploadID: String) async throws -> UploadedMedia {
    try await httpPost(
      "/media/presign/\(escapePath(uploadID))/complete", as: UploadedMedia.self)
  }

  /// Presigns, PUTs the bytes to the returned URL, and completes the upload.
  public func uploadDirect(
    workspaceID: String, filename: String, mimeType: String, data: Data,
    options: PresignOptions = PresignOptions()
  ) async throws -> UploadedMedia {
    try await uploadDirect(
      workspaceID: workspaceID, file: UploadFile(name: filename, data: data, mimeType: mimeType),
      options: options)
  }

  /// Presigns, streams the file off disk to the returned URL, and completes
  /// the upload. Nothing but the file's size is read into memory first.
  public func uploadDirect(
    workspaceID: String, fileURL: URL, filename: String? = nil, mimeType: String? = nil,
    options: PresignOptions = PresignOptions()
  ) async throws -> UploadedMedia {
    try await uploadDirect(
      workspaceID: workspaceID,
      file: UploadFile(contentsOf: fileURL, name: filename, mimeType: mimeType),
      options: options)
  }

  /// Presigns, sends the file's bytes, and completes the upload.
  public func uploadDirect(
    workspaceID: String, file: UploadFile, options: PresignOptions = PresignOptions()
  ) async throws -> UploadedMedia {
    let presigned = try await presign(
      workspaceID: workspaceID, filename: file.name, mimeType: file.resolvedMimeType,
      size: try file.size(), options: options)
    guard let url = URL(string: presigned.uploadUrl) else {
      throw FoPostError.decoding(
        message: "The presigned upload URL is not a valid URL.", body: Data())
    }
    let method = presigned.method ?? "PUT"
    let headers = presigned.headers ?? [:]
    switch file.source {
    case .data(let data):
      try await transport.putRaw(to: url, method: method, headers: headers, body: data)
    case .file(let fileURL):
      try await transport.putRaw(
        to: url, method: method, headers: headers, fromFile: fileURL, size: try file.size())
    }
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
  let size: Int64
  let folderId: String?
  let origin: String?
  let brandRole: String?
  let brandVoiceId: String?
  let personConsent: PersonConsent?
}
