import Foundation
import XCTest

@testable import FoPost

final class BlogsTests: XCTestCase {
  private let article = """
    {"data":{"id":"99","blog_id":"11","title":"Spring drop","body_html":"<p>Hello</p>",
    "excerpt":"A short summary","status":"published","author_name":"Store Owner",
    "tags":["news"],"image_url":"https://cdn.example/img.png",
    "url":"https://demo.myshopify.com/blogs/article/spring-drop",
    "published_at":"2026-09-01T10:00:00Z","updated_at":"2026-09-02T10:00:00Z"}}
    """

  func testListsTheBlogsOnTheSite() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[{\"id\":\"11\",\"title\":\"News\",\"handle\":\"news\",\"url\":null}]}")
    ])
    let client = try makeStubClient()

    let blogs = try await client.blogs.listBlogs(accountID: "acc_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs")
    XCTAssertEqual(blogs.first?.id, "11")
    XCTAssertEqual(blogs.first?.title, "News")
    XCTAssertNil(blogs.first?.url)
  }

  func testListsArticlesWithTheFilters() async throws {
    StubURLProtocol.script([.json("{\"data\":[]}")])
    let client = try makeStubClient()

    _ = try await client.blogs.listArticles(
      accountID: "acc_1", blogID: "11", limit: 5, status: .draft, q: "spring")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs/11/articles")
    XCTAssertEqual(request.query["limit"], "5")
    XCTAssertEqual(request.query["status"], "draft")
    XCTAssertEqual(request.query["q"], "spring")
  }

  func testReadsAnArticleIntoItsFields() async throws {
    StubURLProtocol.script([.json(article)])
    let client = try makeStubClient()

    let found = try await client.blogs.getArticle(
      accountID: "acc_1", blogID: "11", articleID: "99")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs/11/articles/99")
    XCTAssertEqual(found.id, "99")
    XCTAssertEqual(found.blogID, "11")
    XCTAssertEqual(found.status, .published)
    XCTAssertEqual(found.tags, ["news"])
    XCTAssertNotNil(found.updatedAt)
  }

  func testCreatesAnArticleWithOnlyTheFieldsSet() async throws {
    StubURLProtocol.script([.json(article, status: 201)])
    let client = try makeStubClient()

    _ = try await client.blogs.createArticle(
      accountID: "acc_1", blogID: "11",
      ArticleRequest(title: "Spring drop", body: "Hello", status: .draft))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs/11/articles")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["title"] as? String, "Spring drop")
    XCTAssertEqual(body["body"] as? String, "Hello")
    XCTAssertEqual(body["status"] as? String, "draft")
    XCTAssertNil(body["excerpt"])
  }

  /// The article is addressed by its own id, so an update never forks a duplicate.
  func testUpdatesTheLiveArticleInPlace() async throws {
    StubURLProtocol.script([.json(article)])
    let client = try makeStubClient()

    _ = try await client.blogs.updateArticle(
      accountID: "acc_1", blogID: "11", articleID: "99",
      ArticleRequest(title: "Spring drop, restocked"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs/11/articles/99")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["title"] as? String, "Spring drop, restocked")
    XCTAssertNil(body["body"])
  }

  func testDeletesAnArticle() async throws {
    StubURLProtocol.script([.json("{\"data\":null}", status: 204)])
    let client = try makeStubClient()

    try await client.blogs.deleteArticle(accountID: "acc_1", blogID: "11", articleID: "99")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/blogs/11/articles/99")
  }

  func testListsAndUpdatesProducts() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":[{\"id\":\"7\",\"title\":\"Mug\",\"status\":\"active\",\"tags\":[],\"price\":\"12.00\",\"currency\":\"USD\"}]}"
      ),
      .json("{\"data\":{\"id\":\"7\",\"title\":\"Mug XL\",\"status\":\"draft\",\"tags\":[]}}"),
    ])
    let client = try makeStubClient()

    let products = try await client.blogs.listProducts(accountID: "acc_1", status: .active)
    XCTAssertEqual(products.first?.price, "12.00")
    XCTAssertEqual(products.first?.currency, "USD")

    let updated = try await client.blogs.updateProduct(
      accountID: "acc_1", productID: "7", ProductRequest(title: "Mug XL", status: .draft))
    XCTAssertEqual(updated.status, .draft)

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.map(\.method), ["GET", "PATCH"])
    XCTAssertEqual(
      requests.map(\.path), ["/v1/accounts/acc_1/products", "/v1/accounts/acc_1/products/7"])
    XCTAssertEqual(requests[0].query["status"], "active")
    XCTAssertEqual(try requests[1].bodyJSON()["title"] as? String, "Mug XL")
  }
}
