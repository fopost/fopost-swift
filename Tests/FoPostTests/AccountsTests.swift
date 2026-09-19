import Foundation
import XCTest

@testable import FoPost

final class AccountsTests: XCTestCase {
  func testRenameSendsAnExplicitNullToRestoreThePlatformName() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"id\":\"acc_1\",\"name\":\"Acme\",\"platform_name\":\"Acme\"}}")
    ])
    let client = try makeStubClient()

    let result = try await client.accounts.rename("acc_1", displayName: nil)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1")
    XCTAssertEqual(request.bodyString, "{\"display_name\":null}")
    XCTAssertEqual(result.platformName, "Acme")
  }

  func testMoveSurfacesBlockingTablesOnConflict() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"id\":\"acc_1\",\"workspace_id\":\"ws_2\"}}"),
      .json(
        "{\"error\":\"move_blocked\",\"message\":\"Blocked\",\"blocking_tables\":[\"ads\"]}",
        status: 409),
    ])
    let client = try makeStubClient()

    let moved = try await client.accounts.move("acc_1", workspaceID: "ws_2")
    XCTAssertEqual(moved.workspaceID, "ws_2")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/move")
    XCTAssertEqual(try request.bodyJSON()["workspace_id"] as? String, "ws_2")

    do {
      _ = try await client.accounts.move("acc_1", workspaceID: "ws_2")
      XCTFail("expected a conflict")
    } catch let error as FoPostError {
      guard case .conflict(let details) = error else { return XCTFail("got \(error)") }
      XCTAssertEqual(details.code, "move_blocked")
      XCTAssertEqual(details.field("blocking_tables", as: [String].self), ["ads"])
    }
  }

  func testListFiltersByGroupAndDecodesPlatformName() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[{\"id\":\"acc_1\",\"name\":\"Brand\",\"platformName\":\"Acme\"}]}")
    ])
    let client = try makeStubClient()

    let accounts = try await client.accounts.list(groupID: "grp_1")

    XCTAssertEqual(StubURLProtocol.requests.first?.query["group_id"], "grp_1")
    XCTAssertEqual(accounts.first?.platformName, "Acme")
  }
}
