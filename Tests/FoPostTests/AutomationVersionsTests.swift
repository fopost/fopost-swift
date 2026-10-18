import Foundation
import XCTest

@testable import FoPost

final class AutomationVersionsTests: XCTestCase {
  private static let graph = """
    {"nodes":[{"id":"n1","kind":"trigger","label":"New post","config":{"event":"post.published"},
     "position":0,"layout":{"x":10,"y":20}}],
     "edges":[{"id":"e1","source":"n1","source_handle":null,"target":"n2"}]}
    """

  func testListVersionsPagesAndReadsMetaBesideData() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"version":3,"note":"Added a delay","created_by":{"name":"Ops"},
         "created_at":"2026-10-01T09:00:00.000Z","node_count":4,
         "nodes_added":[{"id":"n4","kind":"delay","label":null}],"nodes_removed":[]}],
         "meta":{"page":1,"per_page":30,"total":3,"total_pages":1}}
        """)
    ])
    let client = try makeStubClient()

    let page = try await client.automations.versions("auto_1", page: 1, perPage: 30)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/automations/auto_1/versions")
    XCTAssertEqual(request.query["page"], "1")
    XCTAssertEqual(request.query["per_page"], "30")
    XCTAssertEqual(page.data.count, 1)
    XCTAssertEqual(page.data[0].version, 3)
    XCTAssertEqual(page.data[0].createdBy?.name, "Ops")
    XCTAssertEqual(page.data[0].nodeCount, 4)
    XCTAssertEqual(page.data[0].nodesAdded?.first?.kind, "delay")
    XCTAssertEqual(page.meta?.totalPages, 1)
  }

  func testGetVersionDecodesTheGraph() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"version\":2,\"note\":null,\"created_by\":null,"
          + "\"created_at\":\"2026-10-01T09:00:00.000Z\",\"graph\":\(Self.graph)}}")
    ])
    let client = try makeStubClient()

    let version = try await client.automations.version("auto_1", 2)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/automations/auto_1/versions/2")
    XCTAssertEqual(version.version, 2)
    XCTAssertNil(version.createdBy)
    XCTAssertEqual(version.graph?.nodes?.first?.config?["event"], .string("post.published"))
    XCTAssertEqual(version.graph?.nodes?.first?.layout?.x, 10)
    XCTAssertEqual(version.graph?.edges?.first?.target, "n2")
  }

  func testRestoreVersionPostsAndReturnsTheNewVersion() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"version\":4,\"graph\":\(Self.graph),\"steps\":[{\"position\":0,"
          + "\"node_id\":\"n2\",\"action_type\":\"delay\",\"action_config\":{\"minutes\":5}}]}}")
    ])
    let client = try makeStubClient()

    let restored = try await client.automations.restoreVersion("auto_1", 2)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/automations/auto_1/versions/2/restore")
    XCTAssertEqual(restored.version, 4)
    XCTAssertEqual(restored.steps?.first?.actionType, "delay")
    XCTAssertEqual(restored.steps?.first?.actionConfig?["minutes"], .int(5))
  }
}
