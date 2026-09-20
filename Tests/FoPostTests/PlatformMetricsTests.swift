import Foundation
import XCTest

@testable import FoPost

final class PlatformMetricsTests: XCTestCase {
  private let facebookSet = """
    {"data":{"platform":"facebook",
      "account":{"fetched_at":"2026-09-20T02:00:00.000Z","metrics":[
        {"key":"page_daily_video_ad_break_earnings","label":"Ad Break Earnings",
         "kind":"currency_usd","value":42.15},
        {"key":"page_impressions_paid","label":"Paid Impressions","kind":"count","value":1500}]},
      "post":{"external_post_id":"123_456","fetched_at":"2026-09-20T02:00:00.000Z","metrics":[]}}}
    """

  func testPlatformMetricsAsksForRawAndDecodesTheSet() async throws {
    StubURLProtocol.script([.json(facebookSet)])
    let client = try makeStubClient()

    let metrics = try await client.accounts.platformMetrics("acc_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/insights")
    XCTAssertEqual(request.query["raw"], "true")
    XCTAssertEqual(metrics.platform, "facebook")
    XCTAssertEqual(metrics.account.fetchedAt, "2026-09-20T02:00:00.000Z")
    XCTAssertEqual(
      metrics.account.metrics.map(\.key),
      ["page_daily_video_ad_break_earnings", "page_impressions_paid"])
    XCTAssertEqual(metrics.account.metrics.first?.number, 42.15)
    XCTAssertEqual(metrics.post.externalPostID, "123_456")
    XCTAssertTrue(metrics.post.metrics.isEmpty)
  }

  func testASeriesValueStaysJSON() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"platform":"youtube",
          "account":{"fetched_at":null,"metrics":[
            {"key":"daily_views","label":"Views by Day","kind":"series",
             "value":[{"day":"2026-09-19","views":600}]}]},
          "post":{"external_post_id":null,"fetched_at":null,"metrics":[]}}}
        """)
    ])
    let client = try makeStubClient()

    let metrics = try await client.accounts.platformMetrics("acc_1")
    let row = try XCTUnwrap(metrics.account.metrics.first)

    XCTAssertNil(row.number)
    XCTAssertEqual(row.value.arrayValue?.first?.objectValue?["views"]?.intValue, 600)
    XCTAssertNil(metrics.account.fetchedAt)
  }

  func testAPendingMetricGrantSurfacesAsAServerError() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"error":"platform_metrics_unavailable",
         "message":"google-business metrics are not available on this deployment yet."}
        """,
        status: 503)
    ])
    let client = try makeStubClient(maxAttempts: 1)

    do {
      _ = try await client.accounts.platformMetrics("acc_1")
      XCTFail("expected a pending grant to throw")
    } catch let error as FoPostError {
      XCTAssertEqual(error.details?.status, 503)
      XCTAssertEqual(error.details?.code, "platform_metrics_unavailable")
    }
  }
}
