import Foundation
import XCTest

@testable import FoPost

final class MetaMessagingTests: XCTestCase {
  func testIceBreakersRoundTrip() async throws {
    let body = "{\"data\":{\"ice_breakers\":[{\"question\":\"Hours?\",\"payload\":\"HOURS\"}]}}"
    StubURLProtocol.script([
      .json(body), .json(body), .json("{\"data\":{\"ice_breakers\":[]}}"),
    ])
    let client = try makeStubClient()

    let listed = try await client.accounts.iceBreakers("acc_1")
    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/accounts/acc_1/messaging/ice-breakers")
    XCTAssertEqual(listed.iceBreakers.first?.payload, "HOURS")

    _ = try await client.accounts.setIceBreakers(
      "acc_1", [MetaIceBreaker(question: "Hours?", payload: "HOURS")])
    let put = StubURLProtocol.requests[1]
    XCTAssertEqual(put.method, "PUT")
    // Compared field by field, not as a JSON string: the encoder gives no
    // ordering guarantee across a multi-key object, so a string comparison
    // here passes or fails on the run rather than on the body.
    let breakers = try XCTUnwrap(try put.bodyJSON()["ice_breakers"] as? [[String: Any]])
    XCTAssertEqual(breakers.count, 1)
    XCTAssertEqual(breakers.first?["question"] as? String, "Hours?")
    XCTAssertEqual(breakers.first?["payload"] as? String, "HOURS")

    let cleared = try await client.accounts.deleteIceBreakers("acc_1")
    XCTAssertEqual(StubURLProtocol.requests[2].method, "DELETE")
    XCTAssertEqual(cleared.iceBreakers, [])
  }

  func testALinkMenuItemOmitsThePayloadKey() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"persistent_menu\":[{\"locale\":\"default\",\"call_to_actions\":"
          + "[{\"type\":\"web_url\",\"title\":\"Shop\",\"url\":\"https://example.com/shop\"}]}]}}")
    ])
    let client = try makeStubClient()

    let set = try await client.accounts.setPersistentMenu(
      "acc_1",
      [
        MetaPersistentMenuEntry(callToActions: [
          .link(title: "Shop", url: "https://example.com/shop")
        ])
      ])

    let put = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(put.method, "PUT")
    XCTAssertEqual(put.path, "/v1/accounts/acc_1/messaging/persistent-menu")
    let entries = try XCTUnwrap(try put.bodyJSON()["persistent_menu"] as? [[String: Any]])
    let items = try XCTUnwrap(entries.first?["call_to_actions"] as? [[String: Any]])
    XCTAssertNil(items.first?["payload"])
    XCTAssertEqual(items.first?["url"] as? String, "https://example.com/shop")
    XCTAssertEqual(set.persistentMenu.first?.callToActions.first?.url, "https://example.com/shop")
  }

  func testTheGreetingDefaultsItsLocale() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"greeting\":[{\"locale\":\"default\",\"text\":\"Hi!\"}]}}")
    ])
    let client = try makeStubClient()

    let saved = try await client.accounts.setGreeting("acc_1", [MetaGreetingText(text: "Hi!")])

    let put = try XCTUnwrap(StubURLProtocol.requests.first)
    let greeting = try XCTUnwrap(try put.bodyJSON()["greeting"] as? [[String: Any]])
    XCTAssertEqual(greeting.count, 1)
    XCTAssertEqual(greeting.first?["text"] as? String, "Hi!")
    XCTAssertEqual(greeting.first?["locale"] as? String, "default")
    XCTAssertEqual(saved.greeting.first?.locale, "default")
  }

  func testALapsedSubscriptionIsReportedAndResubscribed() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"subscribed\":false,\"fields\":[\"feed\"],\"missing_fields\":[\"messages\"]}}"),
      .json(
        "{\"data\":{\"subscribed\":true,\"fields\":[\"feed\",\"messages\"],\"missing_fields\":[]}}"),
    ])
    let client = try makeStubClient()

    let lapsed = try await client.accounts.webhookSubscription("acc_1")
    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/accounts/acc_1/webhook-subscription")
    XCTAssertFalse(lapsed.subscribed)
    XCTAssertEqual(lapsed.missingFields, ["messages"])

    let fixed = try await client.accounts.resubscribeWebhook("acc_1")
    XCTAssertEqual(StubURLProtocol.requests[1].method, "POST")
    XCTAssertTrue(fixed.subscribed)
  }

  func testHandoverPassesAndTakesControl() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"app_id\":\"263902037430900\",\"control\":\"passed\"}}"),
      .json("{\"data\":{\"app_id\":null,\"control\":\"taken\"}}"),
    ])
    let client = try makeStubClient()

    let passed = try await client.inbox.handover(
      conversationID: "t_1", accountID: "acc_1", appID: "263902037430900")
    let first = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(first.path, "/v1/inbox/conversations/t_1/handover")
    XCTAssertEqual(try first.bodyJSON()["app_id"] as? String, "263902037430900")
    XCTAssertEqual(passed.control, "passed")

    let taken = try await client.inbox.handover(conversationID: "t_1", accountID: "acc_1")
    XCTAssertNil(try StubURLProtocol.requests[1].bodyJSON()["app_id"])
    XCTAssertNil(taken.appID)
    XCTAssertEqual(taken.control, "taken")
  }
}
