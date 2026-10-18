import Foundation
import XCTest

@testable import FoPost

final class AdsTrackingTests: XCTestCase {
  func testSendPixelConversionsCarriesTheIdempotencyKey() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"batch_1","accepted":1,"eventCount":1,"replayed":false}}
        """, status: 202),
      .json(
        """
        {"data":{"id":"batch_1","accepted":1,"eventCount":1,"replayed":true}}
        """, status: 202, headers: ["Idempotency-Replayed": "true"]),
    ])
    let client = try makeStubClient()
    let body = UploadConversionsRequest(
      workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_1", pixelId: "px_1",
      events: [
        ConversionEvent(
          eventName: "Purchase", occurredAt: "2026-10-18T10:04:00Z", eventId: "evt_1",
          actionSource: .website, email: "buyer@example.com", clickId: "fb.1.abc",
          valueMinor: 4999, currency: "USD", contentIds: ["sku_1"])
      ])

    let first = try await client.ads.sendPixelConversions(body, idempotencyKey: "key_1")
    XCTAssertEqual(first.id, "batch_1")
    XCTAssertEqual(first.replayed, false)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/ads/conversions/events")
    XCTAssertEqual(request.headers["Idempotency-Key"], "key_1")
    let event = try XCTUnwrap((request.bodyJSON()["events"] as? [[String: Any]])?.first)
    XCTAssertEqual(event["actionSource"] as? String, "website")
    XCTAssertEqual(event["clickId"] as? String, "fb.1.abc")

    let replay = try await client.ads.sendPixelConversions(body, idempotencyKey: "key_1")
    XCTAssertEqual(replay.replayed, true)
  }

  func testUploadConversionsSendsTheKeyOnlyWhenGiven() async throws {
    StubURLProtocol.script([
      .json("""
        {"data":{"accepted":2}}
        """, status: 202),
      .json("""
        {"data":{"id":"batch_2","accepted":2,"eventCount":2,"replayed":false}}
        """, status: 202),
    ])
    let client = try makeStubClient()
    let body = UploadConversionsRequest(
      workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_1", pixelId: "px_1",
      events: [ConversionEvent(eventName: "Lead", occurredAt: "2026-10-18T10:04:00Z")])

    let legacy = try await client.ads.uploadConversions(body)
    XCTAssertEqual(legacy.accepted, 2)
    XCTAssertNil(legacy.id)
    XCTAssertNil(StubURLProtocol.requests[0].headers["Idempotency-Key"])

    _ = try await client.ads.uploadConversions(body, idempotencyKey: "key_2")
    XCTAssertEqual(StubURLProtocol.requests[1].headers["Idempotency-Key"], "key_2")
    XCTAssertEqual(StubURLProtocol.requests[1].path, "/v1/ads/conversions")
  }

  func testPixelReadsTheRightPathAndQuery() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"px_1","name":"Site","code":"<script></script>","createdAt":"2026-10-01",
        "lastFiredAt":null,"isUnavailable":false,"dataUseSetting":"analytics_only"}}
        """),
      .json(
        """
        {"data":[{"eventName":"Purchase","score":7.5,
        "matchKeys":[{"identifier":"email","coveragePercent":92.5}]}]}
        """),
    ])
    let client = try makeStubClient()

    let pixel = try await client.ads.pixel(
      "px_1", connectionID: "conn_1", adAccountID: "act_1", workspaceID: "ws_1")
    XCTAssertEqual(pixel.code, "<script></script>")
    XCTAssertEqual(pixel.dataUseSetting, .analyticsOnly)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/pixels/px_1")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(request.query["ad_account_id"], "act_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    let quality = try await client.ads.eventMatchQuality(
      "px_1", connectionID: "conn_1", adAccountID: "act_1")
    XCTAssertEqual(quality.first?.score, 7.5)
    XCTAssertEqual(quality.first?.matchKeys?.first?.coveragePercent, 92.5)
    XCTAssertEqual(StubURLProtocol.requests.last?.path, "/v1/ads/pixels/px_1/match-quality")
  }

  func testCreateCustomConversionPostsTheRuleAndDeleteCarriesABody() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"cc_1","name":"Checkout","pixelId":"px_1","eventType":"PURCHASE",
        "rule":{"eventName":"PageView","urlContains":"/thanks"},"description":null,
        "defaultValueMinor":1000,"isArchived":false,"isUnavailable":false,
        "createdAt":"2026-10-18T10:00:00Z","lastFiredAt":null}}
        """, status: 201),
      .json("", status: 204),
    ])
    let client = try makeStubClient()

    let created = try await client.ads.createCustomConversion(
      CreateCustomConversionRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_1", pixelId: "px_1",
        name: "Checkout", eventType: .purchase,
        rule: CustomConversionRule(urlContains: "/thanks"), defaultValueMinor: 1000))
    XCTAssertEqual(created.eventType, .purchase)
    XCTAssertEqual(created.rule?.urlContains, "/thanks")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/custom-conversions")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["eventType"] as? String, "PURCHASE")
    let rule = try XCTUnwrap(body["rule"] as? [String: Any])
    XCTAssertEqual(rule["urlContains"] as? String, "/thanks")
    XCTAssertFalse(rule.keys.contains("eventName"))

    try await client.ads.deleteCustomConversion(
      "cc_1", workspaceID: "ws_1", connectionID: "conn_1", adAccountID: "act_1")
    let delete = try XCTUnwrap(StubURLProtocol.requests.last)
    XCTAssertEqual(delete.method, "DELETE")
    XCTAssertEqual(delete.path, "/v1/ads/custom-conversions/cc_1")
    XCTAssertEqual(try delete.bodyJSON()["adAccountId"] as? String, "act_1")
  }
}
