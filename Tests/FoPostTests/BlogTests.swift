import Foundation
import XCTest

@testable import FoPost

final class BlogTests: XCTestCase {
  private static let settings = """
    {"siteUrl":"https://yourbrand.com","topic":"Scheduling tools","audience":null,
     "language":"en","locationCode":2840,"cadencePerWeek":2,"reviewHoldDays":3,
     "autoPublish":false,"imageTier":"standard","inBodyImages":2,"minWords":900,
     "maxWords":1600,"brandVoiceId":"bv_1","targetKind":"website","targetAccountId":null,
     "targetPlatform":null,"websiteUrl":"https://yourbrand.com/hooks/fopost",
     "hasWebsiteSecret":true,"keywordDataAvailable":true,
     "updatedAt":"2026-10-01T09:00:00.000Z"}
    """

  private static let keyword = """
    {"id":"kw_1","keyword":"best time to post","searchVolume":2400,"difficulty":31,
     "cpc":1.2,"intent":"informational","source":"provider","status":"planned",
     "plannedFor":"2026-10-14","createdAt":"2026-10-01T09:00:00.000Z"}
    """

  private static let article = """
    {"id":"art_1","title":"Best time to post","slug":"best-time-to-post","keyword":"best time to post",
     "excerpt":null,"metaTitle":null,"metaDescription":null,
     "featuredImage":{"mediaId":"med_1","url":"https://cdn.yourbrand.com/a.jpg","alt":"A clock"},
     "tags":["scheduling"],"wordCount":0,"status":"queued","origin":"user",
     "reviewUntil":null,"publishAt":null,"publishedAt":null,"publishedUrl":null,"error":null,
     "createdAt":"2026-10-01T09:00:00.000Z","updatedAt":"2026-10-01T09:00:00.000Z"}
    """

  // MARK: - Settings

