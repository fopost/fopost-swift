import Foundation
import XCTest

@testable import FoPost

final class QueueTests: XCTestCase {
  private static let slot = """
    {"id":"slot_1","workspace_id":"ws_1","account_id":null,"weekday":1,"time":"09:00",
     "timezone":"Europe/Zagreb","created_at":"2026-10-01T09:00:00.000Z"}
    """

  func testListSlotsPutsTheWorkspaceOnTheQuery() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.slot)]}")])
    let client = try makeStubClient()

    let slots = try await client.queue.listSlots(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/queue/slots")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(slots.count, 1)
    XCTAssertEqual(slots[0].id, "slot_1")
    XCTAssertEqual(slots[0].weekday, 1)
    XCTAssertEqual(slots[0].time, "09:00")
    XCTAssertNil(slots[0].accountID)
  }

  func testCreateSlotSendsSnakeCaseKeys() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.slot)}", status: 201)])
    let client = try makeStubClient()

    let slot = try await client.queue.createSlot(
      CreateQueueSlotRequest(
        workspaceID: "ws_1", weekday: 1, time: "09:00", timezone: "Europe/Zagreb",
        accountID: "acc_1"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/queue/slots")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["account_id"] as? String, "acc_1")
    XCTAssertEqual(body["weekday"] as? Int, 1)
    XCTAssertEqual(body["time"] as? String, "09:00")
    XCTAssertEqual(body["timezone"] as? String, "Europe/Zagreb")
    XCTAssertEqual(slot.timezone, "Europe/Zagreb")
  }

  func testUpdateAndDeleteSlotReportTheMovedPosts() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"slot_1","workspace_id":"ws_1","account_id":null,"weekday":2,"time":"10:30",
         "timezone":"Europe/Zagreb","moved":[{"id":"post_1","from":"2026-10-05T07:00:00.000Z",
         "to":"2026-10-06T08:30:00.000Z"}]}}
        """),
      .json("{\"data\":{\"deleted\":true,\"moved\":[]}}"),
    ])
    let client = try makeStubClient()

    let updated = try await client.queue.updateSlot(
      "slot_1", UpdateQueueSlotRequest(weekday: 2, time: "10:30"))
    let deleted = try await client.queue.deleteSlot("slot_1")

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.count, 2)
    XCTAssertEqual(requests[0].method, "PUT")
    XCTAssertEqual(requests[0].path, "/v1/queue/slots/slot_1")
    let body = try requests[0].bodyJSON()
    XCTAssertEqual(body["weekday"] as? Int, 2)
    XCTAssertEqual(body["time"] as? String, "10:30")
    XCTAssertNil(body["timezone"])
    XCTAssertEqual(updated.moved?.first?.id, "post_1")
    XCTAssertEqual(requests[1].method, "DELETE")
    XCTAssertEqual(requests[1].path, "/v1/queue/slots/slot_1")
    XCTAssertEqual(deleted.deleted, true)
    XCTAssertEqual(deleted.moved, [])
  }

  func testNextAndPreviewDecodeTimes() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"next\":\"2026-10-06T08:30:00.000Z\"}}"),
      .json("{\"data\":[\"2026-10-06T08:30:00.000Z\",\"2026-10-07T08:30:00.000Z\"]}"),
    ])
    let client = try makeStubClient()

    let next = try await client.queue.next(workspaceID: "ws_1", accountID: "acc_1")
    let preview = try await client.queue.preview(workspaceID: "ws_1", count: 2)

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests[0].method, "GET")
    XCTAssertEqual(requests[0].path, "/v1/queue/next")
    XCTAssertEqual(requests[0].query["workspace_id"], "ws_1")
    XCTAssertEqual(requests[0].query["account_id"], "acc_1")
    XCTAssertEqual(next, Timestamps.parse("2026-10-06T08:30:00.000Z"))
    XCTAssertEqual(requests[1].path, "/v1/queue/preview")
    XCTAssertEqual(requests[1].query["count"], "2")
    XCTAssertNil(requests[1].query["account_id"])
    XCTAssertEqual(preview.count, 2)
  }

  func testNextIsNilWhenTheQueueIsEmpty() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"next\":null}}")])
    let client = try makeStubClient()

    let next = try await client.queue.next(workspaceID: "ws_1")

    XCTAssertNil(next)
  }

  func testCreatePostSendsScheduleQueue() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"id\":\"post_1\",\"status\":\"scheduled\"}}")])
    let client = try makeStubClient()

    _ = try await client.posts.create(
      CreatePostRequest(
        workspaceID: "ws_1", accounts: ["acc_1"], content: [ContentBlock(text: "Hi")],
        schedule: "queue"))
    _ = try await client.posts.update("post_1", UpdatePostRequest(schedule: "queue"))

    let requests = StubURLProtocol.requests
    XCTAssertEqual(try requests[0].bodyJSON()["schedule"] as? String, "queue")
    XCTAssertNil(try requests[0].bodyJSON()["schedule_at"])
    XCTAssertEqual(requests[1].method, "PUT")
    XCTAssertEqual(try requests[1].bodyJSON()["schedule"] as? String, "queue")
  }
}
