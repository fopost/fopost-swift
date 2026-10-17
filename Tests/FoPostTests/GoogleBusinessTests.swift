import Foundation
import XCTest

@testable import FoPost

/// Business Profile management: one call per route, pinning the method, the
/// path, the query and the body each endpoint actually receives.
final class GoogleBusinessTests: XCTestCase {
  func testEveryMethodMapsOntoItsRoute() async throws {
    let client = try makeStubClient()
    let gbp = client.googleBusiness
    let base = "/v1/accounts/acc_1/gbp"

    try await expect(method: "GET", path: "\(base)/location") {
      _ = try await gbp.location("acc_1")
    }
    try await expect(method: "PATCH", path: "\(base)/location") {
      _ = try await gbp.updateLocation("acc_1", fields: [:])
    }
    try await expect(method: "GET", path: "\(base)/attributes") {
      _ = try await gbp.attributes("acc_1")
    }
    try await expect(method: "PATCH", path: "\(base)/attributes") {
      _ = try await gbp.updateAttributes("acc_1", attributes: [])
    }
    try await expect(method: "GET", path: "\(base)/menus") { _ = try await gbp.menus("acc_1") }
    try await expect(method: "PUT", path: "\(base)/menus") {
      _ = try await gbp.replaceMenus("acc_1", menus: [])
    }
    try await expect(method: "GET", path: "\(base)/services") {
      _ = try await gbp.services("acc_1")
    }
    try await expect(method: "PUT", path: "\(base)/services") {
      _ = try await gbp.replaceServices("acc_1", serviceItems: [])
    }
    try await expect(method: "GET", path: "\(base)/media") { _ = try await gbp.media("acc_1") }
    try await expect(method: "POST", path: "\(base)/media") {
      _ = try await gbp.addMedia("acc_1", mediaID: "m_1")
    }
    try await expect(method: "DELETE", path: "\(base)/media/CAoSL") {
      _ = try await gbp.deleteMedia("acc_1", mediaKey: "CAoSL")
    }
    try await expect(method: "GET", path: "\(base)/place-actions") {
      _ = try await gbp.placeActions("acc_1")
    }
    try await expect(method: "POST", path: "\(base)/place-actions") {
      _ = try await gbp.createPlaceAction(
        "acc_1", uri: "https://example.test/book", placeActionType: "APPOINTMENT")
    }
    try await expect(method: "PATCH", path: "\(base)/place-actions/links-1") {
      _ = try await gbp.updatePlaceAction("acc_1", linkID: "links-1", isPreferred: true)
    }
    try await expect(method: "DELETE", path: "\(base)/place-actions/links-1") {
      _ = try await gbp.deletePlaceAction("acc_1", linkID: "links-1")
    }
    try await expect(method: "GET", path: "\(base)/verification") {
      _ = try await gbp.verificationOptions("acc_1")
    }
    try await expect(method: "POST", path: "\(base)/verification/start") {
      _ = try await gbp.startVerification("acc_1", method: "SMS")
    }
    try await expect(method: "POST", path: "\(base)/verification/complete") {
      _ = try await gbp.completeVerification("acc_1", verificationName: "v1", pin: "123456")
    }
    try await expect(method: "GET", path: "\(base)/performance") {
      _ = try await gbp.performance("acc_1", startDate: "2026-09-01", endDate: "2026-09-07")
    }
    try await expect(
      method: "POST", path: "\(base)/assign",
      body: "{\"data\":{\"id\":\"acc_1\",\"workspace_id\":\"ws_2\"}}"
    ) {
      _ = try await gbp.assign("acc_1", workspaceID: "ws_2")
    }
  }

  func testAPatchCarriesOnlyTheFieldsTheCallerSet() async throws {
    let client = try makeStubClient()
    stub()

    _ = try await client.googleBusiness.updateLocation(
      "acc_1", fields: ["store_code": .string("S-12")])

    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyString
    XCTAssertEqual(body, "{\"store_code\":\"S-12\"}")
  }

  func testAPhotoIsNamedByItsLibraryID() async throws {
    let client = try makeStubClient()
    stub()

    _ = try await client.googleBusiness.addMedia("acc_1", mediaID: "m_1", category: "INTERIOR")

    let json = try XCTUnwrap(StubURLProtocol.requests.first).bodyJSON()
    XCTAssertEqual(json["media_id"] as? String, "m_1")
    XCTAssertEqual(json["category"] as? String, "INTERIOR")
  }

  func testPerformanceRepeatsTheMetricParameter() async throws {
    let client = try makeStubClient()
    stub()

    _ = try await client.googleBusiness.performance(
      "acc_1", startDate: "2026-09-01", endDate: "2026-09-07",
      dailyMetrics: ["CALL_CLICKS", "WEBSITE_CLICKS"])

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    let items = URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let metrics = items.filter { $0.name == "daily_metrics" }.compactMap(\.value)
    XCTAssertEqual(metrics, ["CALL_CLICKS", "WEBSITE_CLICKS"])
    XCTAssertEqual(request.query["start_date"], "2026-09-01")
  }

  func testSearchKeywordsAsksTheSameRouteForTheMonthlyTerms() async throws {
    let client = try makeStubClient()
    stub()

    _ = try await client.googleBusiness.searchKeywords(
      "acc_1", startDate: "2026-08-01", endDate: "2026-09-01")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/gbp/performance")
    XCTAssertEqual(request.query["keywords"], "true")
  }

  func testAPendingAPIGrantSurfacesAsAnError() async throws {
    let client = try makeStubClient()
    stub(
      body: "{\"error\":\"configuration_error\",\"message\":\"Not available yet\"}",
      status: 503)

    do {
      _ = try await client.googleBusiness.location("acc_1")
      XCTFail("expected the call to throw")
    } catch let error as FoPostError {
      XCTAssertEqual(error.status, 503)
      XCTAssertEqual(error.code, "configuration_error")
    }
  }

  // MARK: - Helpers

  private func stub(body: String = "{\"data\":{\"ok\":true}}", status: Int = 200) {
    StubURLProtocol.script([
      StubResponse(
        status: status, headers: ["Content-Type": "application/json"], body: Data(body.utf8))
    ])
  }

  private func expect(
    method: String, path: String, body: String = "{\"data\":{\"ok\":true}}",
    _ call: () async throws -> Void,
    file: StaticString = #filePath, line: UInt = #line
  ) async throws {
    stub(body: body)
    try await call()
    let request = try XCTUnwrap(StubURLProtocol.requests.first, file: file, line: line)
    XCTAssertEqual(request.method, method, file: file, line: line)
    XCTAssertEqual(request.path, path, file: file, line: line)
  }
}
