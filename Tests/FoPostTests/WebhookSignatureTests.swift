import Foundation
import XCTest

@testable import FoPost

final class WebhookSignatureTests: XCTestCase {
  private let secret = "whsec_test_secret"
  private let now = Date(timeIntervalSince1970: 1_760_000_000)

  private let body = Data(
    """
    {"event":"post.published","timestamp":"2026-10-09T08:00:00.000Z",
     "data":{"id":"post_1","status":"published"}}
    """.utf8)

  private struct PublishedPost: Decodable {
    let id: String
    let status: String
  }

  private func timestampedHeaders(at seconds: Int, for body: Data) -> [String: String] {
    [
      "x-fopost-timestamp": "\(seconds)",
      "X-FoPost-Signature-256": FoPostWebhook.sign(body, secret: secret, timestamp: seconds),
      "X-FoPost-Signature": FoPostWebhook.sign(body, secret: secret),
    ]
  }

  func testAValidTimestampedSignaturePassesAndParsesTheBody() throws {
    let seconds = Int(now.timeIntervalSince1970) - 30
    let envelope = try FoPostWebhook.verify(
      rawBody: body, headers: timestampedHeaders(at: seconds, for: body), secret: secret,
      now: now)

    XCTAssertEqual(envelope.event, .postPublished)
    XCTAssertEqual(envelope.timestamp, Timestamps.parse("2026-10-09T08:00:00.000Z"))
    let post: PublishedPost = try envelope.decodeData()
    XCTAssertEqual(post.id, "post_1")
    XCTAssertEqual(post.status, "published")
  }

  func testATamperedBodyFails() {
    let seconds = Int(now.timeIntervalSince1970)
    let headers = timestampedHeaders(at: seconds, for: body)
    var tampered = body
    tampered.append(Data(" ".utf8))

    XCTAssertThrowsError(
      try FoPostWebhook.verify(rawBody: tampered, headers: headers, secret: secret, now: now)
    ) { error in
      XCTAssertEqual(error as? WebhookVerificationError, .invalidSignature)
    }
  }

  func testAStaleTimestampFailsEvenWhenTheSignatureIsRight() {
    let seconds = Int(now.timeIntervalSince1970) - 301
    XCTAssertThrowsError(
      try FoPostWebhook.verify(
        rawBody: body, headers: timestampedHeaders(at: seconds, for: body), secret: secret,
        now: now)
    ) { error in
      XCTAssertEqual(error as? WebhookVerificationError, .staleTimestamp)
    }
  }

  func testTheBodyOnlySignatureIsAcceptedWhenNoTimestampIsSent() throws {
    let headers = ["X-FoPost-Signature": FoPostWebhook.sign(body, secret: secret)]
    let envelope = try FoPostWebhook.verify(
      rawBody: body, headers: headers, secret: secret, now: now)
    XCTAssertEqual(envelope.event, .postPublished)
  }

  func testTheBodyOnlySignatureIsIgnoredOnceATimestampIsPresent() {
    let seconds = Int(now.timeIntervalSince1970)
    let headers = [
      "X-FoPost-Timestamp": "\(seconds)",
      "X-FoPost-Signature": FoPostWebhook.sign(body, secret: secret),
    ]
    XCTAssertThrowsError(
      try FoPostWebhook.verify(rawBody: body, headers: headers, secret: secret, now: now)
    ) { error in
      XCTAssertEqual(error as? WebhookVerificationError, .missingSignature)
    }
  }

  func testTheWrongSecretFails() {
    let seconds = Int(now.timeIntervalSince1970)
    XCTAssertThrowsError(
      try FoPostWebhook.verify(
        rawBody: body, headers: timestampedHeaders(at: seconds, for: body), secret: "other",
        now: now)
    ) { error in
      XCTAssertEqual(error as? WebhookVerificationError, .invalidSignature)
    }
  }
}
