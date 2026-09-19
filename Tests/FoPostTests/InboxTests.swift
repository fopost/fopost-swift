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
  func testItemAndAccountDecodeTheActionFlags() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":{"id":"item_2","type":"dm","liked":true,"pinned":false,"reaction":"❤️","editedAt":"2026-09-19T11:00:00Z","canLike":true,"canPin":false,"canEdit":true,"canReact":true,"canSendMedia":true,"canQuickReply":true,"canPrivateReply":false,"canDelete":true}}"#
      )
    ])
    let item = try await client.inbox.like("item_2")
    XCTAssertEqual(item.liked, true)
    XCTAssertEqual(item.pinned, false)
    XCTAssertEqual(item.reaction, "❤️")
    XCTAssertEqual(item.editedAt, Timestamps.parse("2026-09-19T11:00:00Z"))
    XCTAssertEqual(item.canLike, true)
    XCTAssertEqual(item.canPin, false)
    XCTAssertEqual(item.canEdit, true)
    XCTAssertEqual(item.canReact, true)
    XCTAssertEqual(item.canSendMedia, true)
    XCTAssertEqual(item.canQuickReply, true)
    XCTAssertEqual(item.canPrivateReply, false)

    StubURLProtocol.script([
      .json(#"{"data":[{"id":"acc_1","platform":"x","canStartConversation":true}]}"#)
    ])
    let accounts = try await client.inbox.accounts(workspaceID: "ws_1")
    XCTAssertEqual(accounts.first?.canStartConversation, true)
  }

  func testLikePinAndReactPostToTheirActions() async throws {
    let client = try makeStubClient()

    for (action, path) in [
      ("like", "/v1/inbox/item_1/like"), ("unlike", "/v1/inbox/item_1/unlike"),
      ("pin", "/v1/inbox/item_1/pin"), ("unpin", "/v1/inbox/item_1/unpin"),
    ] {
      StubURLProtocol.script([.json(#"{"data":{"id":"item_1"}}"#)])
      let item: InboxItem
      switch action {
      case "like": item = try await client.inbox.like("item_1")
      case "unlike": item = try await client.inbox.unlike("item_1")
      case "pin": item = try await client.inbox.pin("item_1")
      default: item = try await client.inbox.unpin("item_1")
      }
      XCTAssertEqual(item.id, "item_1")
      let request = try XCTUnwrap(StubURLProtocol.requests.first)
      XCTAssertEqual(request.method, "POST")
      XCTAssertEqual(request.path, path)
    }

    StubURLProtocol.script([.json(#"{"data":{"id":"item_1","reaction":"❤️"}}"#)])
    _ = try await client.inbox.react("item_1", reaction: "❤️")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/item_1/react")
    XCTAssertEqual(try request.bodyJSON()["reaction"] as? String, "❤️")

    StubURLProtocol.script([.json(#"{"data":{"id":"item_1","reaction":null}}"#)])
    _ = try await client.inbox.react("item_1", reaction: nil)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    let body = try request.bodyJSON()
    XCTAssertEqual(body.count, 1)
    XCTAssertTrue(body["reaction"] is NSNull)
  }

  func testEditCommentAndMediaReplySendTheirBodies() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([.json(#"{"data":{"id":"item_1","text":"Fixed"}}"#)])
    let edited = try await client.inbox.editComment("item_1", text: "Fixed")
    XCTAssertEqual(edited.text, "Fixed")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/inbox/item_1")
    XCTAssertEqual(try request.bodyJSON() as NSDictionary, ["text": "Fixed"] as NSDictionary)

    StubURLProtocol.script([
      .json(#"{"data":{"item":{"id":"item_1"},"reply":{"externalId":"r_2"}}}"#)
    ])
    let replied = try await client.inbox.reply(
      "item_1", mediaIDs: ["med_1"], quickReplies: ["Yes", "No"])
    XCTAssertEqual(replied.reply?.externalId, "r_2")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/item_1/reply")
    let body = try request.bodyJSON()
    XCTAssertNil(body["text"])
    XCTAssertEqual(body["media_ids"] as? [String], ["med_1"])
    XCTAssertEqual(body["quick_replies"] as? [String], ["Yes", "No"])
  }

  func testStartConversationAndTypingHitTheConversationRoutes() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(#"{"data":{"conversationId":"c_9","item":{"id":"item_9"}}}"#, status: 201)
    ])
    let started = try await client.inbox.startConversation(
      StartInboxConversationRequest(
        accountID: "acc_1", handle: "jordanvale", text: "Hi Jordan", mediaIDs: ["med_1"]))
    XCTAssertEqual(started.conversationId, "c_9")
    XCTAssertEqual(started.item?.id, "item_9")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/inbox/conversations")
    var body = try request.bodyJSON()
    XCTAssertEqual(body["account_id"] as? String, "acc_1")
    XCTAssertEqual(body["handle"] as? String, "jordanvale")
    XCTAssertEqual(body["text"] as? String, "Hi Jordan")
    XCTAssertEqual(body["media_ids"] as? [String], ["med_1"])
    XCTAssertNil(body["comment_id"])

    StubURLProtocol.script([
      .json(#"{"data":{"conversationId":null,"item":null}}"#, status: 201)
    ])
    let privateReply = try await client.inbox.startConversation(
      StartInboxConversationRequest(commentID: "item_1", text: "Sent you the details"))
    XCTAssertNil(privateReply.conversationId)
    XCTAssertNil(privateReply.item)
    body = try XCTUnwrap(StubURLProtocol.requests.first).bodyJSON()
    XCTAssertEqual(body["comment_id"] as? String, "item_1")
    XCTAssertNil(body["account_id"])

    StubURLProtocol.script([.json(#"{"data":{"typing":false}}"#)])
    let typing = try await client.inbox.setTyping(
      conversationID: "c_9", accountID: "acc_1", on: false)
    XCTAssertEqual(typing.typing, false)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/inbox/conversations/c_9/typing")
    body = try request.bodyJSON()
    XCTAssertEqual(body["account_id"] as? String, "acc_1")
    XCTAssertEqual(body["on"] as? Bool, false)
  }
}
