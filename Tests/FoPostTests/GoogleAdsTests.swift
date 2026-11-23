import Foundation
import XCTest

@testable import FoPost

final class GoogleAdsTests: XCTestCase {
  private let scope = GoogleAdsScope(
    workspaceId: "ws_1", connectionId: "conn_1", customerId: "1234567890")

  func testAdScheduleIsReplacedWithPut() async throws {
    StubURLProtocol.script([.json(#"{"data":{"slots":2}}"#)])
    let client = try makeStubClient()

    let result = try await client.googleAds.setAdSchedule(
      SetGoogleAdScheduleRequest(
        scope: scope, campaignId: "1234567890~campaign~55",
        slots: [GoogleAdScheduleInput(dayOfWeek: .monday, startHour: 9, endHour: 18)]))

    XCTAssertEqual(result.slots, 2)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PUT")
    XCTAssertEqual(request.path, "/v1/ads/google/ad-schedule")
  }

  func testQueryReturnsRowsAsGoogleSendsThem() async throws {
    StubURLProtocol.script([.json(#"{"data":{"rows":[{"campaign":{"id":"55"}}]}}"#)])
    let client = try makeStubClient()

    let result = try await client.googleAds.query(
      GoogleQueryRequest(scope: scope, query: "SELECT campaign.id FROM campaign"))

    XCTAssertEqual(result.rows?.count, 1)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/insights/query")
  }

  func testAuthorizeGoogleHasItsOwnRoute() async throws {
    StubURLProtocol.script([.json(#"{"data":{"url":"https://accounts.google.com/o/x"}}"#)])
    let client = try makeStubClient()

    let authorization = try await client.ads.authorizeGoogle(
      ConnectGoogleAdsRequest(workspaceId: "ws_1"))

    XCTAssertEqual(authorization.url, "https://accounts.google.com/o/x")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/connections/google/authorize")
  }
}
