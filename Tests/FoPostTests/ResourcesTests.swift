import Foundation
import XCTest

@testable import FoPost

/// One request per resource, checking the method, path, and query the SDK
/// builds. The bodies these return are trimmed to what the assertion reads.
final class ResourcesTests: XCTestCase {
  func testEveryResourceHitsItsDocumentedPath() async throws {
    let client = try makeStubClient()

    try await expect(method: "GET", path: "/v1/workspaces/ws_1/analytics", body: "{\"data\":{}}") {
      _ = try await client.workspaces.analytics("ws_1")
    }
    try await expect(method: "GET", path: "/v1/accounts/health", body: "{\"data\":{}}") {
      _ = try await client.accounts.healthSummary(workspaceID: "ws_1")
    }
    try await expect(
      method: "POST", path: "/v1/accounts/acc_1/refresh-token", body: "{\"data\":{}}"
    ) {
      _ = try await client.accounts.refreshToken("acc_1")
    }
    try await expect(
      method: "GET", path: "/v1/accounts/acc_1/communities/search", body: "{\"data\":[]}"
    ) {
      _ = try await client.communities.search(accountID: "acc_1", query: "swift")
    }
    try await expect(
      method: "DELETE", path: "/v1/accounts/acc_1/communities/7", body: "", status: 204
    ) {
      try await client.communities.remove(accountID: "acc_1", id: 7)
    }
    try await expect(method: "POST", path: "/v1/webhooks/wh_1/test", body: "{\"message\":\"sent\"}")
    {
      _ = try await client.webhooks.test("wh_1")
    }
    try await expect(
      method: "GET", path: "/v1/analytics/posting-streak", body: "{\"data\":{\"streak\":[]}}"
    ) {
      _ = try await client.analytics.postingStreak(workspaceID: "ws_1")
    }
    try await expect(method: "POST", path: "/v1/analytics/collect", body: "{\"data\":{}}") {
      _ = try await client.analytics.collect(accountID: "acc_1")
    }
    try await expect(method: "GET", path: "/v1/automations/stats", body: "{\"data\":{}}") {
      _ = try await client.automations.stats()
    }
    try await expect(
      method: "POST", path: "/v1/automations/auto_1/toggle",
      body: "{\"data\":{\"id\":\"auto_1\",\"active\":false}}"
    ) {
      _ = try await client.automations.toggle("auto_1")
    }
    try await expect(
      method: "GET", path: "/v1/automations/auto_1/runs/3", body: "{\"data\":{\"id\":3}}"
    ) {
      _ = try await client.automations.run("auto_1", runID: 3)
    }
    try await expect(method: "GET", path: "/v1/media", body: "{\"data\":[]}") {
      _ = try await client.media.list(workspaceID: "ws_1")
    }
  }

  func testAnalyticsParamsBecomeQueryParameters() async throws {
    StubURLProtocol.script([.json("{\"data\":{}}")])
    let client = try makeStubClient()

    _ = try await client.analytics.overview(
      AnalyticsParams(accountID: "acc_1", workspaceID: "ws_1", days: 30, limit: 10))

    let query = try XCTUnwrap(StubURLProtocol.requests.first).query
    XCTAssertEqual(query["accountId"], "acc_1")
    XCTAssertEqual(query["workspace_id"], "ws_1")
    XCTAssertEqual(query["days"], "30")
    XCTAssertEqual(query["limit"], "10")
  }

  func testAutomationRunsDecodeTheirPageMeta() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":1,"status":"completed","automationId":"auto_1"}],
         "meta":{"current_page":1,"per_page":20,"total":1,"last_page":1,"from":1,"to":1}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.automations.runs("auto_1", page: 1, perPage: 20)

    XCTAssertEqual(page.data.first?.id, 1)
    XCTAssertEqual(page.meta?.perPage, 20)
    XCTAssertFalse(page.hasMore)
  }

  func testPathIdsArePercentEncoded() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"a b","name":"Odd"}}"#)])
    let client = try makeStubClient()

    _ = try await client.labels.get("a b/c")

    XCTAssertEqual(
      StubURLProtocol.requests.first?.url.absoluteString,
      "https://api.fopost.test/v1/labels/a%20b%2Fc")
  }

  private func expect(
    method: String, path: String, body: String, status: Int = 200,
    _ call: () async throws -> Void,
    file: StaticString = #filePath, line: UInt = #line
  ) async throws {
    StubURLProtocol.script([
      StubResponse(
        status: status, headers: ["Content-Type": "application/json"],
        body: Data(body.utf8))
    ])
    try await call()
    let request = try XCTUnwrap(StubURLProtocol.requests.first, file: file, line: line)
    XCTAssertEqual(request.method, method, file: file, line: line)
    XCTAssertEqual(request.path, path, file: file, line: line)
  }
}
