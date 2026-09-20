import Foundation
import XCTest

@testable import FoPost

/// The deeper analytics endpoints: decay, cadence, per-post timelines, the
/// changes cursor, the on-demand refresh, and posts made outside FoPost.
final class AnalyticsTests: XCTestCase {
  func testDecayReadsTheBandsAndTheHalfLife() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"days":30,"postsMeasured":2,"halfLifeBucket":"1h_3h","bands":[
        {"bucket":"under_1h","label":"First hour","posts":2,"avgEngagements":25,
         "avgImpressions":300,"shareOfFinal":0.3},
        {"bucket":"6h_12h","label":"6-12 hours","posts":0,"avgEngagements":0,
         "avgImpressions":0,"shareOfFinal":null}]}}
        """)
    ])
    let client = try makeStubClient()

    let decay = try await client.analytics.decay(AnalyticsParams(accountID: "acc_1", days: 30))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/analytics/decay")
    XCTAssertEqual(decay.halfLifeBucket, "1h_3h")
    XCTAssertEqual(decay.postsMeasured, 2)
    XCTAssertEqual(decay.bands?.first?.shareOfFinal, 0.3)
    // A band nothing was measured in reports no share rather than zero
    XCTAssertNil(decay.bands?.last?.shareOfFinal)
  }

  func testFrequencyReadsTheWeeksAndTheBestCadence() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"days":90,
        "weeks":[{"weekStart":"2026-03-02","posts":2,"engagements":240,"avgEngagementsPerPost":120}],
        "bands":[{"band":"under_3","label":"1-2 a week","weeks":1,"posts":2,"avgPostsPerWeek":2,
                  "avgEngagementsPerPost":120,"engagementRate":0.12}],
        "best":{"band":"under_3","label":"1-2 a week","avgEngagementsPerPost":120}}}
        """)
    ])
    let client = try makeStubClient()

    let cadence = try await client.analytics.frequency(AnalyticsParams(days: 90))

    XCTAssertEqual(cadence.weeks?.first?.weekStart, "2026-03-02")
    XCTAssertEqual(cadence.bands?.first?.engagementRate, 0.12)
    XCTAssertEqual(cadence.best?.label, "1-2 a week")
  }

  func testATimelineCanBeAddressedByPermalink() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"postId":null,"deliveries":[{"accountId":"acc_1","platform":"twitter",
        "username":"acme","externalPostId":"1","postedAt":"2026-03-02T00:00:00.000Z",
        "points":[{"at":"2026-03-02T00:30:00.000Z","ageMinutes":30,"engagements":40,
        "impressions":400,"reach":null,"likes":30,"comments":null,"shares":null,
        "videoViews":null,"delta":{"impressions":400,"reach":0,"engagements":40,
        "likes":30,"comments":0,"shares":0}}]}]}}
        """)
    ])
    let client = try makeStubClient()

    let timeline = try await client.analytics.timeline("https://x.com/acme/status/1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(
      request.path,
      "/v1/analytics/posts/https%3A%2F%2Fx.com%2Facme%2Fstatus%2F1/timeline")
    // A post made on the network has no FoPost id
    XCTAssertNil(timeline.postId)
    XCTAssertEqual(timeline.deliveries?.first?.points?.first?.ageMinutes, 30)
    XCTAssertEqual(timeline.deliveries?.first?.points?.first?.delta?.engagements, 40)
  }

  func testChangesCarriesTheCursor() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"since":"2026-03-02T00:00:00.000Z","cursor":"2026-03-02T06:00:00.000Z",
        "hasMore":true,"changes":[{"accountId":"acc_1","platform":"twitter","externalPostId":"1",
        "postId":"post_1","postedAt":"2026-03-02T00:00:00.000Z",
        "fetchedAt":"2026-03-02T06:00:00.000Z","impressions":900,"reach":null,
        "engagements":90,"likes":70,"comments":10,"shares":10}]}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.analytics.changes(
      MetricChangesParams(since: "2026-03-02T00:00:00Z", limit: 100))

    XCTAssertEqual(page.hasMore, true)
    XCTAssertEqual(page.cursor, "2026-03-02T06:00:00.000Z")
    XCTAssertEqual(page.changes?.first?.postId, "post_1")
  }

  func testCollectPostReportsEachDelivery() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"collected":1,"deliveries":[{"accountId":"acc_1","platform":"twitter",
        "externalPostId":"1","collected":true,"fetchedAt":"2026-03-02T00:30:00.000Z",
        "message":null}]}}
        """)
    ])
    let client = try makeStubClient()

    let result = try await client.analytics.collectPost("post_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/posts/post_1/analytics/collect")
    XCTAssertEqual(result.collected, 1)
    XCTAssertEqual(result.deliveries?.first?.collected, true)
  }

  func testNativePostsKeepsTheMetaEnvelope() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"externalPostId":"1","text":"Posted by hand",
        "permalink":"https://x.com/acme/status/1","thumbnailUrl":null,"mediaType":null,
        "postedAt":"2026-03-02T00:00:00.000Z","fetchedAt":"2026-03-02T06:00:00.000Z",
        "metrics":{"impressions":900,"reach":null,"engagements":90,"likes":70,
        "comments":10,"shares":10,"videoViews":null}}],
        "meta":{"page":1,"perPage":20,"total":1}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.analytics.nativePosts(
      accountID: "acc_1", NativePostsParams(page: 1, perPage: 20))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/native-posts")
    XCTAssertEqual(page.data.count, 1)
    XCTAssertEqual(page.data.first?.permalink, "https://x.com/acme/status/1")
    XCTAssertEqual(page.data.first?.metrics?.engagements, 90)
    XCTAssertEqual(page.meta?.total, 1)
  }
}
