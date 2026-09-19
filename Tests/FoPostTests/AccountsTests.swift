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


  func testCreateTelegramConnectCodeSendsTheWorkspace() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"code\":\"ABC123\",\"command\":\"/connect ABC123\","
          + "\"bot_username\":\"fopost_bot\",\"deep_link\":null,\"group_link\":null,"
          + "\"expires_at\":\"2026-09-19T12:15:00Z\"}}",
        status: 201)
    ])
    let client = try makeStubClient()

    let code = try await client.accounts.createTelegramConnectCode(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/accounts/telegram/connect-code")
    XCTAssertEqual(try request.bodyJSON()["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(code.command, "/connect ABC123")
    XCTAssertEqual(code.botUsername, "fopost_bot")
    XCTAssertNil(code.deepLink)
  }

  func testTelegramConnectStatusDecodesTheFailureReason() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"status\":\"failed\",\"account_id\":null,\"reason\":\"card_required\"}}")
    ])
    let client = try makeStubClient()

    let status = try await client.accounts.telegramConnectStatus(code: "ABC123")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/accounts/telegram/connect-code/status")
    XCTAssertEqual(request.query["code"], "ABC123")
    XCTAssertEqual(status.status, .failed)
    XCTAssertEqual(status.reason, .cardRequired)
  }

  func testTelegramBotCommandsGetSetAndDelete() async throws {
    let menu = "{\"data\":{\"commands\":[{\"command\":\"start\",\"description\":\"Start\"}]}}"
    StubURLProtocol.script([
      .json(menu), .json(menu), .json("{\"data\":{\"commands\":[]}}"),
    ])
    let client = try makeStubClient()

    let listed = try await client.accounts.telegramBotCommands("acc_1")
    XCTAssertEqual(listed.commands.first?.command, "start")

    _ = try await client.accounts.setTelegramBotCommands(
      "acc_1", commands: [TelegramBotCommand(command: "start", description: "Start")])
    let put = StubURLProtocol.requests[1]
    XCTAssertEqual(put.method, "PUT")
    XCTAssertEqual(put.path, "/v1/accounts/acc_1/telegram/commands")
    let sent = try XCTUnwrap(try put.bodyJSON()["commands"] as? [[String: String]])
    XCTAssertEqual(sent, [["command": "start", "description": "Start"]])

    let cleared = try await client.accounts.deleteTelegramBotCommands("acc_1")
    XCTAssertEqual(StubURLProtocol.requests[2].method, "DELETE")
    XCTAssertEqual(cleared.commands, [])
  }
}
