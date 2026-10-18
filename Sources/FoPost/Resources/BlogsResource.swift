import Foundation

/// Articles and products that already live on a connected site, addressed by the
/// platform's own ids rather than FoPost ids.
///
/// Reads need the `posts` scope; anything that changes the site needs `posts` and
/// `publish`. An account on a platform that cannot manage articles answers 400
/// `unsupported_platform`.
///
/// An update changes the live article in place and never creates a second post,
/// so a link already shared keeps working.
public struct BlogsResource: Resource {
  let transport: Transport

  private func blogsPath(_ accountID: String) -> String {
    "/accounts/\(escapePath(accountID))/blogs"
  }

  private func articlesPath(_ accountID: String, _ blogID: String) -> String {
    "\(blogsPath(accountID))/\(escapePath(blogID))/articles"
  }

  private func articlePath(_ accountID: String, _ blogID: String, _ articleID: String) -> String {
    "\(articlesPath(accountID, blogID))/\(escapePath(articleID))"
  }

  /// The blogs the account can write to. WordPress reports one, under `default`.
  public func listBlogs(accountID: String) async throws -> [RemoteBlog] {
    try await httpGet(blogsPath(accountID), as: [RemoteBlog].self)
  }

  /// Articles on the blog, newest first, drafts included.
  public func listArticles(
    accountID: String, blogID: String, limit: Int? = nil,
    status: RemoteArticleStatus? = nil, q: String? = nil
  ) async throws -> [RemoteArticle] {
    var query = Query()
    query.add("limit", limit)
    query.add("status", status?.rawValue)
    query.add("q", q)
    return try await httpGet(
      articlesPath(accountID, blogID), query: query, as: [RemoteArticle].self)
  }

  /// One article in full.
  public func getArticle(accountID: String, blogID: String, articleID: String) async throws
    -> RemoteArticle
  {
    try await httpGet(articlePath(accountID, blogID, articleID), as: RemoteArticle.self)
  }

  /// Writes a new article. Needs the `publish` scope.
  public func createArticle(accountID: String, blogID: String, _ body: ArticleRequest) async throws
    -> RemoteArticle
  {
    try await httpPost(articlesPath(accountID, blogID), body: body, as: RemoteArticle.self)
  }

  /// Changes the live article in place; never creates a duplicate.
  public func updateArticle(
    accountID: String, blogID: String, articleID: String, _ body: ArticleRequest
  ) async throws -> RemoteArticle {
    try await httpPatch(
      articlePath(accountID, blogID, articleID), body: body, as: RemoteArticle.self)
  }

  /// Removes the article from the site. This cannot be undone.
  public func deleteArticle(accountID: String, blogID: String, articleID: String) async throws {
    try await httpDelete(articlePath(accountID, blogID, articleID))
  }

  /// The store's products.
  public func listProducts(
    accountID: String, limit: Int? = nil, status: RemoteProductStatus? = nil, q: String? = nil
  ) async throws -> [RemoteProduct] {
    var query = Query()
    query.add("limit", limit)
    query.add("status", status?.rawValue)
    query.add("q", q)
    return try await httpGet(
      "/accounts/\(escapePath(accountID))/products", query: query, as: [RemoteProduct].self)
  }

  /// Changes the product on the store. Only what is set travels.
  public func updateProduct(accountID: String, productID: String, _ body: ProductRequest)
    async throws -> RemoteProduct
  {
    try await httpPatch(
      "/accounts/\(escapePath(accountID))/products/\(escapePath(productID))",
      body: body, as: RemoteProduct.self)
  }
}
