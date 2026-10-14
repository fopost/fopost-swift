import Foundation
import XCTest

@testable import FoPost

final class WebhookSignatureTests: XCTestCase {
  private let secret = "whsec_test_secret"
  private let now = Date(timeIntervalSince1970: 1_760_000_000)

  private let body = Data(
    """
    {"event":"article.published","timestamp":"2026-10-09T08:00:00.000Z",
     "data":{"id":"art_1","title":"Best time to post","slug":"best-time-to-post",
      "excerpt":null,"metaTitle":null,"metaDescription":null,
      "bodyMarkdown":"# Best time","bodyHtml":"<h1>Best time</h1>",
      "featuredImage":{"mediaId":"med_1","url":"https://cdn.yourbrand.com/a.jpg","alt":"Clock"},
      "images":[],"tags":["scheduling"],"keyword":"best time to post","wordCount":1200,
      "publishedAt":"2026-10-09T08:00:00.000Z","publishedUrl":"https://yourbrand.com/blog/best-time-to-post"}}
    """.utf8)

  private func timestampedHeaders(at seconds: Int, for body: Data) -> [String: String] {
    [
      "x-fopost-timestamp": "\(seconds)",
      "X-FoPost-Signature-256": FoPostWebhook.sign(body, secret: secret, timestamp: seconds),
      "X-FoPost-Signature": FoPostWebhook.sign(body, secret: secret),
    ]
  }

  func testAValidTimestampedSignaturePassesAndParsesTheArticle() throws {
    let seconds = Int(now.timeIntervalSince1970) - 30
    let envelope = try FoPostWebhook.verify(
      rawBody: body, headers: timestampedHeaders(at: seconds, for: body), secret: secret,
      now: now)

    XCTAssertEqual(envelope.event, .articlePublished)
    XCTAssertEqual(envelope.timestamp, Timestamps.parse("2026-10-09T08:00:00.000Z"))
    let article: BlogArticleWebhookPayload = try envelope.decodeData()
    XCTAssertEqual(article.id, "art_1")
    XCTAssertEqual(article.featuredImage?.mediaID, "med_1")
    XCTAssertEqual(article.publishedUrl, "https://yourbrand.com/blog/best-time-to-post")
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
    XCTAssertEqual(envelope.event, .articlePublished)
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
