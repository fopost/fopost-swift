import Foundation
import XCTest

@testable import FoPost

final class InboxTests: XCTestCase {
  func testListSendsSnakeCaseFiltersAndDecodesThePage() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"item_1","workspaceId":"ws_1","platform":"instagram","type":"comment",
        "state":"unread","direction":"inbound","authorHandle":"yourbrand","text":"Love this",
        "attachments":[{"kind":"image","url":"https://api.fopost.test/v1/inbox/item_1/attachments/0"}],
        "createdAt":"2026-09-19T10:00:00.000Z","canReply":true,
        "account":{"id":"acc_1","platform":"instagram","username":"yourbrand"}}],
         "meta":{"page":1,"perPage":20,"total":41}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.inbox.list(
      InboxListParams(
        workspaceID: "ws_1", type: .comment, state: .unread, accountID: "acc_1",
        postExternalID: "ext_9", sort: .unanswered, page: 1, perPage: 20))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/inbox")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["type"], "comment")
    XCTAssertEqual(request.query["state"], "unread")
    XCTAssertEqual(request.query["account_id"], "acc_1")
    XCTAssertEqual(request.query["post_external_id"], "ext_9")
    XCTAssertEqual(request.query["sort"], "unanswered")
    XCTAssertEqual(request.query["per_page"], "20")

    XCTAssertEqual(page.data.first?.id, "item_1")
    XCTAssertEqual(page.data.first?.type, .comment)
    XCTAssertEqual(page.data.first?.state, .unread)
    XCTAssertEqual(page.data.first?.attachments?.first?.kind, "image")
    XCTAssertEqual(page.data.first?.account?.username, "yourbrand")
    XCTAssertEqual(page.data.first?.createdAt, Timestamps.parse("2026-09-19T10:00:00.000Z"))
    XCTAssertEqual(page.meta?.total, 41)
    XCTAssertTrue(page.hasMore)
  }

  func testWriteCallsSendTheDocumentedBodies() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([.json(#"{"data":{"updated":3}}"#)])
    let read = try await client.inbox.markThreadRead(
      MarkInboxReadRequest(workspaceID: "ws_1", accountID: "acc_1", postExternalID: "ext_9"))
    XCTAssertEqual(read.updated, 3)
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/inbox/read")
    var body = try request.bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["account_id"] as? String, "acc_1")
    XCTAssertEqual(body["post_external_id"] as? String, "ext_9")
    XCTAssertNil(body["conversation_id"])

    StubURLProtocol.script([
      .json(#"{"data":{"accountsPolled":2,"newItems":5,"rateLimited":0,"dmReconnect":[]}}"#)
    ])
    let refreshed = try await client.inbox.refresh(workspaceID: "ws_1")
    XCTAssertEqual(refreshed.newItems, 5)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/refresh")
    XCTAssertEqual(try request.bodyJSON()["workspace_id"] as? String, "ws_1")

    StubURLProtocol.script([.json(#"{"data":{"id":"item_1","state":"snoozed"}}"#)])
    let snoozeUntil = try XCTUnwrap(Timestamps.parse("2026-09-20T09:00:00Z"))
    let item = try await client.inbox.update(
      "item_1", UpdateInboxItemRequest(state: .snoozed, snoozedUntil: snoozeUntil))
    XCTAssertEqual(item.state, .snoozed)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/inbox/item_1")
    body = try request.bodyJSON()
    XCTAssertEqual(body["state"] as? String, "snoozed")
    XCTAssertEqual(body["snoozedUntil"] as? String, "2026-09-20T09:00:00Z")

    StubURLProtocol.script([
      .json(
        #"{"data":{"item":{"id":"item_1","repliedAt":"2026-09-19T10:05:00Z"},"reply":{"externalId":"r_1","externalUrl":"https://example.invalid/r_1"}}}"#
      )
    ])
    let replied = try await client.inbox.reply("item_1", text: "Thanks!")
    XCTAssertEqual(replied.reply?.externalId, "r_1")
    XCTAssertNotNil(replied.item?.repliedAt)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/item_1/reply")
    XCTAssertEqual(try request.bodyJSON()["text"] as? String, "Thanks!")

    StubURLProtocol.script([.json(#"{"data":{"deleted":true}}"#)])
    let deleted = try await client.inbox.delete("item_1")
    XCTAssertEqual(deleted.deleted, true)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/inbox/item_1")
  }

  func testApprovalsUseIntegerIdsAndOptionalText() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":[{"id":7,"workspaceId":"ws_1","source":"agent","reply":"On it","createdAt":"2026-09-19T10:00:00Z"}]}"#
      )
    ])
    let approvals = try await client.inbox.approvals(workspaceID: "ws_1")
    XCTAssertEqual(approvals.first?.id, 7)
    XCTAssertEqual(approvals.first?.reply, "On it")
    XCTAssertEqual(StubURLProtocol.requests.first?.query["workspace_id"], "ws_1")

    StubURLProtocol.script([.json(#"{"data":{"id":7,"outcome":"sent"}}"#)])
    let approved = try await client.inbox.approveReply(7, text: "On it, thanks")
    XCTAssertEqual(approved.outcome, "sent")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/approvals/7/approve")
    XCTAssertEqual(try request.bodyJSON()["text"] as? String, "On it, thanks")

    StubURLProtocol.script([.json(#"{"data":{"id":7,"outcome":"sent"}}"#)])
    _ = try await client.inbox.approveReply(7)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(try request.bodyJSON().count, 0)

    StubURLProtocol.script([.json(#"{"data":{"id":7,"outcome":"rejected"}}"#)])
    let rejected = try await client.inbox.rejectReply(7)
    XCTAssertEqual(rejected.outcome, "rejected")
    XCTAssertEqual(StubURLProtocol.requests.first?.path, "/v1/inbox/approvals/7/reject")
  }

  func testUnreadCountIsNotEnveloped() async throws {
    StubURLProtocol.script([.json(#"{"count":12}"#)])
    let client = try makeStubClient()

    let unread = try await client.inbox.unreadCount(workspaceID: "ws_1")

    XCTAssertEqual(unread.count, 12)
    XCTAssertEqual(StubURLProtocol.requests.first?.path, "/v1/inbox/unread-count")
  }

  func testThreadsAndConversationsHitTheirPaths() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":[{"accountId":"acc_1","postExternalId":"ext_9","commentCount":4,"unreadCount":1}],"meta":{"page":1,"perPage":20,"total":1}}"#
      )
    ])
    let threads = try await client.inbox.threads(
      InboxThreadListParams(workspaceID: "ws_1", kind: .mentions))
    XCTAssertEqual(threads.data.first?.commentCount, 4)
    XCTAssertFalse(threads.hasMore)
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/posts")
    XCTAssertEqual(request.query["kind"], "mentions")

    StubURLProtocol.script([
      .json(
        #"{"data":[{"accountId":"acc_1","conversationId":"c_1","messageCount":2,"participant":{"name":"Jordan Vale"}}],"meta":{"page":1,"perPage":20,"total":1}}"#
      )
    ])
    let conversations = try await client.inbox.conversations(
      InboxConversationListParams(workspaceID: "ws_1", state: .unread))
    XCTAssertEqual(conversations.data.first?.participant?.name, "Jordan Vale")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/conversations")
    XCTAssertEqual(request.query["state"], "unread")

    StubURLProtocol.script([
      .json(#"{"data":[{"platform":"instagram","comments":"live","dms":"none"}]}"#)
    ])
    let platforms = try await client.inbox.platforms()
    XCTAssertEqual(platforms.first?.comments, .live)
    XCTAssertEqual(platforms.first?.dms, .unavailable)
  }
}
