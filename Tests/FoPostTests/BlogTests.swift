import Foundation
import XCTest

@testable import FoPost

final class BlogTests: XCTestCase {
  private static let settings = """
    {"site_url":"https://yourbrand.com","topic":"Scheduling tools","audience":null,
     "goal":"signups","focus_topics":"scheduling, analytics","avoid_topics":"politics",
     "language":"en","location_code":2840,"cadence_per_week":2,"review_hold_days":3,
     "image_tier":"standard","in_body_images":2,"min_words":900,
     "max_words":1600,"brand_voice_id":"bv_1","target_kind":"website","target_account_id":null,
     "target_platform":null,"website_url":"https://yourbrand.com/hooks/fopost",
     "has_website_secret":true,"keyword_data_available":true,
     "plan_run":{"status":"done","error":null,"added":12,"finished_at":"2026-10-01T09:05:00.000Z"},
     "updated_at":"2026-10-01T09:00:00.000Z"}
    """

  private static let keyword = """
    {"id":"kw_1","keyword":"best time to post","search_volume":2400,"difficulty":31,
     "cpc":1.2,"intent":"informational","source":"provider","status":"planned",
     "planned_for":"2026-10-14","fit_reason":"Buyers ask it before choosing a tool",
     "created_at":"2026-10-01T09:00:00.000Z"}
    """

  private static let article = """
    {"id":"art_1","title":"Best time to post","slug":"best-time-to-post","keyword":"best time to post",
     "excerpt":null,"meta_title":null,"meta_description":null,
     "featured_image":{"media_id":"med_1","url":"https://cdn.yourbrand.com/a.jpg","alt":"A clock"},
     "tags":["scheduling"],"word_count":0,"status":"queued","origin":"user",
     "review_until":null,"publish_at":null,"published_at":null,"published_url":null,"error":null,
     "created_at":"2026-10-01T09:00:00.000Z","updated_at":"2026-10-01T09:00:00.000Z"}
    """

  // MARK: - Settings

  func testGetSettingsPutsTheWorkspaceOnTheQuery() async throws {
    StubURLProtocol.script([.json(Self.settings)])
    let client = try makeStubClient()

    let settings = try await client.blog.getSettings(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/blog/settings")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(settings.targetKind, .website)
    XCTAssertEqual(settings.brandVoiceID, "bv_1")
    XCTAssertEqual(settings.hasWebsiteSecret, true)
    XCTAssertEqual(settings.goal, .signups)
    XCTAssertEqual(settings.avoidTopics, "politics")
    XCTAssertEqual(settings.planRun?.status, .done)
    XCTAssertEqual(settings.planRun?.added, 12)
  }

  func testUpdateSettingsSendsTheWorkspaceInTheBodyAndKeepsTheSecret() async throws {
    StubURLProtocol.script([
      .json(String(Self.settings.dropLast()) + ",\"website_secret\":\"whsec_abc\"}")
    ])
    let client = try makeStubClient()

    let updated = try await client.blog.updateSettings(
      workspaceID: "ws_1",
      UpdateBlogSettingsRequest(
        goal: .leads, focusTopics: "scheduling", avoidTopics: .some(nil),
        cadencePerWeek: 2, brandVoiceID: .some(nil), targetKind: .website,
        websiteUrl: "https://yourbrand.com/hooks/fopost"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/blog/settings")
    XCTAssertNil(request.query["workspace_id"])
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["cadencePerWeek"] as? Int, 2)
    XCTAssertEqual(body["targetKind"] as? String, "website")
    // Inner nil clears; an unset field is left out entirely.
    XCTAssertTrue(body["brandVoiceId"] is NSNull, request.bodyString)
    XCTAssertEqual(body["goal"] as? String, "leads")
    XCTAssertEqual(body["focusTopics"] as? String, "scheduling")
    XCTAssertTrue(body["avoidTopics"] is NSNull, request.bodyString)
    XCTAssertNil(body["topic"], request.bodyString)
    XCTAssertEqual(updated.websiteSecret, "whsec_abc")
    XCTAssertEqual(updated.settings.websiteUrl, "https://yourbrand.com/hooks/fopost")
  }

  func testRotateAndTestWebsiteReadThePassAndThe502() async throws {
    StubURLProtocol.script([
      .json("{\"website_secret\":\"whsec_new\"}"),
      .json("{\"http_status\":200}"),
      .json(
        #"{"error":"website_test_failed","message":"Website answered 500","http_status":500}"#,
        status: 502),
    ])
    let client = try makeStubClient(maxAttempts: 1)

    let secret = try await client.blog.rotateWebsiteSecret(workspaceID: "ws_1")
    let test = try await client.blog.testWebsite(workspaceID: "ws_1")

    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/blog/settings/website-secret")
    XCTAssertEqual(try StubURLProtocol.requests[0].bodyJSON()["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(StubURLProtocol.requests[1].path, "/v1/blog/settings/website-test")
    XCTAssertEqual(secret.websiteSecret, "whsec_new")
    XCTAssertTrue(test.ok)
    XCTAssertEqual(test.httpStatus, 200)
    let failed = try await client.blog.testWebsite(workspaceID: "ws_1")
    XCTAssertFalse(failed.ok)
    XCTAssertEqual(failed.httpStatus, 500)
    XCTAssertEqual(failed.error, "Website answered 500")
  }

  // MARK: - Keywords

  func testListKeywordsJoinsStatusesWithCommas() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.keyword)]}")])
    let client = try makeStubClient()

    let keywords = try await client.blog.listKeywords(
      workspaceID: "ws_1", status: [.suggested, .planned], limit: 50)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/keywords")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["status"], "suggested,planned")
    XCTAssertEqual(request.query["limit"], "50")
    XCTAssertEqual(keywords.count, 1)
    XCTAssertEqual(keywords[0].status, .planned)
    XCTAssertEqual(keywords[0].plannedFor, "2026-10-14")
    XCTAssertEqual(keywords[0].difficulty, 31)
    XCTAssertEqual(keywords[0].fitReason, "Buyers ask it before choosing a tool")
  }

