import Foundation
import XCTest

@testable import FoPost

final class WebhookDeliveriesTests: XCTestCase {
  private static let delivery = """
    {"id":"del_1","webhook_id":"wh_1","event":"post.published","delivery_key":"key_1","attempt":2,
     "status":"failed","response_status":500,"response_snippet":"boom","duration_ms":120,
     "payload_hash":"abc","next_retry_at":"2026-10-01T09:05:00.000Z",
     "created_at":"2026-10-01T09:00:00.000Z"}
    """

  func testListFiltersByStatusAndLimit() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.delivery)]}")])
    let client = try makeStubClient()

    let deliveries = try await client.webhooks.deliveries("wh_1", status: .failed, limit: 10)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/webhooks/wh_1/deliveries")
    XCTAssertEqual(request.query["status"], "failed")
    XCTAssertEqual(request.query["limit"], "10")
    XCTAssertEqual(deliveries.count, 1)
    XCTAssertEqual(deliveries[0].event, .postPublished)
    XCTAssertEqual(deliveries[0].status, .failed)
    XCTAssertEqual(deliveries[0].attempt, 2)
    XCTAssertEqual(deliveries[0].responseStatus, 500)
    XCTAssertEqual(deliveries[0].deliveryKey, "key_1")
    XCTAssertNil(deliveries[0].payload)
  }

  func testGetCarriesThePayload() async throws {
    StubURLProtocol.script([
      .json("{\"data\":" + String(Self.delivery.dropLast()) + ",\"payload\":{\"id\":\"post_1\"}}}")
    ])
    let client = try makeStubClient()

    let delivery = try await client.webhooks.delivery("wh_1", deliveryID: "del_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/webhooks/wh_1/deliveries/del_1")
    XCTAssertEqual(delivery.payload?["id"], .string("post_1"))
  }

  func testRedeliverPostsAndAcceptsAnEmptyAnswer() async throws {
    StubURLProtocol.script([StubResponse(status: 204)])
    let client = try makeStubClient()

    try await client.webhooks.redeliver("wh_1", deliveryID: "del_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/webhooks/wh_1/deliveries/del_1/redeliver")
  }
}
