import Foundation

/// Posts, publishing, deliveries, and bulk operations.
public struct PostsResource: Resource {
  let transport: Transport

  /// One page of posts.
  public func list(_ params: PostListParams = PostListParams()) async throws -> Page<Post> {
    try await httpGet("/posts", query: params.query, unwrap: false, as: Page<Post>.self)
  }

  /// Walks every matching post, one page at a time.
  public func all(_ params: PostListParams = PostListParams()) -> AsyncThrowingStream<
    Post, any Error
  > {
    AsyncThrowingStream { continuation in
      let task = Task {
        var walk = params
        walk.page = params.page ?? 1
        walk.perPage = params.perPage ?? 30
        do {
          while true {
            try Task.checkCancellation()
            let page = try await list(walk)
            for post in page.data { continuation.yield(post) }
            guard !page.data.isEmpty else { break }
            if let last = page.meta?.lastPage {
              guard (walk.page ?? 1) < last else { break }
            } else if page.data.count < (walk.perPage ?? 30) {
              break
            }
            walk.page = (walk.page ?? 1) + 1
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// One post.
  public func get(_ id: String) async throws -> Post {
    try await httpGet("/posts/\(escapePath(id))", as: Post.self)
  }

  /// Composes a draft or a scheduled post.
  public func create(_ body: CreatePostRequest) async throws -> Post {
    try await httpPost("/posts", body: body, as: Post.self)
  }

  /// Edits a post that has not been published.
  public func update(_ id: String, _ body: UpdatePostRequest) async throws -> Post {
    try await httpPut("/posts/\(escapePath(id))", body: body, as: Post.self)
  }

  /// Removes a post.
  public func delete(_ id: String) async throws {
    try await httpDelete("/posts/\(escapePath(id))")
  }

  /// Copies a post into a new draft.
  public func duplicate(_ id: String) async throws -> DuplicatedPost {
    try await httpPost("/posts/\(escapePath(id))/duplicate", as: DuplicatedPost.self)
  }

  /// Queues a post for immediate delivery to its accounts. Nothing reaches a
  /// platform without this call or a schedule the user set.
  ///
  /// - Parameters:
  ///   - accountIDs: narrows publishing to a subset of the post's accounts.
  ///   - dryRun: validates without sending anything to a platform.
  @discardableResult
  public func publish(_ id: String, accountIDs: [String]? = nil, dryRun: Bool = false)
    async throws -> PublishResult
  {
    var body: [String: JSONValue] = [:]
    if let accountIDs, !accountIDs.isEmpty {
      body["accountIds"] = .array(accountIDs.map { .string($0) })
    }
    if dryRun { body["options"] = .object(["dryRun": .bool(true)]) }
    return try await httpPost(
      "/posts/\(escapePath(id))/publish", body: body, as: PublishResult.self)
  }

  /// Re-sends the deliveries that failed, leaving successful ones alone.
  @discardableResult
  public func retry(_ id: String, accountIDs: [String]? = nil, includePublished: Bool = false)
    async throws -> RetryResult
  {
    var body: [String: JSONValue] = [:]
    if let accountIDs, !accountIDs.isEmpty {
      body["accountIds"] = .array(accountIDs.map { .string($0) })
    }
    if includePublished { body["includePublished"] = .bool(true) }
    return try await httpPost("/posts/\(escapePath(id))/retry", body: body, as: RetryResult.self)
  }

  /// Stops the deliveries that have not gone out yet.
  @discardableResult
  public func cancel(_ id: String, accountIDs: [String]? = nil) async throws -> CancelResult {
    var body: [String: JSONValue] = [:]
    if let accountIDs, !accountIDs.isEmpty {
      body["accountIds"] = .array(accountIDs.map { .string($0) })
    }
    return try await httpPost("/posts/\(escapePath(id))/cancel", body: body, as: CancelResult.self)
  }

  /// Checks a post against every target platform without publishing.
  public func preflight(_ id: String) async throws -> PreflightResult {
    try await httpPost("/posts/\(escapePath(id))/preflight", as: PreflightResult.self)
  }

  /// The current delivery record per account.
  public func deliveries(_ id: String) async throws -> [Delivery] {
    try await httpGet("/posts/\(escapePath(id))/deliveries", as: [Delivery].self)
  }

  /// Every publish attempt made for a post, newest first.
  public func publishRuns(_ id: String) async throws -> [PublishRun] {
    try await httpGet("/posts/\(escapePath(id))/publish-runs", as: [PublishRun].self)
  }

  /// A post's performance across the platforms it reached.
  public func analytics(_ id: String) async throws -> PostAnalytics {
    try await httpGet("/posts/\(escapePath(id))/analytics", as: PostAnalytics.self)
  }

  // MARK: - Bulk

  /// Moves a selection's schedule by `offsetMinutes`, which may be negative
  /// but never zero. Only drafts and scheduled posts can be shifted, and one
  /// ineligible post in the selection changes nothing at all.
  @discardableResult
  public func bulkShift(workspaceID: String, postIDs: [String], offsetMinutes: Int) async throws
    -> BulkResult
  {
    try await bulk([
      "action": "shift",
      "workspace_id": .string(workspaceID),
      "post_ids": .array(postIDs.map { .string($0) }),
      "offset_minutes": .int(offsetMinutes),
    ])
  }

  /// Relabels a selection.
  @discardableResult
  public func bulkLabel(
    workspaceID: String, postIDs: [String], labelIDs: [String],
    mode: BulkLabelMode = .replace
  ) async throws -> BulkResult {
    try await bulk([
      "action": "label",
      "workspace_id": .string(workspaceID),
      "post_ids": .array(postIDs.map { .string($0) }),
      "label_ids": .array(labelIDs.map { .string($0) }),
      "mode": .string(mode.rawValue),
    ])
  }

  /// Removes a selection of posts in one transaction.
  @discardableResult
  public func bulkDelete(workspaceID: String, postIDs: [String]) async throws -> BulkResult {
    try await bulk([
      "action": "delete",
      "workspace_id": .string(workspaceID),
      "post_ids": .array(postIDs.map { .string($0) }),
    ])
  }

  private func bulk(_ body: [String: JSONValue]) async throws -> BulkResult {
    try await httpPost("/posts/bulk", body: body, unwrap: false, as: BulkResult.self)
  }

  // MARK: - Bulk import

  /// Checks a CSV without creating anything.
  public func validateBulkImport(workspaceID: String, filename: String = "posts.csv", csv: Data)
    async throws -> BulkImportValidation
  {
    try await httpUpload(
      "/posts/bulk-import/validate",
      form: csvForm(workspaceID: workspaceID, filename: filename, csv: csv),
      as: BulkImportValidation.self)
  }

  /// Creates the posts a CSV describes.
  public func commitBulkImport(workspaceID: String, filename: String = "posts.csv", csv: Data)
    async throws -> BulkImportResult
  {
    try await httpUpload(
      "/posts/bulk-import/commit",
      form: csvForm(workspaceID: workspaceID, filename: filename, csv: csv),
      as: BulkImportResult.self)
  }

  /// Deletes every post a committed batch created.
  @discardableResult
  public func rollbackBulkImport(batchID: String) async throws -> MessageResponse {
    try await httpDelete("/posts/bulk-import/\(escapePath(batchID))", as: MessageResponse.self)
  }

  private func csvForm(workspaceID: String, filename: String, csv: Data) -> MultipartForm {
    var form = MultipartForm()
    form.addField("workspace_id", workspaceID)
    form.addFile(field: "file", filename: filename, mimeType: "text/csv", data: csv)
    return form
  }
}
