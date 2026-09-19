import Foundation
import XCTest

@testable import FoPost

final class PostsTests: XCTestCase {
  func testCreateAndPublishSendsTheDocumentedShape() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"post_1","workspace_id":"ws_1","status":"draft",
        "content":[{"text":"Hello from Swift","media":[]}],
        "accounts":[{"id":"acc_1","platform":"bluesky","publish_status":"pending"}],
        "created_at":"2026-08-30T10:00:00.000Z"}}
        """)
    ])
    let client = try makeStubClient()

    let post = try await client.posts.create(
      CreatePostRequest(
        workspaceID: "ws_1",
        accounts: ["acc_1"],
        content: .text("Hello from Swift"),
        status: .draft))

    XCTAssertEqual(post.id, "post_1")
    XCTAssertEqual(post.status, .draft)
    XCTAssertEqual(post.content?.first?.text, "Hello from Swift")
    XCTAssertEqual(post.accounts?.first?.platform, "bluesky")
    XCTAssertEqual(
      post.createdAt, Timestamps.parse("2026-08-30T10:00:00.000Z"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/posts")
    XCTAssertEqual(request.headers["Content-Type"], "application/json")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["accounts"] as? [String], ["acc_1"])
    XCTAssertEqual(body["status"] as? String, "draft")
    let content = try XCTUnwrap(body["content"] as? [[String: Any]])
    XCTAssertEqual(content.first?["text"] as? String, "Hello from Swift")

    StubURLProtocol.script([
      .json(
        """
        {"data":{"post_status":"publishing","dryRun":false,
        "deliveries":[{"id":"del_1","accountId":"acc_1","status":"queued"}]}}
        """)
    ])
    let result = try await client.posts.publish("post_1")
    XCTAssertEqual(result.postStatus, .publishing)
    XCTAssertEqual(result.deliveries?.first?.status, .queued)
    XCTAssertEqual(StubURLProtocol.requests.first?.path, "/v1/posts/post_1/publish")
  }

  func testScheduledPostEncodesAnISO8601Timestamp() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"post_2","status":"scheduled"}}"#)])
    let client = try makeStubClient()
    let at = Date(timeIntervalSince1970: 1_788_000_000)

    _ = try await client.posts.create(
      CreatePostRequest(
        workspaceID: "ws_1", accounts: ["acc_1"], content: .thread("One", "Two"),
        status: .scheduled, scheduleAt: at))

    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyJSON()
    XCTAssertEqual(body["schedule_at"] as? String, Timestamps.format(at))
    XCTAssertEqual((body["content"] as? [[String: Any]])?.count, 2)
  }

  func testPublishSendsADryRunFlagOnlyWhenAsked() async throws {
    StubURLProtocol.script([.json(#"{"data":{"dryRun":true,"accounts":[]}}"#)])
    let client = try makeStubClient()

    _ = try await client.posts.publish("post_1", accountIDs: ["acc_1"], dryRun: true)

    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyJSON()
    XCTAssertEqual(body["accountIds"] as? [String], ["acc_1"])
    XCTAssertEqual((body["options"] as? [String: Any])?["dryRun"] as? Bool, true)
  }

  func testListDecodesPaginationMeta() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"post_1","status":"published"},{"id":"post_2","status":"draft"}],
         "meta":{"current_page":2,"per_page":30,"total":45,"last_page":2,"from":31,"to":45}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.posts.list(
      PostListParams(page: 2, perPage: 30, status: .published, platforms: ["twitter", "bluesky"]))

    XCTAssertEqual(page.data.count, 2)
    XCTAssertEqual(page.meta?.currentPage, 2)
    XCTAssertEqual(page.meta?.perPage, 30)
    XCTAssertEqual(page.meta?.total, 45)
    XCTAssertEqual(page.meta?.lastPage, 2)
    XCTAssertEqual(page.meta?.from, 31)
    XCTAssertEqual(page.meta?.to, 45)
    XCTAssertFalse(page.hasMore)

    let query = try XCTUnwrap(StubURLProtocol.requests.first).query
    XCTAssertEqual(query["page"], "2")
    XCTAssertEqual(query["per_page"], "30")
    XCTAssertEqual(query["status"], "published")
    XCTAssertEqual(query["platform"], "twitter,bluesky")
  }

  func testUnknownStatusesDecodeInsteadOfFailing() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"post_9","status":"quantum_entangled"}}"#)])
    let client = try makeStubClient()

    let post = try await client.posts.get("post_9")

    XCTAssertEqual(post.status?.rawValue, "quantum_entangled")
  }

  func testDeleteSendsNoBodyAndToleratesAnEmptyResponse() async throws {
    StubURLProtocol.script([StubResponse(status: 204, body: Data())])
    let client = try makeStubClient()

    try await client.posts.delete("post_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/posts/post_1")
    XCTAssertNil(request.body)
  }

  func testCreatePostCanTargetAGroupAlone() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"id\":\"post_1\"}}", status: 201)])
    let client = try makeStubClient()

    _ = try await client.posts.create(
      CreatePostRequest(
        workspaceID: "ws_1", accountGroupID: "grp_1", content: [ContentBlock(text: "Hi")]))

    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyJSON()
    XCTAssertEqual(body["account_group_id"] as? String, "grp_1")
  }
}
