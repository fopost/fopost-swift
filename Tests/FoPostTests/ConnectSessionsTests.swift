import Foundation
import XCTest

@testable import FoPost

final class ConnectSessionsTests: XCTestCase {
  private static let session = """
    {"id":"cs_1","status":"pending","external_user_id":"user-42","platforms":["linkedin","threads"],
     "redirect_url":"https://yourbrand.com/connected","branding":{"name":"Your Brand",
     "logo_url":"https://yourbrand.com/logo.png"},"account_id":null,
     "url":"https://app.fopost.test/connect/cs_1","expires_at":"2026-10-01T10:00:00.000Z",
     "used_at":null,"created_at":"2026-10-01T09:00:00.000Z"}
    """

  func testCreateSendsCamelCaseKeysAndDecodesTheSession() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.session)}", status: 201)])
    let client = try makeStubClient()

    let session = try await client.connectSessions.create(
      CreateConnectSessionRequest(
        externalUserID: "user-42", platforms: [.linkedin, .threads], workspaceID: "ws_1",
        redirectURL: "https://yourbrand.com/connected",
        branding: CreateConnectSessionBranding(
          name: "Your Brand", logoURL: "https://yourbrand.com/logo.png")))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/connect-sessions")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["externalUserId"] as? String, "user-42")
    XCTAssertEqual(body["platforms"] as? [String], ["linkedin", "threads"])
    XCTAssertEqual(body["redirectUrl"] as? String, "https://yourbrand.com/connected")
    let branding = try XCTUnwrap(body["branding"] as? [String: Any])
    XCTAssertEqual(branding["logoUrl"] as? String, "https://yourbrand.com/logo.png")
    XCTAssertEqual(session.id, "cs_1")
    XCTAssertEqual(session.status, .pending)
    XCTAssertEqual(session.externalUserID, "user-42")
    XCTAssertEqual(session.platforms, [.linkedin, .threads])
    XCTAssertEqual(session.url, "https://app.fopost.test/connect/cs_1")
    XCTAssertEqual(session.branding?.logoURL, "https://yourbrand.com/logo.png")
    XCTAssertNil(session.accountID)
  }

  func testGetReadsOneSession() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":"
          + Self.session.replacingOccurrences(of: "\"status\":\"pending\"", with: "\"status\":\"used\"")
          .replacingOccurrences(of: "\"account_id\":null", with: "\"account_id\":\"acc_1\"") + "}")
    ])
    let client = try makeStubClient()

    let session = try await client.connectSessions.get("cs_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/connect-sessions/cs_1")
    XCTAssertEqual(session.status, .used)
    XCTAssertEqual(session.accountID, "acc_1")
  }
}