  func testSuggestSeedsPostsSeedsAndPromptAndASpentBalanceIsPaymentRequired() async throws {
    StubURLProtocol.script([
      .json(#"{"seeds":["social media calendar","post scheduler"]}"#),
      .json(
        #"{"error":"insufficient_credits","message":"Balance is empty","upgrade_url":"https://fopost.com/billing"}"#,
        status: 402),
    ])
    let client = try makeStubClient()

    let suggested = try await client.blog.suggestSeeds(
      workspaceID: "ws_1", seeds: ["scheduling"], prompt: "Lean into small agencies")
    XCTAssertEqual(suggested.seeds, ["social media calendar", "post scheduler"])
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/blog/keywords/suggest")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["seeds"] as? [String], ["scheduling"])
    XCTAssertEqual(body["prompt"] as? String, "Lean into small agencies")

    do {
      _ = try await client.blog.suggestSeeds(workspaceID: "ws_1")
      XCTFail("expected a 402")
    } catch let error as FoPostError {
      guard case .paymentRequired = error else { return XCTFail("\(error)") }
      XCTAssertEqual(error.code, "insufficient_credits")
    }
    let bare = try StubURLProtocol.requests[1].bodyJSON()
    XCTAssertNil(bare["seeds"])
    XCTAssertNil(bare["prompt"])
  }

  func testPlanKeywordsIsQueuedAndASpentBalanceIsPaymentRequired() async throws {
    StubURLProtocol.script([
      .json("{\"status\":\"queued\"}", status: 202),
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
      .json(Self.keyword, status: 201),
      .json(Self.keyword),
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
    XCTAssertEqual(requests[1].query["workspace_id"], "ws_1")
    XCTAssertEqual(try requests[1].bodyJSON()["status"] as? String, "planned")
    XCTAssertTrue(try requests[1].bodyJSON()["plannedFor"] is NSNull, requests[1].bodyString)
    XCTAssertNil(try requests[1].bodyJSON()["workspaceId"])

    XCTAssertEqual(requests[2].method, "DELETE")
    XCTAssertEqual(requests[2].path, "/v1/blog/keywords/kw_1")
    XCTAssertEqual(requests[2].query["workspace_id"], "ws_1")
  }

  // MARK: - Articles

  func testListArticlesFiltersByStatus() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.article)]}")])
    let client = try makeStubClient()

