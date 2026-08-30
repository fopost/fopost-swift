import Foundation
import XCTest

@testable import FoPost

final class TransportTests: XCTestCase {
  func testSendsAPIKeyAndSDKHeaders() async throws {
    StubURLProtocol.script([.json(#"{"data":[]}"#)])
    let client = try makeStubClient(apiKey: "fp_live_secret")

    _ = try await client.workspaces.list()

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.headers["X-API-Key"], "fp_live_secret")
    XCTAssertEqual(request.headers["Accept"], "application/json")
    XCTAssertEqual(request.headers["User-Agent"], "fopost-swift/\(fopostVersion)")
    XCTAssertEqual(request.url.absoluteString, "https://api.fopost.test/v1/workspaces")
    // The key never travels as a bearer token.
    XCTAssertNil(request.headers["Authorization"])
  }

  func testReadsAPIKeyFromEnvironmentWhenOmitted() throws {
    setenv("FOPOST_API_KEY", "fp_from_env", 1)
    defer { unsetenv("FOPOST_API_KEY") }

    XCTAssertNoThrow(try FoPostClient())
  }

  func testMissingAPIKeyIsAConfigurationError() throws {
    unsetenv("FOPOST_API_KEY")
    XCTAssertThrowsError(try FoPostClient(apiKey: "  ")) { error in
      guard case .configuration = error as? FoPostError else {
        return XCTFail("expected a configuration error, got \(error)")
      }
    }
  }

  func testRetriesOn429AndHonorsRetryAfter() async throws {
    StubURLProtocol.script([
      .json(
        #"{"error":"rate_limited","message":"Slow down"}"#, status: 429,
        headers: ["Retry-After": "2", "X-RateLimit-Limit": "100"]),
      .json(#"{"data":[{"id":"ws_1","name":"Studio"}]}"#),
    ])
    let client = try makeStubClient()

    let workspaces = try await client.workspaces.list()

    XCTAssertEqual(workspaces.count, 1)
    XCTAssertEqual(StubURLProtocol.requests.count, 2)
    // The wait comes from Retry-After, not the exponential schedule.
    XCTAssertEqual(
      Transport.retryDelay(attempt: 1, retryAfter: 2, base: 0.5, cap: 60), 2)
    XCTAssertEqual(
      Transport.retryDelay(attempt: 1, retryAfter: 900, base: 0.5, cap: 60), 60)
  }

  func testRetriesOn500ThenGivesUp() async throws {
    StubURLProtocol.script([.json(#"{"error":"server_error"}"#, status: 500)])
    let client = try makeStubClient()

    do {
      _ = try await client.workspaces.list()
      XCTFail("expected the 500 to surface")
    } catch let error as FoPostError {
      guard case .server(let details) = error else {
        return XCTFail("expected a server error, got \(error)")
      }
      XCTAssertEqual(details.status, 500)
    }
    XCTAssertEqual(StubURLProtocol.requests.count, 3, "3 attempts means 2 retries")
  }

  func testDoesNotRetryOn400() async throws {
    StubURLProtocol.script([
      .json(#"{"error":"validation_error","message":"name is required"}"#, status: 400)
    ])
    let client = try makeStubClient()

    do {
      _ = try await client.workspaces.list()
      XCTFail("expected the 400 to surface")
    } catch let error as FoPostError {
      guard case .validation = error else {
        return XCTFail("expected a validation error, got \(error)")
      }
    }
    XCTAssertEqual(StubURLProtocol.requests.count, 1, "a 400 is never retried")
  }

  func testRetriesNetworkErrors() async throws {
    StubURLProtocol.script([
      .failure(.networkConnectionLost),
      .json(#"{"data":[]}"#),
    ])
    let client = try makeStubClient()

    _ = try await client.workspaces.list()

    XCTAssertEqual(StubURLProtocol.requests.count, 2)
  }

  func testBackoffDoublesAndIsCapped() {
    XCTAssertEqual(Transport.retryDelay(attempt: 1, retryAfter: nil, base: 0.5, cap: 60), 0.5)
    XCTAssertEqual(Transport.retryDelay(attempt: 2, retryAfter: nil, base: 0.5, cap: 60), 1.0)
    XCTAssertEqual(Transport.retryDelay(attempt: 3, retryAfter: nil, base: 0.5, cap: 60), 2.0)
    XCTAssertEqual(Transport.retryDelay(attempt: 20, retryAfter: nil, base: 0.5, cap: 60), 60)
  }

  func testUnwrapsDataEnvelopeAndLeavesBarePayloadsAlone() async throws {
    StubURLProtocol.script([.json(##"{"data":{"id":"lbl_1","name":"Launch","color":"#2563eb"}}"##)])
    let client = try makeStubClient()
    let label = try await client.labels.get("lbl_1")
    XCTAssertEqual(label.name, "Launch")

    StubURLProtocol.script([.json(##"{"id":"lbl_2","name":"Bare","color":"#000000"}"##)])
    let bare = try await client.labels.get("lbl_2")
    XCTAssertEqual(bare.name, "Bare")
  }

  func testEscapeHatchSendsArbitraryRequests() async throws {
    StubURLProtocol.script([.json(#"{"data":{"platforms":["twitter"]}}"#)])
    let client = try makeStubClient()

    let payload = try await client.request(
      method: "GET", path: "/platforms", query: ["scope": "write"], as: JSONValue.self)

    XCTAssertEqual(payload["platforms"]?[0]?.stringValue, "twitter")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/platforms")
    XCTAssertEqual(request.query["scope"], "write")
  }

  func testRateLimitHeadersReachTheError() async throws {
    StubURLProtocol.script([
      .json(
        #"{"error":"rate_limited","message":"Slow down"}"#, status: 429,
        headers: [
          "Retry-After": "1", "X-RateLimit-Limit": "100", "X-RateLimit-Remaining": "0",
        ])
    ])
    let client = try makeStubClient(maxAttempts: 1)

    do {
      _ = try await client.workspaces.list()
      XCTFail("expected a 429")
    } catch let error as FoPostError {
      XCTAssertEqual(error.status, 429)
      XCTAssertEqual(error.retryAfter, 1)
      XCTAssertEqual(error.rateLimit?.limit, 100)
      XCTAssertEqual(error.rateLimit?.remaining, 0)
    }
  }
}
