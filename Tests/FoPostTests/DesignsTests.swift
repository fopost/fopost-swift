import Foundation
import XCTest

@testable import FoPost

/// Designs: paths, methods, snake_case bodies, and the document passed through as JSON.
final class DesignsTests: XCTestCase {
  private static let design = """
    {"id":"des_1","name":"Launch","kind":"carousel","width":1080,"height":1350,
     "document":{"pages":[{"id":"p1","layers":[]}]},"thumbnail_media_id":"med_9",
     "thumbnail_url":"https://api.fopost.test/v1/media/med_9/file",
     "created_at":"2026-11-01T00:00:00.000Z","updated_at":"2026-11-02T00:00:00.000Z"}
    """

  private static let version = #"{"id":"ver_1","version":3,"created_at":"2026-11-02T00:00:00Z"}"#

  func testListSendsTheFiltersAndDecodesTheRows() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.design)]}")])
    let client = try makeStubClient()

    let designs = try await client.designs.list(
      DesignListParams(workspaceID: "ws_1", kind: .carousel, limit: 10, offset: 20))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/designs")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["kind"], "carousel")
    XCTAssertEqual(request.query["limit"], "10")
    XCTAssertEqual(request.query["offset"], "20")

    let first = try XCTUnwrap(designs.first)
    XCTAssertEqual(first.kind, .carousel)
    XCTAssertEqual(first.width, 1080)
    XCTAssertEqual(first.thumbnailMediaID, "med_9")
    XCTAssertNotNil(first.updatedAt)
  }

  func testCreateSendsTheDocumentAsJSON() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design)}", status: 201)])
    let client = try makeStubClient()

    let design = try await client.designs.create(
      CreateDesignRequest(
        workspaceID: "ws_1", kind: .story, name: "Launch",
        document: ["pages": [["id": "p1", "layers": []]]], brandVoiceID: "bv_1"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["kind"] as? String, "story")
    XCTAssertEqual(body["brand_voice_id"] as? String, "bv_1")
    let pages = (body["document"] as? [String: Any])?["pages"] as? [[String: Any]]
    XCTAssertEqual(pages?.first?["id"] as? String, "p1")

    XCTAssertEqual(design.id, "des_1")
    XCTAssertEqual(design.document?["pages"]?.arrayValue?.count, 1)
  }

  func testGetReadsOneDesign() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design)}")])
    let client = try makeStubClient()

    let design = try await client.designs.get("des_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/designs/des_1")
    XCTAssertEqual(design.name, "Launch")
  }

  func testUpdateKeepsTheSavedVersionBesideTheDesign() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design),\"version\":\(Self.version)}")])
    let client = try makeStubClient()

    let saved = try await client.designs.update(
      "des_1", UpdateDesignRequest(name: "Renamed", createVersion: true))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/designs/des_1")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["name"] as? String, "Renamed")
    XCTAssertEqual(body["create_version"] as? Bool, true)
    XCTAssertNil(body["document"])

    XCTAssertEqual(saved.design.id, "des_1")
    XCTAssertEqual(saved.version?.version, 3)
  }

  func testUpdateDecodesANullVersion() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design),\"version\":null}")])
    let client = try makeStubClient()

    let saved = try await client.designs.update("des_1", UpdateDesignRequest(name: "Renamed"))

    XCTAssertNil(saved.version)
  }

  func testDeleteDecodesTheAcknowledgement() async throws {
    StubURLProtocol.script([.json(#"{"data":{"id":"des_1","deleted":true}}"#)])
    let client = try makeStubClient()

    let deleted = try await client.designs.delete("des_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/designs/des_1")
    XCTAssertTrue(deleted.deleted)
  }

  func testVersionsAsksForDocumentsOnlyWhenTold() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.version)]}")])
    let client = try makeStubClient()

    let plain = try await client.designs.versions("des_1")
    XCTAssertEqual(StubURLProtocol.requests.first?.path, "/v1/designs/des_1/versions")
    XCTAssertNil(StubURLProtocol.requests.first?.query["include"])
    XCTAssertEqual(plain.first?.id, "ver_1")

    StubURLProtocol.script([.json("{\"data\":[\(Self.version)]}")])
    _ = try await client.designs.versions("des_1", includeDocument: true)
    XCTAssertEqual(StubURLProtocol.requests.first?.query["include"], "document")
  }

  func testRestoreVersionPostsToTheVersionPath() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design),\"version\":\(Self.version)}")])
    let client = try makeStubClient()

    let restored = try await client.designs.restoreVersion("des_1", versionID: "ver_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/des_1/versions/ver_1/restore")
    XCTAssertEqual(restored.design.id, "des_1")
    XCTAssertEqual(restored.version?.id, "ver_1")
  }

  func testDuplicateSendsTheNameOnlyWhenGiven() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design)}", status: 201)])
    let client = try makeStubClient()

    _ = try await client.designs.duplicate("des_1")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/des_1/duplicate")
    XCTAssertEqual(request.bodyString, "{}")

    StubURLProtocol.script([.json("{\"data\":\(Self.design)}", status: 201)])
    _ = try await client.designs.duplicate("des_1", name: "Copy")
    XCTAssertEqual(StubURLProtocol.requests.first?.bodyString, #"{"name":"Copy"}"#)
  }

  func testExportSendsTheFormatAndDecodesTheFiles() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"format":"png","files":[{"media_id":"med_1","page_index":0,
         "mime_type":"image/png","preview_url":"https://api.fopost.test/v1/media/med_1/file"}]}}
        """)
    ])
    let client = try makeStubClient()

    let export = try await client.designs.export(
      "des_1", ExportDesignRequest(format: .png, pageIndexes: [0, 2]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/des_1/export")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["format"] as? String, "png")
    XCTAssertEqual(body["page_indexes"] as? [Int], [0, 2])
    XCTAssertNil(body["duration_sec"])

    XCTAssertEqual(export.format, .png)
    XCTAssertEqual(export.files.first?.mediaID, "med_1")
    XCTAssertEqual(export.files.first?.pageIndex, 0)
    XCTAssertEqual(export.files.first?.mimeType, "image/png")
  }

  func testBulkSendsRowsAndTheNameColumn() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.design),\(Self.design)]}", status: 201)])
    let client = try makeStubClient()

    let created = try await client.designs.bulk(
      "des_1",
      BulkDesignsRequest(
        rows: [["title": "One"], ["title": "Two"]], nameColumn: "title"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/des_1/bulk")
    let body = try request.bodyJSON()
    XCTAssertEqual((body["rows"] as? [[String: String]])?.count, 2)
    XCTAssertEqual(body["name_column"] as? String, "title")
    XCTAssertEqual(created.count, 2)
  }

  func testPostsDecodesTheLinkedPosts() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"post_1","status":"published","title":null,"text":"Hello",
         "schedule_at":null,"published_at":"2026-11-03T10:00:00Z","platforms":["linkedin"],
         "engagement":12,"views":340}]}
        """)
    ])
    let client = try makeStubClient()

    let posts = try await client.designs.posts("des_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/designs/des_1/posts")
    let first = try XCTUnwrap(posts.first)
    XCTAssertEqual(first.status, .published)
    XCTAssertEqual(first.platforms, ["linkedin"])
    XCTAssertEqual(first.views, 340)
    XCTAssertNotNil(first.publishedAt)
    XCTAssertNil(first.scheduleAt)
  }

  func testTextToSlidesSendsSnakeCaseAndDecodesTheOutline() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"cover":{"title":"Five tips","subtitle":"For launch week"},
         "slides":[{"heading":"Plan","body":"Pick a date."}],
         "cta":{"heading":"Follow","body":"For more."},
         "brand":{"colors":["#111111"],"fonts":{"heading":"Geist"},"logo_media_id":null}}}
        """)
    ])
    let client = try makeStubClient()

    let outline = try await client.designs.textToSlides(
      TextToSlidesRequest(workspaceID: "ws_1", postID: "post_1", maxSlides: 6))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/text-to-slides")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    XCTAssertEqual(body["post_id"] as? String, "post_1")
    XCTAssertEqual(body["max_slides"] as? Int, 6)
    XCTAssertNil(body["text"])

    XCTAssertEqual(outline.cover.title, "Five tips")
    XCTAssertEqual(outline.slides.first?.heading, "Plan")
    XCTAssertEqual(outline.cta.body, "For more.")
    XCTAssertEqual(outline.brand?.fonts?.heading, "Geist")
    XCTAssertNil(outline.brand?.logoMediaID)
  }

  func testFromPostSendsTheLayoutOptions() async throws {
    StubURLProtocol.script([.json("{\"data\":\(Self.design)}", status: 201)])
    let client = try makeStubClient()

    let design = try await client.designs.fromPost(
      DesignFromPostRequest(
        workspaceID: "ws_1", text: "Ship it", style: .post, accountID: "acc_1", carousel: false))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/designs/from-post")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["text"] as? String, "Ship it")
    XCTAssertEqual(body["style"] as? String, "post")
    XCTAssertEqual(body["account_id"] as? String, "acc_1")
    XCTAssertEqual(body["carousel"] as? Bool, false)
    XCTAssertEqual(design.id, "des_1")
  }
}
