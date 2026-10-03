import Foundation
import XCTest

@testable import FoPost

final class GoogleAdsTests: XCTestCase {
  private let scope = GoogleAdsScope(
    workspaceId: "ws_1", connectionId: "conn_1", customerId: "1234567890")

  func testKeywordsNameTheConnectionAndTheCustomer() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"1234567890~keyword~77~99","adGroupId":"1234567890~adGroup~77",
        "text":"running shoes","matchType":"EXACT","status":"ENABLED","cpcBidMinor":180,
        "negative":false}]}
        """)
    ])
    let client = try makeStubClient()

    let keywords = try await client.googleAds.keywords(
      scope, adGroupID: "1234567890~adGroup~77")

    XCTAssertEqual(keywords.first?.text, "running shoes")
    XCTAssertEqual(keywords.first?.cpcBidMinor, 180)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/google/keywords")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(request.query["customer_id"], "1234567890")
    XCTAssertEqual(request.query["ad_group_id"], "1234567890~adGroup~77")
  }

  func testCreateKeywordSendsTheScopeInTheBody() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"1234567890~keyword~77~99"}}"#, status: 201)])
    let client = try makeStubClient()

    let created = try await client.googleAds.createKeyword(
      CreateGoogleKeywordRequest(
        scope: scope, adGroupId: "1234567890~adGroup~77", text: "running shoes",
        matchType: .exact))

    XCTAssertEqual(created.id, "1234567890~keyword~77~99")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["customerId"] as? String, "1234567890")
    XCTAssertEqual(body["matchType"] as? String, "EXACT")
  }

  func testDeleteCarriesTheScopeInTheBody() async throws {
    StubURLProtocol.script([.json("", status: 204)])
    let client = try makeStubClient()

    try await client.googleAds.deleteAsset("1234567890~asset~4321", scope: scope)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["connectionId"] as? String, "conn_1")
    XCTAssertEqual(body["customerId"] as? String, "1234567890")
  }

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

  func testRecommendationsJoinTheTypesFilter() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":[{"id":"customers/1234567890/recommendations/ABC~1","type":"KEYWORD","campaignId":"1234567890~campaign~55","dismissed":false,"impact":{"baseClicks":10,"potentialClicks":25}}]}"#
      )
    ])
    let client = try makeStubClient()

    let rows = try await client.googleAds.recommendations(
      scope, types: ["KEYWORD", "TARGET_CPA_OPT_IN"])

    XCTAssertEqual(rows.first?.type, "KEYWORD")
    XCTAssertEqual(rows.first?.impact?.potentialClicks, 25)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.query["types"], "KEYWORD,TARGET_CPA_OPT_IN")
  }

  func testRecommendationsOmitTypesWhenNoneGiven() async throws {
    StubURLProtocol.script([.json(#"{"data":[]}"#)])
    let client = try makeStubClient()

    _ = try await client.googleAds.recommendations(scope)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertNil(request.query["types"])
  }

  func testApplyRecommendationsSendsTheIds() async throws {
    StubURLProtocol.script([.json(#"{"data":{"applied":1}}"#)])
    let client = try makeStubClient()

    let result = try await client.googleAds.applyRecommendations(
      GoogleRecommendationsRequest(
        scope: scope, ids: ["customers/1234567890/recommendations/ABC~1"]))

    XCTAssertEqual(result.applied, 1)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/google/recommendations/apply")
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