  func testGetSettingsPutsTheWorkspaceOnTheQuery() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.settings)}")])
    let client = try makeStubClient()

    let settings = try await client.blog.getSettings(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/blog/settings")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    XCTAssertEqual(settings.targetKind, .website)
    XCTAssertEqual(settings.brandVoiceID, "bv_1")
    XCTAssertEqual(settings.hasWebsiteSecret, true)
  }

  func testUpdateSettingsSendsTheWorkspaceInTheBodyAndKeepsTheSecret() async throws {
    StubURLProtocol.script([
      .json("{\"data\":\(Self.settings),\"websiteSecret\":\"whsec_abc\"}")
    ])
    let client = try makeStubClient()

    let updated = try await client.blog.updateSettings(
      workspaceID: "ws_1",
      UpdateBlogSettingsRequest(
        cadencePerWeek: 2, brandVoiceID: .some(nil), targetKind: .website,
        websiteUrl: "https://yourbrand.com/hooks/fopost"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/blog/settings")
    XCTAssertNil(request.query["workspaceId"])
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["cadencePerWeek"] as? Int, 2)
    XCTAssertEqual(body["targetKind"] as? String, "website")
    // Inner nil clears; an unset field is left out entirely.
    XCTAssertTrue(body["brandVoiceId"] is NSNull, request.bodyString)
    XCTAssertNil(body["topic"], request.bodyString)
    XCTAssertEqual(updated.websiteSecret, "whsec_abc")
    XCTAssertEqual(updated.data.websiteUrl, "https://yourbrand.com/hooks/fopost")
  }

  func testRotateAndTestWebsitePostTheWorkspace() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"websiteSecret\":\"whsec_new\"}}"),
      .json("{\"data\":{\"ok\":true,\"status\":200,\"error\":null}}"),
    ])
    let client = try makeStubClient()

    let secret = try await client.blog.rotateWebsiteSecret(workspaceID: "ws_1")
    let test = try await client.blog.testWebsite(workspaceID: "ws_1")

    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/blog/settings/website-secret")
    XCTAssertEqual(try StubURLProtocol.requests[0].bodyJSON()["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(StubURLProtocol.requests[1].path, "/v1/blog/settings/website-test")
    XCTAssertEqual(secret.websiteSecret, "whsec_new")
    XCTAssertTrue(test.ok)
    XCTAssertEqual(test.status, 200)
  }

  // MARK: - Keywords

  func testListKeywordsJoinsStatusesWithCommas() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.keyword)]}")])
    let client = try makeStubClient()

    let keywords = try await client.blog.listKeywords(
      workspaceID: "ws_1", status: [.suggested, .planned], limit: 50)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/keywords")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    XCTAssertEqual(request.query["status"], "suggested,planned")
    XCTAssertEqual(request.query["limit"], "50")
    XCTAssertEqual(keywords.count, 1)
    XCTAssertEqual(keywords[0].status, .planned)
    XCTAssertEqual(keywords[0].plannedFor, "2026-10-14")
    XCTAssertEqual(keywords[0].difficulty, 31)
  }

  func testPlanKeywordsIsQueuedAndASpentBalanceIsPaymentRequired() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"status\":\"queued\"}}", status: 202),
      .json(
        #"{"error":"insufficient_credits","message":"Balance is empty","upgrade_url":"https://fopost.com/billing"}"#,
        status: 402),
    ])
    let client = try makeStubClient()

    let queued = try await client.blog.planKeywords(workspaceID: "ws_1", seeds: ["scheduling"])
    XCTAssertEqual(queued.status, "queued")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/keywords/plan")
    XCTAssertEqual(try request.bodyJSON()["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(try request.bodyJSON()["seeds"] as? [String], ["scheduling"])

    do {
      _ = try await client.blog.planKeywords(workspaceID: "ws_1")
      XCTFail("expected a 402")
    } catch let error as FoPostError {
      guard case .paymentRequired = error else { return XCTFail("\(error)") }
      XCTAssertEqual(error.code, "insufficient_credits")
      XCTAssertEqual(error.upgradeURL, URL(string: "https://fopost.com/billing"))
    }
  }

  func testAddUpdateAndDeleteKeyword() async throws {
    StubURLProtocol.script([
      .json("{\"data\":\(Self.keyword)}", status: 201),
      .json("{\"data\":\(Self.keyword)}"),
      StubResponse(status: 204),
    ])
    let client = try makeStubClient()

    _ = try await client.blog.addKeyword(
      workspaceID: "ws_1", AddBlogKeywordRequest(keyword: "best time to post"))
    _ = try await client.blog.updateKeyword(
      workspaceID: "ws_1", "kw_1",
      UpdateBlogKeywordRequest(status: .planned, plannedFor: .some(nil)))
    try await client.blog.deleteKeyword(workspaceID: "ws_1", "kw_1")

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests[0].method, "POST")
    XCTAssertEqual(requests[0].path, "/v1/blog/keywords")
    XCTAssertEqual(try requests[0].bodyJSON()["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(try requests[0].bodyJSON()["keyword"] as? String, "best time to post")
    XCTAssertNil(try requests[0].bodyJSON()["plannedFor"])

    XCTAssertEqual(requests[1].method, "PATCH")
    XCTAssertEqual(requests[1].path, "/v1/blog/keywords/kw_1")
    XCTAssertEqual(requests[1].query["workspaceId"], "ws_1")
    XCTAssertEqual(try requests[1].bodyJSON()["status"] as? String, "planned")
    XCTAssertTrue(try requests[1].bodyJSON()["plannedFor"] is NSNull, requests[1].bodyString)
    XCTAssertNil(try requests[1].bodyJSON()["workspaceId"])

    XCTAssertEqual(requests[2].method, "DELETE")
    XCTAssertEqual(requests[2].path, "/v1/blog/keywords/kw_1")
    XCTAssertEqual(requests[2].query["workspaceId"], "ws_1")
  }

  // MARK: - Articles

  func testListArticlesFiltersByStatus() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.article)]}")])
    let client = try makeStubClient()

    let articles = try await client.blog.listArticles(
      workspaceID: "ws_1", status: [.draft, .scheduled], limit: 20)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/articles")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    XCTAssertEqual(request.query["status"], "draft,scheduled")
    XCTAssertEqual(request.query["limit"], "20")
    XCTAssertEqual(articles[0].featuredImage?.mediaID, "med_1")
    XCTAssertEqual(articles[0].origin, .user)
  }

  func testRequestArticleSendsTheWorkspaceInTheBody() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.article)}", status: 202)])
    let client = try makeStubClient()

    let article = try await client.blog.requestArticle(
      workspaceID: "ws_1",
      RequestBlogArticleRequest(keywordID: "kw_1", instructions: "Keep it short."))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/blog/articles")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["keywordId"] as? String, "kw_1")
    XCTAssertEqual(body["instructions"] as? String, "Keep it short.")
    XCTAssertNil(body["title"])
    XCTAssertEqual(article.status, .queued)
  }

  func testGetArticleDecodesTheFullBody() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"art_1","title":"Best time to post","slug":"best-time-to-post",
         "tags":[],"wordCount":1200,"status":"draft","origin":"plan",
         "createdAt":"2026-10-01T09:00:00.000Z","updatedAt":"2026-10-02T09:00:00.000Z",
         "instructions":null,"outline":["Why timing matters","What the data says"],
         "brief":{"sources":3},"bodyMarkdown":"# Best time","bodyHtml":"<h1>Best time</h1>",
         "images":[{"mediaId":"med_2","url":"https://cdn.yourbrand.com/b.jpg","alt":"Chart","position":1}]}}
        """)
    ])
    let client = try makeStubClient()

    let article = try await client.blog.getArticle(workspaceID: "ws_1", "art_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/articles/art_1")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    XCTAssertEqual(article.outline?.count, 2)
    XCTAssertEqual(article.bodyMarkdown, "# Best time")
    XCTAssertEqual(article.images?.first?.position, 1)
    XCTAssertEqual(article.brief, .object(["sources": .number(3)]))
  }

  func testUpdateArticleSplitsClearFromUnset() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"art_1","title":"New title","slug":"new-title","tags":[],"wordCount":1200,
         "status":"draft","origin":"plan","createdAt":"2026-10-01T09:00:00.000Z",
         "updatedAt":"2026-10-02T09:00:00.000Z"}}
        """)
    ])
    let client = try makeStubClient()

    _ = try await client.blog.updateArticle(
      workspaceID: "ws_1", "art_1",
      UpdateBlogArticleRequest(title: "New title", excerpt: .some(nil), publishAt: .some(nil)))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/blog/articles/art_1")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["title"] as? String, "New title")
    XCTAssertTrue(body["excerpt"] is NSNull, request.bodyString)
    XCTAssertTrue(body["publishAt"] is NSNull, request.bodyString)
    XCTAssertNil(body["slug"])
    XCTAssertNil(body["metaTitle"])
  }

  func testLifecycleActionsCarryTheWorkspaceOnTheQuery() async throws {
    StubURLProtocol.script([
      .json("{\"data\":\(Self.article)}", status: 202),
      .json("{\"data\":\(Self.article)}", status: 202),
      .json("{\"data\":\(Self.article)}"),
      StubResponse(status: 204),
    ])
    let client = try makeStubClient()

    _ = try await client.blog.regenerateArticle(workspaceID: "ws_1", "art_1")
    _ = try await client.blog.publishArticle(workspaceID: "ws_1", "art_1")
    _ = try await client.blog.rejectArticle(workspaceID: "ws_1", "art_1")
    try await client.blog.deleteArticle(workspaceID: "ws_1", "art_1")

    let requests = StubURLProtocol.requests
    XCTAssertEqual(
      requests.map(\.path),
      [
        "/v1/blog/articles/art_1/regenerate", "/v1/blog/articles/art_1/publish",
        "/v1/blog/articles/art_1/reject", "/v1/blog/articles/art_1",
      ])
    XCTAssertEqual(requests.map(\.method), ["POST", "POST", "POST", "DELETE"])
    for request in requests {
      XCTAssertEqual(request.query["workspaceId"], "ws_1", request.path)
    }
  }

  func testPublishWithoutATargetIsAConflict() async throws {
    StubURLProtocol.script([
      .json(#"{"error":"no_target","message":"Set a publish target first"}"#, status: 409)
    ])
    let client = try makeStubClient()

    do {
      _ = try await client.blog.publishArticle(workspaceID: "ws_1", "art_1")
      XCTFail("expected a 409")
    } catch let error as FoPostError {
      guard case .conflict = error else { return XCTFail("\(error)") }
      XCTAssertEqual(error.code, "no_target")
    }
  }
}
