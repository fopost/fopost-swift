import Foundation

/// Blog articles: the keyword plan, the articles written from it, and where
/// they are published.
///
/// An article goes to a website; a post goes to a social network. Every call
/// is scoped to one workspace. Reading, settings and keyword edits need the
/// `posts` scope; ``planKeywords(workspaceID:seeds:)``,
/// ``requestArticle(workspaceID:_:)`` and ``regenerateArticle(workspaceID:_:)``
/// spend AI credits and need `ai`; ``publishArticle(workspaceID:_:)`` needs
/// `publish`.
public struct BlogResource: Resource {
  let transport: Transport

  // MARK: - Settings

  /// How the workspace's blog is planned, written, and published.
  public func getSettings(workspaceID: String) async throws -> BlogSettings {
    try await httpGet("/blog/settings", query: workspace(workspaceID), as: BlogSettings.self)
  }

  /// Changes the settings. Only the fields you set are sent.
  ///
  /// The call that first sets `websiteUrl` answers with
  /// ``BlogSettingsUpdated/websiteSecret``, shown once; later calls carry nil.
  public func updateSettings(
    workspaceID: String, _ body: UpdateBlogSettingsRequest
  ) async throws -> BlogSettingsUpdated {
    // `unwrap: false`: the secret sits beside `data`.
    try await httpPatch(
      "/blog/settings", body: WorkspaceScoped(workspaceID, body), unwrap: false,
      as: BlogSettingsUpdated.self)
  }

  /// Issues a new website signing secret and retires the old one. The new
  /// value is shown once.
  public func rotateWebsiteSecret(workspaceID: String) async throws -> BlogWebsiteSecret {
    try await httpPost(
      "/blog/settings/website-secret", body: WorkspaceBody(workspaceID),
      as: BlogWebsiteSecret.self)
  }

  /// Sends a signed `article.test` delivery to `websiteUrl` and reports what
  /// it answered. A failing endpoint comes back as a `502` error whose body
  /// still carries the status it answered.
  public func testWebsite(workspaceID: String) async throws -> BlogWebsiteTest {
    try await httpPost(
      "/blog/settings/website-test", body: WorkspaceBody(workspaceID), as: BlogWebsiteTest.self)
  }

  // MARK: - Keywords

  /// The keyword plan. `status` narrows it to one or more statuses.
  public func listKeywords(
    workspaceID: String, status: [BlogKeywordStatus]? = nil, limit: Int? = nil
  ) async throws -> [BlogKeyword] {
    var query = workspace(workspaceID)
    query.add("status", status.map { $0.map(\.rawValue).joined(separator: ",") })
    query.add("limit", limit)
    return try await httpGet("/blog/keywords", query: query, as: [BlogKeyword].self)
  }

  /// Queues keyword research from the workspace's topic, or from `seeds`.
  /// Spends AI credits and needs the `ai` scope.
  @discardableResult
  public func planKeywords(workspaceID: String, seeds: [String]? = nil) async throws -> BlogQueued {
    try await httpPost(
      "/blog/keywords/plan", body: PlanBlogKeywordsRequest(workspaceId: workspaceID, seeds: seeds),
      as: BlogQueued.self)
  }

  /// Adds a keyword of your own to the plan.
  public func addKeyword(
    workspaceID: String, _ body: AddBlogKeywordRequest
  ) async throws -> BlogKeyword {
    try await httpPost(
      "/blog/keywords", body: WorkspaceScoped(workspaceID, body), as: BlogKeyword.self)
  }

  /// Changes a keyword's status or planned day.
  public func updateKeyword(
    workspaceID: String, _ id: String, _ body: UpdateBlogKeywordRequest
  ) async throws -> BlogKeyword {
    try await httpPatch(
      "/blog/keywords/\(escapePath(id))", body: body, query: workspace(workspaceID),
      as: BlogKeyword.self)
  }

  /// Removes a keyword from the plan.
  public func deleteKeyword(workspaceID: String, _ id: String) async throws {
    try await httpDelete("/blog/keywords/\(escapePath(id))", query: workspace(workspaceID))
  }

