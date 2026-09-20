import Foundation
import XCTest

@testable import FoPost

final class AdsTikTokTests: XCTestCase {
  func testIdentitiesAndSparkPostsReadTheRightPaths() async throws {
    StubURLProtocol.script([
      .json("""
        {"data":[{"id":"bc1","name":"Brand HQ","role":"ADMIN"}]}
        """),
      .json("""
        {"data":[{"id":"idt_1","type":"CUSTOMIZED_USER","name":"Your Brand"}]}
        """),
      .json("""
        {"data":[{"id":"item_99","identityId":"idt_1","views":48213}]}
        """),
    ])
    let client = try makeStubClient()

    let centers = try await client.ads.tiktokBusinessCenters(
      connectionID: "conn_1", workspaceID: "ws_1")
    XCTAssertEqual(centers.first?.name, "Brand HQ")
    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/ads/tiktok/business-centers")

    let identities = try await client.ads.tiktokIdentities(
      connectionID: "conn_1", adAccountID: "7011", workspaceID: "ws_1")
    XCTAssertEqual(identities.first?.type, "CUSTOMIZED_USER")

    let posts = try await client.ads.sparkPosts(
      SparkPostsParams(
        connectionID: "conn_1", adAccountID: "7011", identityID: "idt_1", workspaceID: "ws_1"))
    XCTAssertEqual(posts.first?.views, 48213)
    let last = try XCTUnwrap(StubURLProtocol.requests.last)
    XCTAssertEqual(last.path, "/v1/ads/spark-posts")
    XCTAssertEqual(last.query["identity_id"], "idt_1")
  }

  func testSparkPostIdAndSmartPlusTravelInTheBody() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"ad_1","workspaceId":"ws_1","kind":"ad","name":"Spark","goal":"traffic",
        "status":"paused","connectionId":"conn_1","adAccountId":"7011",
        "targeting":{"countries":["US"],"ageMin":18,"ageMax":44,"gender":"all"},
        "createdAt":"2026-09-19T10:00:00.000Z"}}
        """, status: 201),
      .json("""
        {"data":{"id":"c1","name":"Smart","status":"PAUSED"}}
        """, status: 201),
    ])
    let client = try makeStubClient()

    _ = try await client.ads.create(
      CreateAdRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "7011", pageId: "idt_1",
        name: "Spark", goal: .traffic, budget: AdBudget(minor: 2000, type: .daily),
        targeting: AdTargeting(countries: ["US"], ageMin: 18, ageMax: 44), text: "",
        sparkPostId: "item_99"))
    XCTAssertEqual(try StubURLProtocol.requests[0].bodyJSON()["sparkPostId"] as? String, "item_99")

    _ = try await client.ads.createCampaign(
      CreateAdCampaignRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "7011", name: "Smart",
        goal: .traffic, smartPlus: true))
    XCTAssertEqual(try StubURLProtocol.requests[1].bodyJSON()["smartPlus"] as? Bool, true)
  }

  func testConversionsReportWhatTheNetworkAccepted() async throws {
    StubURLProtocol.script([.json("""
        {"data":{"accepted":2}}
        """, status: 202)])
    let client = try makeStubClient()

    let result = try await client.ads.uploadConversions(
      UploadConversionsRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "7011", pixelId: "px_1",
        events: [
          ConversionEvent(
            eventName: "CompletePayment", occurredAt: "2026-09-18T10:04:00Z",
            email: "buyer@example.com", valueMinor: 4999, currency: "USD")
        ]))

    XCTAssertEqual(result.accepted, 2)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/conversions")
    XCTAssertEqual(try request.bodyJSON()["pixelId"] as? String, "px_1")
  }

  func testCommentsPageAndTheThreeWrites() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"comments":[{"id":"cm_1","adId":"ad_1","text":"nice","likes":3,"replyCount":0,
        "hidden":true}],"nextCursor":"2"}}
        """),
      .json("""
        {"data":{"replyId":"cm_2"}}
        """, status: 201),
      .json("""
        {"message":"Comment hidden"}
        """),
      .json("""
        {"message":"Comment deleted"}
        """),
    ])
    let client = try makeStubClient()

    let page = try await client.ads.comments(
      AdCommentsParams(connectionID: "conn_1", adID: "ad_1", workspaceID: "ws_1"))
    XCTAssertEqual(page.nextCursor, "2")
    XCTAssertEqual(page.comments.first?.hidden, true)
    XCTAssertEqual(page.comments.first?.likes, 3)

    let scope = AdCommentRequest(workspaceId: "ws_1", connectionId: "conn_1", adId: "ad_1")

    let reply = try await client.ads.replyToComment(
      "cm_1",
      AdCommentRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adId: "ad_1", text: "Friday!"))
    XCTAssertEqual(reply.replyId, "cm_2")
    XCTAssertEqual(StubURLProtocol.requests[1].path, "/v1/ads/comments/cm_1/reply")

    try await client.ads.setCommentHidden(
      "cm_1",
      AdCommentRequest(workspaceId: "ws_1", connectionId: "conn_1", adId: "ad_1", hidden: true))
    XCTAssertEqual(try StubURLProtocol.requests[2].bodyJSON()["hidden"] as? Bool, true)

    try await client.ads.deleteComment("cm_1", scope)
    // The ad travels in the body, because the path already carries the comment.
    let deleted = StubURLProtocol.requests[3]
    XCTAssertEqual(deleted.method, "DELETE")
    XCTAssertEqual(deleted.path, "/v1/ads/comments/cm_1")
    XCTAssertEqual(try deleted.bodyJSON()["adId"] as? String, "ad_1")
  }
}
