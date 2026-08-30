import Foundation
import XCTest

@testable import FoPost

final class ErrorMappingTests: XCTestCase {
  private func error(status: Int, body: String) -> FoPostError {
    let response = HTTPURLResponse(
      url: URL(string: "https://api.fopost.test/v1/posts")!, statusCode: status,
      httpVersion: "HTTP/1.1", headerFields: [:])!
    return Transport.error(from: response, body: Data(body.utf8))
  }

  func testMapsEveryDocumentedStatus() {
    let body = #"{"error":"nope","message":"Not allowed"}"#
    let cases: [(Int, String)] = [
      (400, "validation"), (422, "validation"), (401, "authentication"),
      (402, "paymentRequired"), (403, "permissionDenied"), (404, "notFound"),
      (409, "conflict"), (429, "rateLimited"), (500, "server"), (503, "server"),
      (418, "api"),
    ]
    for (status, expected) in cases {
      let mapped = error(status: status, body: body)
      XCTAssertEqual(name(of: mapped), expected, "status \(status)")
      XCTAssertEqual(mapped.status, status)
      XCTAssertEqual(mapped.code, "nope")
      XCTAssertEqual(mapped.message, "Not allowed")
    }
  }

  func testPaymentRequiredCarriesTheUpgradeURL() {
    let mapped = error(
      status: 402,
      body:
        #"{"error":"subscription_required","message":"Upgrade to publish","upgrade_url":"https://app.fopost.com/settings/billing"}"#
    )
    XCTAssertEqual(
      mapped.upgradeURL, URL(string: "https://app.fopost.com/settings/billing"))
    XCTAssertEqual(mapped.code, "subscription_required")
  }

  func testUpgradeURLIsOnlyReadFromA402() {
    let mapped = error(
      status: 403, body: #"{"error":"forbidden","upgrade_url":"https://example.test"}"#)
    XCTAssertNil(mapped.upgradeURL)
    XCTAssertEqual(mapped.details?.field("upgrade_url", as: String.self), "https://example.test")
  }

  func testFallsBackToTheStatusWhenTheBodyIsNotJSON() {
    let mapped = error(status: 502, body: "<html>bad gateway</html>")
    XCTAssertNil(mapped.code)
    XCTAssertFalse(mapped.message.isEmpty)
    XCTAssertEqual(mapped.details?.bodyText, "<html>bad gateway</html>")
  }

  func testRawBodyStaysAvailableForExtraFields() {
    let mapped = error(
      status: 400,
      body: #"{"error":"validation_error","message":"Bad","fields":["accounts","content"]}"#)
    XCTAssertEqual(mapped.details?.field("fields", as: [String].self), ["accounts", "content"])
  }

  func testThrottledCollectionReadsRetryAfterFromTheBody() {
    let mapped = error(
      status: 429, body: #"{"error":"throttled","message":"Wait","retryAfter":45}"#)
    XCTAssertEqual(mapped.retryAfter, 45)
  }

  private func name(of error: FoPostError) -> String {
    switch error {
    case .validation: return "validation"
    case .authentication: return "authentication"
    case .paymentRequired: return "paymentRequired"
    case .permissionDenied: return "permissionDenied"
    case .notFound: return "notFound"
    case .conflict: return "conflict"
    case .rateLimited: return "rateLimited"
    case .server: return "server"
    case .api: return "api"
    case .transport: return "transport"
    case .decoding: return "decoding"
    case .encoding: return "encoding"
    case .configuration: return "configuration"
    }
  }
}