  // MARK: - Articles

  /// The articles, newest first, without their bodies.
  public func listArticles(
    workspaceID: String, status: [BlogArticleStatus]? = nil, limit: Int? = nil
  ) async throws -> [BlogArticle] {
    var query = workspace(workspaceID)
    query.add("status", status.map { $0.map(\.rawValue).joined(separator: ",") })
    query.add("limit", limit)
    return try await httpGet("/blog/articles", query: query, as: [BlogArticle].self)
  }

  /// Queues an article. One of `title`, `keyword` or `keywordID` is required.
  /// The answer is the article in ``BlogArticleStatus/queued``; poll
  /// ``getArticle(workspaceID:_:)`` or subscribe to `article.published`.
  /// Spends AI credits and needs the `ai` scope.
  public func requestArticle(
    workspaceID: String, _ body: RequestBlogArticleRequest
  ) async throws -> BlogArticle {
    try await httpPost(
      "/blog/articles", body: WorkspaceScoped(workspaceID, body), as: BlogArticle.self)
  }

  /// One article with its body, outline, brief and images.
  public func getArticle(workspaceID: String, _ id: String) async throws -> BlogArticleFull {
    try await httpGet(
      "/blog/articles/\(escapePath(id))", query: workspace(workspaceID), as: BlogArticleFull.self)
  }

  /// Edits a draft or scheduled article. Anything else answers `409`.
  public func updateArticle(
    workspaceID: String, _ id: String, _ body: UpdateBlogArticleRequest
  ) async throws -> BlogArticleFull {
    try await httpPatch(
      "/blog/articles/\(escapePath(id))", body: body, query: workspace(workspaceID),
      as: BlogArticleFull.self)
  }

  /// Writes the article again from the same brief. Spends AI credits and
  /// needs the `ai` scope.
  public func regenerateArticle(workspaceID: String, _ id: String) async throws -> BlogArticle {
    try await httpPost(
      "/blog/articles/\(escapePath(id))/regenerate", query: workspace(workspaceID),
      as: BlogArticle.self)
  }

  /// Publishes the article to the configured target. Answers `409 no_target`
  /// when the workspace has none. Needs the `publish` scope.
  public func publishArticle(workspaceID: String, _ id: String) async throws -> BlogArticle {
    try await httpPost(
      "/blog/articles/\(escapePath(id))/publish", query: workspace(workspaceID),
      as: BlogArticle.self)
  }

  /// Rejects a draft so it never publishes.
  public func rejectArticle(workspaceID: String, _ id: String) async throws -> BlogArticle {
    try await httpPost(
      "/blog/articles/\(escapePath(id))/reject", query: workspace(workspaceID),
      as: BlogArticle.self)
  }

  /// Removes an article. A published copy on the target stays where it is.
  public func deleteArticle(workspaceID: String, _ id: String) async throws {
    try await httpDelete("/blog/articles/\(escapePath(id))", query: workspace(workspaceID))
  }

  private func workspace(_ id: String) -> Query {
    var query = Query()
    query.add("workspaceId", id)
    return query
  }
}

extension Resource {
  /// A DELETE with a query string and no response body.
  func httpDelete(_ path: String, query: Query) async throws {
    try await transport.send(
      HTTPRequest(method: "DELETE", path: path, query: query.items, unwrap: false))
  }
}

/// A body that is only the workspace id.
private struct WorkspaceBody: Encodable, Sendable {
  let workspaceId: String
  init(_ workspaceId: String) { self.workspaceId = workspaceId }
}

/// Adds `workspaceId` beside a request body's own fields.
private struct WorkspaceScoped<Body: Encodable & Sendable>: Encodable, Sendable {
  let workspaceId: String
  let body: Body

  init(_ workspaceId: String, _ body: Body) {
    self.workspaceId = workspaceId
    self.body = body
  }

  private enum CodingKeys: String, CodingKey { case workspaceId }

  func encode(to encoder: any Encoder) throws {
    try body.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(workspaceId, forKey: .workspaceId)
  }
}
