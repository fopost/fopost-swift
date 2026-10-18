import Foundation
import XCTest

@testable import FoPost

final class LogsTests: XCTestCase {
  func testListSendsEveryFilterAndReadsMetaAndSummaryBesideData() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":41,"workspace_id":"ws_1","time":"2026-10-01T09:00:00.000Z",
         "auth_method":"api_key","method":"POST","route":"/v1/posts","path":"/v1/posts",
         "status_code":422,"duration_ms":18,"platform":null,"message":"content is required"}],
         "meta":{"next_cursor":"40","has_more":true},
         "summary":{"since":"2026-09-24T09:00:00.000Z","total":120,"errors":3,
         "buckets":[{"at":"2026-10-01T00:00:00.000Z","total":12,"errors":1}]}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.logs.list(
      LogListParams(
        workspaceID: "ws_1", days: 7, status: "failed", method: "POST", statusCode: 422,
        route: "/v1/posts", q: "content", limit: 50, before: "60"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/logs")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["days"], "7")
    XCTAssertEqual(request.query["status"], "failed")
    XCTAssertEqual(request.query["method"], "POST")
    XCTAssertEqual(request.query["status_code"], "422")
    XCTAssertEqual(request.query["route"], "/v1/posts")
    XCTAssertEqual(request.query["q"], "content")
    XCTAssertEqual(request.query["limit"], "50")
    XCTAssertEqual(request.query["before"], "60")
    XCTAssertNil(request.query["platform"])
    XCTAssertEqual(page.data.count, 1)
    XCTAssertEqual(page.data[0].id, 41)
    XCTAssertEqual(page.data[0].statusCode, 422)
    XCTAssertEqual(page.data[0].authMethod, "api_key")
    XCTAssertEqual(page.data[0].message, "content is required")
    XCTAssertEqual(page.meta?.nextCursor, "40")
    XCTAssertEqual(page.meta?.hasMore, true)
    XCTAssertEqual(page.summary?.errors, 3)
    XCTAssertEqual(page.summary?.buckets?.first?.total, 12)
  }
}