    let articles = try await client.blog.listArticles(
      workspaceID: "ws_1", status: [.draft, .scheduled], limit: 20)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/articles")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["status"], "draft,scheduled")
    XCTAssertEqual(request.query["limit"], "20")
    XCTAssertEqual(articles[0].featuredImage?.mediaID, "med_1")
    XCTAssertEqual(articles[0].origin, .user)
  }

  func testRequestArticleSendsTheWorkspaceInTheBody() async throws {
    StubURLProtocol.script([.json(Self.article, status: 202)])
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
        {"id":"art_1","title":"Best time to post","slug":"best-time-to-post",
         "tags":[],"word_count":1200,"status":"draft","origin":"plan",
         "created_at":"2026-10-01T09:00:00.000Z","updated_at":"2026-10-02T09:00:00.000Z",
         "instructions":null,"outline":["Why timing matters","What the data says"],
         "brief":{"sources":3},"body_markdown":"# Best time","body_html":"<h1>Best time</h1>",
         "images":[{"media_id":"med_2","url":"https://cdn.yourbrand.com/b.jpg","alt":"Chart","position":1}]}
        """)
    ])
    let client = try makeStubClient()

    let article = try await client.blog.getArticle(workspaceID: "ws_1", "art_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/blog/articles/art_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(article.outline?.count, 2)
    XCTAssertEqual(article.bodyMarkdown, "# Best time")
    XCTAssertEqual(article.images?.first?.position, 1)
    XCTAssertEqual(article.brief, .object(["sources": .int(3)]))
  }

  func testUpdateArticleSplitsClearFromUnset() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"id":"art_1","title":"New title","slug":"new-title","tags":[],"word_count":1200,
         "status":"draft","origin":"plan","created_at":"2026-10-01T09:00:00.000Z",
         "updated_at":"2026-10-02T09:00:00.000Z"}
        """)
    ])
    let client = try makeStubClient()

    _ = try await client.blog.updateArticle(
      workspaceID: "ws_1", "art_1",
      UpdateBlogArticleRequest(title: "New title", excerpt: .some(nil), publishAt: .some(nil)))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/blog/articles/art_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["title"] as? String, "New title")
    XCTAssertTrue(body["excerpt"] is NSNull, request.bodyString)
    XCTAssertTrue(body["publishAt"] is NSNull, request.bodyString)
    XCTAssertNil(body["slug"])
    XCTAssertNil(body["metaTitle"])
  }

  func testLifecycleActionsCarryTheWorkspaceOnTheQuery() async throws {
    StubURLProtocol.script([
      .json(Self.article, status: 202),
      .json(Self.article, status: 202),
      .json(Self.article),
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
      XCTAssertEqual(request.query["workspace_id"], "ws_1", request.path)
    }
  }

  func testSubmitArticlePostsToTheSubmitPathAndReadsInReview() async throws {
    let inReview = Self.article.replacingOccurrences(
      of: #""status":"queued""#, with: #""status":"in_review""#)
    StubURLProtocol.script([.json(inReview)])
    let client = try makeStubClient()

    let article = try await client.blog.submitArticle(workspaceID: "ws_1", "art_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/blog/articles/art_1/submit")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(article.status, .inReview)
  }

  func testSubmitFromAStateThatCannotBeSubmittedIsAConflict() async throws {
    StubURLProtocol.script([
      .json(#"{"error":"invalid_state","message":"Only a draft can be submitted"}"#, status: 409)
    ])
    let client = try makeStubClient()

    do {
      _ = try await client.blog.submitArticle(workspaceID: "ws_1", "art_1")
      XCTFail("expected a 409")
    } catch let error as FoPostError {
      guard case .conflict = error else { return XCTFail("\(error)") }
      XCTAssertEqual(error.code, "invalid_state")
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
