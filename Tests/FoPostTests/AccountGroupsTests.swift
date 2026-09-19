import Foundation
import XCTest

@testable import FoPost

final class AccountGroupsTests: XCTestCase {
  private let group = """
    {"data":{"id":"grp_1","name":"Launch","account_ids":["acc_1","acc_2"],
    "created_at":"2026-09-19T10:00:00Z","updated_at":"2026-09-19T10:00:00Z"}}
    """

  func testCrudHitsTheDocumentedPaths() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[]}"), .json(group, status: 201), .json(group), .json(group),
      .json("{\"message\":\"Account group deleted\"}"),
    ])
    let client = try makeStubClient()

    _ = try await client.accountGroups.list(workspaceID: "ws_1")
    let created = try await client.accountGroups.create(
      CreateAccountGroupRequest(workspaceID: "ws_1", name: "Launch", accountIDs: ["acc_1"]))
    _ = try await client.accountGroups.get("grp_1")
    _ = try await client.accountGroups.update("grp_1", UpdateAccountGroupRequest(name: "Launch"))
    try await client.accountGroups.delete("grp_1")

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.map(\.method), ["GET", "POST", "GET", "PATCH", "DELETE"])
    XCTAssertEqual(
      requests.map(\.path),
      [
        "/v1/account-groups", "/v1/account-groups", "/v1/account-groups/grp_1",
        "/v1/account-groups/grp_1", "/v1/account-groups/grp_1",
      ])
    XCTAssertEqual(requests[0].query["workspace_id"], "ws_1")
    let body = try requests[1].bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["account_ids"] as? [String], ["acc_1"])
    XCTAssertEqual(try requests[3].bodyJSON()["name"] as? String, "Launch")
    XCTAssertEqual(created.accountIDs, ["acc_1", "acc_2"])
    XCTAssertNotNil(created.createdAt)
  }

  func testSetMembersReplacesTheAccountIDs() async throws {
    StubURLProtocol.script([.json(group)])
    let client = try makeStubClient()

    let result = try await client.accountGroups.setMembers("grp_1", accountIDs: ["acc_2"])

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PUT")
    XCTAssertEqual(request.path, "/v1/account-groups/grp_1/members")
    XCTAssertEqual(try request.bodyJSON()["account_ids"] as? [String], ["acc_2"])
    XCTAssertEqual(result.id, "grp_1")
  }
}
