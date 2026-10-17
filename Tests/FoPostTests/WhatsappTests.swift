import Foundation
import XCTest

@testable import FoPost

final class WhatsappTests: XCTestCase {
  func testWhatsappIsOnThePlatformList() {
    XCTAssertEqual(Platform.whatsapp.rawValue, "whatsapp")
    XCTAssertTrue(Platform.all.contains(.whatsapp))
  }

  func testCreateTemplateReturnsTheReviewStatusThePlatformGaveIt() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"tpl-1","name":"order_shipped","language":"en_US","category":"UTILITY",
        "status":"PENDING","rejectedReason":null,"components":[],"qualityScore":null}}
        """)
    ])
    let client = try makeStubClient()

    let template = try await client.whatsapp.createTemplate(
      "a1",
      CreateWhatsappTemplateRequest(
        name: "order_shipped",
        language: "en_US",
        category: "UTILITY",
        components: [.object(["type": .string("BODY"), "text": .string("On its way.")])]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/accounts/a1/whatsapp/templates")
    // Nothing marks a template approved but the platform.
    XCTAssertEqual(template.status, "PENDING")
    XCTAssertEqual(template.name, "order_shipped")
  }

  func testDeleteTemplateNamesItInTheQuery() async throws {
    StubURLProtocol.script([.json(#"{"data":{"deleted":true}}"#)])
    let client = try makeStubClient()

    try await client.whatsapp.deleteTemplate("a1", "tpl-1", name: "order_shipped")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/accounts/a1/whatsapp/templates/tpl-1")
    XCTAssertEqual(request.query["name"], "order_shipped")
  }

  func testSandboxSessionCarriesOnlyTheLastFourDigits() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"ses-1","status":"invited","phoneNumberLast4":"4567",
        "invitedAt":"2026-09-20T10:00:00Z","activatedAt":null,"expiresAt":"2026-09-21T10:00:00Z"}}
        """)
    ])
    let client = try makeStubClient()

    let session = try await client.whatsapp.createSandboxSession(
      workspaceID: "ws", phoneNumber: "+15551234567")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/whatsapp/sandbox/sessions")
    XCTAssertEqual(session.phoneNumberLast4, "4567")
    XCTAssertEqual(session.status, "invited")
  }
}
