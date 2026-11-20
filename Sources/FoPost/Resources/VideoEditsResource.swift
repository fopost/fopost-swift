import Foundation

/// Video edits: trims, cuts, subtitles, clips and more, run as a background job
/// that writes the result into the media library. Needs the `posts` scope; an
/// operation that uses AI also needs `ai`.
public struct VideoEditsResource: Resource {
  let transport: Transport

  /// Every operation, whether it can run here, and whether it uses AI.
  public func ops() async throws -> [VideoEditOpInfo] {
    try await httpGet("/video-edits/ops", as: [VideoEditOpInfo].self)
  }

  /// Recent jobs in a workspace, or on one video. Name a workspace, a media
  /// id, or both. `limit` defaults to 20.
  public func list(workspaceID: String? = nil, mediaID: String? = nil, limit: Int? = nil)
    async throws -> [VideoEditJob]
  {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("media_id", mediaID)
    query.add("limit", limit)
    return try await httpGet("/video-edits", query: query, as: [VideoEditJob].self)
  }

  /// Queues a job. It comes back `queued`; poll ``get(_:workspaceID:)`` for the result.
  public func create(_ body: CreateVideoEditRequest) async throws -> VideoEditJob {
    try await httpPost("/video-edits", body: body, as: VideoEditJob.self)
  }

  /// One job.
  public func get(_ id: String, workspaceID: String? = nil) async throws -> VideoEditJob {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet(
      "/video-edits/\(escapePath(id))", query: query, as: VideoEditJob.self)
  }
}
