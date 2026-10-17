import Foundation
import XCTest

@testable import FoPost

final class BroadcastsTests: XCTestCase {
  private static let broadcast = """
    {"id":"bc_1","name":"September check-in","text":"New colours just landed.",
     "account_id":"acc_1","audience":{"platforms":["instagram"]},
     "status":"sent","scheduled_at":null,
     "sent_at":"2026-09-19T10:04:00.000Z","created_at":"2026-09-19T09:58:00.000Z",
     "counts":{"total":3,"sent":2,"skipped":1,"failed":0,"pending":0}}
    """

  func testListReadsThePaginationBlockRatherThanMeta() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[\(Self.broadcast)],"pagination":{"page":2,"per_page":10,"total":11}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.broadcasts.list(
      workspaceID: "ws_1", status: "sent", page: 2, perPage: 10)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/broadcasts")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["status"], "sent")

    XCTAssertEqual(page.data.count, 1)
    XCTAssertEqual(page.data[0].name, "September check-in")
    XCTAssertEqual(page.data[0].status, .sent)
    XCTAssertEqual(page.data[0].counts?.sent, 2)
    XCTAssertEqual(page.data[0].counts?.skipped, 1)
    XCTAssertEqual(page.pagination?.total, 11)
  }

  func testCreateSendsTheSnakeCaseBody() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.broadcast)}")])
    let client = try makeStubClient()

    _ = try await client.broadcasts.create(
      CreateBroadcastRequest(
        workspaceID: "ws_1",
        accountID: "acc_1",
        name: "September check-in",
        text: "New colours just landed.",
        audience: AudienceFilter(platforms: ["instagram"])))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/broadcasts")
    XCTAssertTrue(request.bodyString.contains("\"workspace_id\":\"ws_1\""), request.bodyString)
    XCTAssertTrue(request.bodyString.contains("\"account_id\":\"acc_1\""), request.bodyString)
    XCTAssertTrue(request.bodyString.contains("\"platforms\""), request.bodyString)
    // An unset clause must not travel as null: that would claim we mean it.
    XCTAssertFalse(request.bodyString.contains("label_ids"), request.bodyString)
  }

  /// A closed messaging window has to be readable, or a non-send is a mystery.
  func testASkippedRecipientKeepsItsReason() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"contact_id":"con_1","display_name":"Sam Rivera",
                  "status":"skipped","skip_reason":"window_closed",
                  "sent_at":null,"error":null}],
         "pagination":{"page":1,"per_page":50,"total":1}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.broadcasts.recipients("bc_1", status: "skipped")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/broadcasts/bc_1/recipients")
    XCTAssertEqual(request.query["status"], "skipped")
    XCTAssertEqual(page.data[0].status, .skipped)
    XCTAssertEqual(page.data[0].skipReason, .windowClosed)
  }

  func testSendReportsHowManyMatched() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"id\":\"bc_1\",\"status\":\"sending\",\"recipients\":3}}")
    ])
    let client = try makeStubClient()

    let sent = try await client.broadcasts.send("bc_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/broadcasts/bc_1/send")
    XCTAssertEqual(sent.recipients, 3)
    XCTAssertEqual(sent.status, "sending")
  }

  func testSequenceStepsTravelAsGiven() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"seq_1","name":"Welcome","account_id":"acc_1",
         "steps":[{"delay_hours":0,"text":"Hi"},{"delay_hours":48,"text":"Still here?"}],
         "status":"active","created_at":"2026-09-12T08:00:00.000Z"}}
        """)
    ])
    let client = try makeStubClient()

    let sequence = try await client.sequences.create(
      CreateSequenceRequest(
        workspaceID: "ws_1", accountID: "acc_1", name: "Welcome",
        steps: [SequenceStep(delayHours: 0, text: "Hi")]))

    XCTAssertEqual(sequence.steps[1].delayHours, 48)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertTrue(request.bodyString.contains("\"delay_hours\":0"), request.bodyString)
    XCTAssertTrue(request.bodyString.contains("\"text\":\"Hi\""), request.bodyString)
    XCTAssertFalse(request.bodyString.contains("media_id"), request.bodyString)
  }

  func testEnrollTakesIDsOrAnAudience() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"id\":\"seq_1\",\"enrolled\":2}}"),
      .json("{\"data\":{\"id\":\"seq_1\",\"enrolled\":5}}"),
    ])
    let client = try makeStubClient()

    let byID = try await client.sequences.enroll(
      "seq_1", EnrollRequest(contactIDs: ["con_1", "con_2"]))
    XCTAssertEqual(byID.enrolled, 2)
    XCTAssertTrue(
      StubURLProtocol.requests[0].bodyString.contains("\"contact_ids\":[\"con_1\",\"con_2\"]"),
      StubURLProtocol.requests[0].bodyString)

    _ = try await client.sequences.enroll(
      "seq_1", EnrollRequest(audience: AudienceFilter(platforms: ["telegram"])))
    XCTAssertTrue(
      StubURLProtocol.requests[1].bodyString.contains("telegram"),
      StubURLProtocol.requests[1].bodyString)
  }

  func testUnenrollNamesTheContactsItStops() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"id\":\"seq_1\",\"stopped\":1}}")])
    let client = try makeStubClient()

    let stopped = try await client.sequences.unenroll("seq_1", ["con_1"])

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/sequences/seq_1/unenroll")
    XCTAssertEqual(request.bodyString, "{\"contact_ids\":[\"con_1\"]}")
    XCTAssertEqual(stopped.stopped, 1)
  }
}
