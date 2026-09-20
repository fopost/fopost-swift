import Foundation
import XCTest

@testable import FoPost

final class ContactsTests: XCTestCase {
  private static let contact = """
    {"id":"con_1","display_name":"Ada Okafor",
     "channels":[{"platform":"instagram","handle":"adaokafor","externalId":"178414"},
                 {"platform":"x","handle":"ada_writes","externalId":null}],
     "source":"inbox","note":null,
     "first_seen_at":"2026-04-02T09:14:00.000Z","last_seen_at":"2026-09-18T14:30:00.000Z",
     "fields":{"plan_tier":"Pro"},
     "labels":[{"id":"lbl_1","name":"VIP","color":"#0070f3"}]}
    """

  func testListReadsThePaginationBlockRatherThanMeta() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[\(Self.contact)],"pagination":{"page":2,"per_page":10,"total":11}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.contacts.list(
      workspaceID: "ws_1", search: "ada", page: 2, perPage: 10)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/contacts")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["search"], "ada")
    XCTAssertEqual(request.query["per_page"], "10")

    XCTAssertEqual(page.data.count, 1)
    XCTAssertEqual(page.data[0].displayName, "Ada Okafor")
    XCTAssertEqual(page.data[0].channels[0].externalID, "178414")
    XCTAssertEqual(page.data[0].fields["plan_tier"], "Pro")
    XCTAssertEqual(page.data[0].labels[0].name, "VIP")
    XCTAssertEqual(page.data[0].source, .inbox)
    XCTAssertEqual(page.pagination?.total, 11)
    XCTAssertEqual(page.pagination?.page, 2)
    XCTAssertTrue(page.hasMore)
  }

  func testCreateOmitsAnAbsentPlatformID() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.contact)}")])
    let client = try makeStubClient()

    _ = try await client.contacts.create(
      CreateContactRequest(
        workspaceID: "ws_1",
        channels: [ContactChannel(platform: "x", handle: "ada_writes")],
        displayName: "Ada Okafor",
        fields: ["plan_tier": "Pro"]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/contacts")
    XCTAssertTrue(request.bodyString.contains("\"workspace_id\":\"ws_1\""), request.bodyString)
    XCTAssertTrue(
      request.bodyString.contains("\"display_name\":\"Ada Okafor\""), request.bodyString)
    // An absent id must not travel as null: that would claim we know one.
    XCTAssertFalse(request.bodyString.contains("externalId"), request.bodyString)
  }

  func testUpdateClearsAFieldWithNullAndSendsNothingElse() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.contact)}")])
    let client = try makeStubClient()

    _ = try await client.contacts.update("con_1", UpdateContactRequest(fields: ["region": nil]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/contacts/con_1")
    XCTAssertEqual(request.bodyString, "{\"fields\":{\"region\":null}}")
  }

  func testConversationsReadsTheThreadsAContactAppearsIn() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"key":"t_182736","account_id":"acc_1","account_username":"yourbrand",
                  "platform":"instagram","messages":14,"received":9,"sent":5,
                  "last_message_at":"2026-09-18T14:30:00.000Z","last_item_id":"inb_1"}]}
        """)
    ])
    let client = try makeStubClient()

    let rows = try await client.contacts.conversations("con_1", limit: 10)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/contacts/con_1/conversations")
    XCTAssertEqual(request.query["limit"], "10")
    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows[0].key, "t_182736")
    XCTAssertEqual(rows[0].received, 9)
  }

  func testImportReportsWhatMergedAndWhatWasSkipped() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"created":1,"merged":2,
                 "skipped":[{"row":4,"reason":"platform and handle are both required"}],
                 "unknownColumns":["lifetime_value"]}}
        """)
    ])
    let client = try makeStubClient()

    let result = try await client.contacts.importCSV(
      workspaceID: "ws_1", csv: "platform,handle\nx,ada_writes")

    XCTAssertEqual(result.created, 1)
    XCTAssertEqual(result.merged, 2)
    XCTAssertEqual(result.skipped.first?.row, 4)
    XCTAssertEqual(result.unknownColumns, ["lifetime_value"])
  }

  func testCreateFieldPutsTheWorkspaceOnTheQueryAndNotInTheBody() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"fld_1","key":"plan_tier","name":"Plan Tier",
                 "type":"select","options":["Free","Pro"],"position":0}}
        """)
    ])
    let client = try makeStubClient()

    let field = try await client.contacts.createField(
      CreateContactFieldRequest(
        workspaceID: "ws_1", key: "plan_tier", name: "Plan Tier", type: .select,
        options: ["Free", "Pro"]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/contacts/fields")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertFalse(request.bodyString.contains("workspace_id"), request.bodyString)
    XCTAssertEqual(field.key, "plan_tier")
    XCTAssertEqual(field.type, .select)
    XCTAssertEqual(field.options, ["Free", "Pro"])
  }

  func testConversationAnalyticsReadsTheAnalyticsRoute() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"conversations":[{"key":"t_1","accountId":"acc_1","platform":"instagram",
                  "received":9,"sent":5,"answered":5,"open":1,
                  "medianResponseMinutes":47,"firstMessageAt":null,"lastMessageAt":null}],
                 "total":128,"page":1,"perPage":25}}
        """)
    ])
    let client = try makeStubClient()

    let report = try await client.contacts.conversationAnalytics(days: 30, sort: "slowest")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/analytics/inbox/conversations")
    XCTAssertEqual(request.query["days"], "30")
    XCTAssertEqual(request.query["sort"], "slowest")
    XCTAssertEqual(report.total, 128)
    XCTAssertEqual(report.conversations[0].medianResponseMinutes, 47)
  }
}
