import Foundation
import XCTest

@testable import FoPost

final class ActivityTests: XCTestCase {
  func testReadsTheAuditLogAndKeepsTheCursor() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"evt_1","workspace_id":"ws_1","kind":"security",
        "ref_type":"member_removed","ref_id":"usr_2","summary":"Removed sam@example.com",
        "actor":{"type":"user","name":"Ada"},"time":"2026-09-20T10:00:00.000Z"}],
        "meta":{"next_cursor":"42"}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.activity.list(
      ActivityListParams(workspaceID: "ws_1", kind: .security, limit: 1))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/activity")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["kind"], "security")
    XCTAssertEqual(request.query["limit"], "1")

    XCTAssertEqual(page.data.first?.refType, "member_removed")
    XCTAssertEqual(page.data.first?.actor.name, "Ada")
    XCTAssertEqual(page.meta.nextCursor, "42")
  }

  func testTheEndOfTheListIsNoCursor() async throws {
    StubURLProtocol.script([.json(#"{"data":[],"meta":{"next_cursor":null}}"#)])
    let client = try makeStubClient()

    let page = try await client.activity.list()

    XCTAssertTrue(page.data.isEmpty)
    XCTAssertNil(page.meta.nextCursor)
  }
}
