import Foundation
import XCTest

@testable import FoPost

/// The knowledge base: the path, the query casing, the snake_case request body,
/// and that a camelCase response decodes into the model.
final class KnowledgeTests: XCTestCase {
  private static let source = """
    {"id":"know_1","kind":"url","title":"Refund policy","status":"ready","statusMessage":null,
     "url":"https://yourbrand.com/help/refunds","mediaId":null,"brandVoiceId":null,
     "chunkCount":3,"content":null,"lastSyncedAt":"2026-09-20T00:00:00.000Z",
     "createdAt":"2026-09-19T00:00:00.000Z","updatedAt":"2026-09-20T00:00:00.000Z"}
    """

  func testListSendsTheWorkspaceFilterAndDecodesCamelCaseFields() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.source)]}")])
    let client = try makeStubClient()

    let sources = try await client.knowledge.list(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/knowledge/sources")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    XCTAssertEqual(sources.count, 1)
    XCTAssertEqual(sources.first?.status, .ready)
    XCTAssertEqual(sources.first?.kind, .url)
    XCTAssertEqual(sources.first?.chunkCount, 3)
    XCTAssertNil(sources.first?.statusMessage)
  }

  func testCreateSendsASnakeCaseBodyAndOmitsWhatTheKindDoesNotUse() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.source)}")])
    let client = try makeStubClient()

    _ = try await client.knowledge.create(
      CreateKnowledgeSourceRequest(
        kind: .file, title: "Price list", mediaID: "media_1", workspaceID: "ws_1"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/knowledge/sources")

    let body = try request.bodyJSON()
    XCTAssertEqual(body["kind"] as? String, "file")
    XCTAssertEqual(body["media_id"] as? String, "media_1")
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    // Nothing the kind does not use reaches the wire.
    XCTAssertNil(body["url"])
    XCTAssertNil(body["content"])
  }

  func testUpdatePatchesOnlyTheFieldsThatWereSet() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.source)}")])
    let client = try makeStubClient()

    _ = try await client.knowledge.update(
      "know_1", UpdateKnowledgeSourceRequest(title: "Refunds"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/knowledge/sources/know_1")
    XCTAssertEqual(request.bodyString, "{\"title\":\"Refunds\"}")
  }

  func testSearchSendsTopKAndDecodesTheMatches() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"sourceId":"know_1","sourceTitle":"Refund policy","sourceKind":"url",
         "sourceUrl":"https://yourbrand.com/help/refunds","text":"We refund within 30 days.",
         "score":0.82}]}
        """)
    ])
    let client = try makeStubClient()

    let matches = try await client.knowledge.search("how long do refunds take?", topK: 3)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/knowledge/search")
    XCTAssertEqual(request.query["q"], "how long do refunds take?")
    XCTAssertEqual(request.query["top_k"], "3")

    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches.first?.sourceTitle, "Refund policy")
    XCTAssertEqual(matches.first?.score ?? 0, 0.82, accuracy: 0.0001)
  }

  func testSyncPostsToTheSourcesSyncPath() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"know_1","status":"pending"}}"#)])
    let client = try makeStubClient()

    let queued = try await client.knowledge.sync("know_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/knowledge/sources/know_1/sync")
    XCTAssertEqual(queued.status, .pending)
  }
}
